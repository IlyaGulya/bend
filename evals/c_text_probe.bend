# C text-pipeline probe: compiles and runs through the ordinary Bend compiler
# (bun bend2/main.ts evals/c_text_probe.bend), so it exercises the renderer's own
# Link helpers rather than a model of them. Checks exact characters, not lengths
# alone: pieces_ok compares text_of_pieces over CRLF, non-ASCII, a quote and a
# comment body against the literal; rewrite_ok compares CID()/FID() substitution
# across that same text (ASCII keys only, the linker's documented key charset);
# missing_ok requires a loud failure for an unknown key; long_ok concatenates a
# 13 000-character piece. Expected stdout:
#   pieces_ok=True
#   rewrite_ok=True
#   missing_ok=True
#   long_ok=True
import Base
import ../bend2/selfhost/c_backend_link.bend as Link

def cid_map() -> Map<&2, String>:
  Map.set(&2, String, Map.set(&2, String, Map.set(&2, String, Map.new(&2, String), "K", "7"), "kc", "9"), "Seg", "4")

def fid_map() -> Map<&2, String>:
  Map.set(&2, String, Map.set(&2, String, Map.new(&2, String), "f", "3"), "kf", "5")

def expect_pieces() -> String:
  "a\r\nλx\"q\"/* c */"

def pieces_ok() -> Bool:
  String.eq(Link.text_of_pieces(["a", "\r\n", "λ", "x", "\"q\"", "/* c */"]), expect_pieces())

def expect_rewrite() -> String:
  "7+3\r\nλ 9 5"

def rewrite_of(result: Link.LinkResult) -> String:
  match result:
    case Link.LinkSuccess{source}: source
    case Link.LinkFailure{message}: String.append("FAIL:", message)

def rewrite_sample() -> String:
  rewrite_of(Link.rewrite("CID(K)+FID(f)\r\nλ CID(kc) FID(kf)", cid_map(), fid_map()))

def rewrite_ok() -> Bool:
  String.eq(rewrite_sample(), expect_rewrite())

def missing_of(result: Link.LinkResult) -> Bool:
  match result:
    case Link.LinkSuccess{source}: False{}
    case Link.LinkFailure{message}: True{}

def missing_ok() -> Bool:
  missing_of(Link.rewrite("CID(nope)", cid_map(), fid_map()))

def long_piece() -> String:
  Link.text_of_pieces(List.replicate(String, 13000n, "X"))

def long_ok() -> Bool:
  Nat.is_eq(String.length(long_piece()), 13000n)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(String.append("pieces_ok=", Bool.show(pieces_ok())))
    Unit <- IO.print(String.append("rewrite_ok=", Bool.show(rewrite_ok())))
    Unit <- IO.print(String.append("missing_ok=", Bool.show(missing_ok())))
    IO.print(String.append("long_ok=", Bool.show(long_ok())))
