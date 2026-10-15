import { expect, test } from "bun:test";
import { readParserGraph } from "./parser_full_graph.ts";
import { instrumentExplicitProgress } from "./parser_full_explicit_progress.ts";
import { buildExplicitProgressCertificate } from "./parser_full_explicit_certificate.ts";
import { renderExplicitControlRuntime } from "./parser_full_control_runtime.ts";

async function balancedFixture(nonproductive?: "direct" | "mixed" | "structural") {
  const runtime = renderExplicitControlRuntime({
    frameVariants: ["  FrameA{}", "  FrameB{}"], requestVariants: ["  Request_x{}"],
    dispatchCases: ["    case Request_x{}: step_x()"],
    resumeCases: ["FrameA", "FrameB"].map(name => `    case ${name}{}:
      match value:
        case Value_0{flag}: feedback_resume_${name}(flag)
        case _: FeedbackControl{FeedbackInvariant{}, Nil{}, NoProgress{}, NoProgress{}}`),
  });
  const source = ["import Base", "type FeedbackValue is Data:\n  Value_0{flag: Bool}", ...runtime.typeDeclarations,
    ...runtime.declarations.values(), `
def feedback_make_x() -> FeedbackControl:
  FeedbackControl{FeedbackCall{Request_x{}}, Nil{}, NoProgress{}, NoProgress{}}
def feedback_pack_0(flag: Bool) -> FeedbackControl:
  FeedbackControl{FeedbackDone{Value_0{flag}}, Nil{}, NoProgress{}, NoProgress{}}
def feedback_make_FrameA() -> FeedbackFrame:
  FrameA{}
def feedback_make_FrameB() -> FeedbackFrame:
  FrameB{}
def step_a() -> FeedbackControl:
  ${nonproductive === "direct" ? "flag = spin(True{})\n  feedback_pack_0(flag)" : "feedback_attach(feedback_make_x(), feedback_make_FrameA())"}
def step_b() -> FeedbackControl:
  feedback_attach(feedback_make_x(), feedback_make_FrameB())
def step_x() -> FeedbackControl:
  feedback_pack_0(True{})
def feedback_resume_FrameA(result: Bool) -> FeedbackControl:
  feedback_pack_0(result)
def feedback_resume_FrameB(result: Bool) -> FeedbackControl:
  step_a()
${nonproductive === "direct" ? "def spin(flag: Bool) -> Bool:\n  spin(flag)" : nonproductive === "mixed" ? `
def identityBool(flag: Bool) -> Bool:
  flag
def spin(+flag: Bool) -> Bool:
  choice = Bool.pick(Bool -> Bool, identityBool(flag), ignored => True{}, ignored => spin(flag))
  choice(flag)
def step_spin(flag: Bool) -> FeedbackControl:
  feedback_pack_0(spin(flag))
` : nonproductive === "structural" ? `
type Cell is Data:
  Cell{}
def walk(cursor: List<&2, Cell>) -> Bool:
  match cursor:
    case head <> tail: walk(tail)
    case Nil{}: True{}
def step_walk(cursor: List<&2, Cell>) -> FeedbackControl:
  packet = walk(cursor)
  feedback_pack_0(packet)
` : ""}`].join("\n\n");
  const graph = await readParserGraph(source);
  const program = instrumentExplicitProgress(graph, {
    definitions: ["step_a", "step_b", "step_x", "feedback_resume_FrameA", "feedback_resume_FrameB", ...(nonproductive === "mixed" ? ["step_spin"] : nonproductive === "structural" ? ["step_walk", "walk"] : [])],
    nameOf: name => name, controlType: "FeedbackControl", emitPrelude: false,
    primitiveOperations: new Map([
      ["feedback_attach", { kind: "suspend", carriesControl: true, frameArgument: 1, captureName: "feedback_attach_with_progress" }],
      ["feedback_make_x", { kind: "request", activeArguments: [] }],
      ["feedback_make_FrameA", { kind: "suspend" }], ["feedback_make_FrameB", { kind: "suspend" }],
      ["feedback_pack_0", { kind: "return", activeArguments: [0], carriesControl: true }],
    ]),
  });
  return buildExplicitProgressCertificate(program, {
    graph, sourceGraph: graph, lifted: new Set(["a", "b", "x"]), selected: new Set(["x"]), classifications: [],
    frames: ["FrameA", "FrameB"].map((name, index) => ({ name, owner: index ? "step_b" : "step_a", pushOffset: 0, inputFamily: 0, fields: [] })),
    steps: new Map(), consumerHelpers: new Map(), runtimeBlocks: runtime.declarations, rawChunks: new Map(),
  });
}

test("a shared neutral child resumes only its own caller frame, not another caller's frame", async () => {
  const certificate = await balancedFixture();
  expect(certificate.certified).toBe(true);
  expect(certificate.smallestRemainingCycle).toBeNull();
  expect(certificate.bound.H).toBe(4);
});

test("nonproductive native evaluation is rejected instead of certifying an empty administrative graph", async () => {
  await expect(balancedFixture("direct")).rejects.toThrow("Reachable native evaluation has no productive summary");
});

test("a productive native return cannot hide a divergent recursive alternative", async () => {
  await expect(balancedFixture("mixed")).rejects.toThrow("Native recursive evaluation lacks a checked structural termination proof");
});

test("native structural helper recursion is accepted through the unchanged Bend checker", async () => {
  const certificate = await balancedFixture("structural");
  expect(certificate.certified).toBe(true);
  expect(certificate.bound.H).toBe(4);
});
