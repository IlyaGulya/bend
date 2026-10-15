import { patt_term, term_show, type LTerm, type Patt, type Quant } from "../bend2/bend.ts";
import { freeBinderIds, termChildren, type LexicalTypes } from "./parser_full_type_env.ts";

export type CaptureField = {
  id: number;
  sourceName: string;
  name: string;
  type: LTerm;
  /** Original source quantity, never promoted merely to store a capture. */
  quantity: Quant;
  resumeQuantity: Quant;
  uses: number;
};
export type CapturePlan = { fields: CaptureField[]; callbacks: LTerm[] };

/** The current flat capture plan has no dependent binder-telescope transport. */
export class CaptureTypeDependencyError extends Error {
  readonly code = "dependent-capture-type";
  readonly evidence: Record<string, unknown>;
  constructor(readonly capturedBinderId: number, readonly dependencyBinderIds: number[], readonly type: LTerm) {
    super("Captured binder type requires a dependent Kont telescope");
    this.evidence = { code: this.code, capturedBinderId, dependencyBinderIds, type,
      reusableRule: "Transport a typed dependent binder telescope before emitting dependent Kont fields." };
  }
}


/** Map syntax children only; source spans and quantity metadata are not terms. */
function mapChildren(term: LTerm, visit: (child: LTerm) => LTerm): LTerm {
  const copy = { ...term } as Record<string, unknown>;
  if (term.$ === "Sub") {
    const pattern = (node: Patt): Patt => {
      if (node.$ === "PCtr") return { ...node, x: node.x.map(pattern) };
      const renamed = visit({ $: "Var", k: node.k, i: node.i, s: node.s });
      if (renamed.$ !== "Var") throw Error("Capture remapping changed a pattern binder into a non-variable");
      return { ...node, k: renamed.k, i: renamed.i, s: renamed.s };
    };
    return { ...term, v: pattern(term.v), f: visit(term.f) };
  }
  for (const [key, value] of Object.entries(term)) {
    if (key === "s" || key === "q" || key === "v" && term.$ === "Var") continue;
    if (Array.isArray(value)) {
      copy[key] = value.map(child => child && typeof child === "object" && "$" in child ? visit(child as LTerm) : child);
    } else if (value && typeof value === "object" && "$" in value) {
      copy[key] = visit(value as LTerm);
    }
  }
  return copy as LTerm;
}

/** One field per free binder ID across all callbacks of a continuation.
 * Generated transfer and dispatch binders consume each field exactly once.
 * Only the resume-local copy receives + when its actual AST uses repeat.
 */
export function planCaptures(callbacks: readonly LTerm[], lexical: Pick<LexicalTypes, "captures">,
  options: { prefix?: string } = {}): CapturePlan {
  const reserved = new Set<string>();
  const uses = new Map<number, number>();
  function inspect(term: LTerm): void {
    if ("k" in term) {
      if (typeof term.k === "string") reserved.add(term.k);
      else term.k.forEach(name => reserved.add(name));
    }
    if (term.$ === "Var") uses.set(term.i, (uses.get(term.i) ?? 0) + 1);
    for (const child of termChildren(term)) inspect(child);
  }
  callbacks.forEach(inspect);
  const fields = new Map<number, CaptureField>();
  for (const callback of callbacks) {
    for (const binding of lexical.captures(callback)) {
      if (fields.has(binding.id)) continue;
      const dependencies = freeBinderIds(binding.type);
      if (dependencies.length) throw new CaptureTypeDependencyError(binding.id, dependencies, binding.type);
      const base = (options.prefix ?? "capture") + "_" + binding.id;
      let name = base, suffix = 1;
      while (reserved.has(name)) name = base + "_" + suffix++;
      reserved.add(name);
      const count = uses.get(binding.id) ?? 0;
      fields.set(binding.id, { id: binding.id, sourceName: binding.name, name,
        type: binding.type, quantity: binding.quantity, uses: count,
        resumeQuantity: binding.quantity.$ === "None" ? binding.quantity : { $: count > 1 ? "Many" : "Lone" } });
    }
  }
  function rename(term: LTerm): LTerm {
    if (term.$ === "Var") {
      const field = fields.get(term.i);
      return field ? { ...term, k: field.name } : term;
    }
    return mapChildren(term, rename);
  }
  return { fields: [...fields.values()], callbacks: callbacks.map(rename) };
}

export function renderCaptureFields(plan: CapturePlan, type: (term: LTerm) => string): string {
  return plan.fields.map(field => field.name + ": " + type(field.type)).join(", ");
}

export function renderCaptureParameters(plan: CapturePlan, phase: "transfer" | "resume",
  type: (term: LTerm) => string): string {
  return plan.fields.map(field => {
    const quantity = phase === "transfer" ? field.quantity.$ === "None" ? "-" : ""
      : { None: "-", Lone: "", Many: "+" }[field.resumeQuantity.$];
    return quantity + field.name + ": " + type(field.type);
  }).join(", ");
}

export function renderCapturePattern(plan: CapturePlan): string {
  return plan.fields.map(field => field.name).join(", ");
}

export function renderCaptureArguments(plan: CapturePlan, scope: "source" | "local"): string {
  return plan.fields.map(field => scope === "source" ? field.sourceName : field.name).join(", ");
}

type PrintBinder = { name: string; index: number };

/** term_show expects lexical positions rather than the authoritative parser IDs.
 * Rebase a private print AST, also freshening shadowed local names, so no textual
 * replacement can accidentally rename a constructor, reference or inner binder.
 */
function printable(term: LTerm, environment: ReadonlyMap<number, PrintBinder>, names: readonly string[]): LTerm {
  function bind(id: number, sourceName: string): [Map<number, PrintBinder>, string[], PrintBinder] {
    let name = sourceName, suffix = 1;
    while (names.includes(name)) name = sourceName + "_" + suffix++;
    const binder = { name, index: names.length };
    return [new Map([...environment, [id, binder]]), [...names, name], binder];
  }
  if (term.$ === "Var") {
    const binder = environment.get(term.i);
    if (!binder) throw Error("Uncaptured callback binder ID " + term.i);
    return { ...term, k: binder.name, i: binder.index };
  }
  if (term.$ === "Lam") {
    const [env, bound, binder] = bind(term.i, term.k);
    return { ...term, k: binder.name, i: binder.index, f: printable(term.f, env, bound) };
  }
  if (term.$ === "All") {
    const [env, bound, binder] = bind(term.i, term.k);
    return { ...term, k: binder.name, i: binder.index, A: printable(term.A, environment, names),
      B: printable(term.B, env, bound) };
  }
  if (term.$ === "Let") {
    let env = new Map(environment), bound = [...names];
    const keys: string[] = [], indices: number[] = [];
    for (let j = 0; j < term.i.length; j++) {
      let name = term.k[j]!, suffix = 1;
      while (bound.includes(name)) name = term.k[j]! + "_" + suffix++;
      const index = bound.length;
      env.set(term.i[j]!, { name, index });
      bound.push(name); keys.push(name); indices.push(index);
    }
    return { ...term, k: keys, i: indices,
      v: term.v.map(value => printable(value, environment, names)), f: printable(term.f, env, bound) };
  }
  if (term.$ === "Sub") {
    const value = patt_term(term.v);
    const substitute = (node: LTerm): LTerm => node.$ === "Var" && node.i === term.i ? value : mapChildren(node, substitute);
    return printable(substitute(term.f), environment, names);
  }
  return mapChildren(term, child => printable(child, environment, names));
}

export function renderCaptureCallbacks(plan: CapturePlan,
  render: (term: LTerm, boundNames: string[]) => string = (term, names) => term_show(term, -1, names)): string[] {
  const names = plan.fields.map(field => field.name);
  const environment = new Map(plan.fields.map((field, index) => [field.id, { name: field.name, index }]));
  return plan.callbacks.map(callback => render(printable(callback, environment, names), [...names]));
}
