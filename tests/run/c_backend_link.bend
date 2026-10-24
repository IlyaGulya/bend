import Base
import ../../bend2/selfhost/c_backend_link.bend as Link

# Consumer regression for the lexical CID/FID linker: whole markers link,
# comments/literals stay verbatim, a backslash-spliced continuation keeps the
# previous identifier token (so CID inside it is not a marker), and a miss is
# the exact-key failure category, not a guessed id. Both LF and CRLF splices.
def pick(value: Bool, yes: String, no: String) -> String:
  match value:
    case True{}: yes
    case False{}: no

def cids() -> Map<&2, String>:
  Map.set(&2, String, Map.new(&2, String), "answer", "CID_ANSWER")

def fids() -> Map<&2, String>:
  Map.set(&2, String, Map.new(&2, String), "Clo~apply", "FID_CLO_APPLY")

def linked_and_comment(result: Link.LinkResult) -> String:
  match result:
    case Link.LinkSuccess{source}:
      +src = source
      pick(Bool.and(String.contains(src, "CID_ANSWER"), String.contains(src, "// CID(nope)")), "linked-comment-kept", "linked-comment-missed")
    case Link.LinkFailure{_}: "linked-comment-failed"

def literal_kept(result: Link.LinkResult, input: String) -> String:
  match result:
    case Link.LinkSuccess{source}:
      pick(String.eq(source, input), "literal-kept", "literal-changed")
    case Link.LinkFailure{_}: "literal-failed"

def fid_linked(result: Link.LinkResult) -> String:
  match result:
    case Link.LinkSuccess{source}:
      pick(String.contains(source, "FID_CLO_APPLY"), "fid-linked", "fid-missed")
    case Link.LinkFailure{_}: "fid-failed"

def splice_kept(result: Link.LinkResult, input: String) -> String:
  match result:
    case Link.LinkSuccess{source}:
      pick(String.eq(source, input), "splice-kept", "splice-changed")
    case Link.LinkFailure{_}: "splice-linked"

def miss(result: Link.LinkResult) -> String:
  match result:
    case Link.LinkFailure{_}: "missing"
    case Link.LinkSuccess{_}: "missing-succeeded"

def main() -> IO(Unit):
  +comment_input: String = "int x = CID(answer); // CID(nope)"
  +literal_input: String = "char *s = \"CID(answer)\";"
  +fid_input: String = "int f = FID(Clo~apply);"
  +lf_input: String = "int a = MY_\\\nCID(any);"
  +crlf_input: String = "int a = MY_\\\r\nCID(any);"
  IO.print(String.join([
    linked_and_comment(Link.rewrite(comment_input, cids(), fids())),
    literal_kept(Link.rewrite(literal_input, cids(), fids()), literal_input),
    fid_linked(Link.rewrite(fid_input, cids(), fids())),
    splice_kept(Link.rewrite(lf_input, cids(), fids()), lf_input),
    splice_kept(Link.rewrite(crlf_input, cids(), fids()), crlf_input),
    miss(Link.rewrite("int a = CID(Ful);", cids(), fids()))
  ], "\n"))

#|linked-comment-kept
#|literal-kept
#|fid-linked
#|splice-kept
#|splice-kept
#|missing
