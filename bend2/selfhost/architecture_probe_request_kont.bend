import Base

type Token is Data:
  TkDo{}
  TkMonad{}
  TkLt{}
  TkArg{}
  TkGt{}
  TkColon{}
  TkReturn{}
  TkWord{key: String}
  TkBind{}
  TkSemi{}
  TkLine{}
  TkOpen{}
  TkClose{}
  TkStop{}

type Step is Data:
  Act{value: String, grouped: Bool}
  Bound{key: String, value: String, grouped: Bool}

type Term is Data:
  Ref{key: String}
  Grouped{inner: Term}
  DoTerm{steps: List<&2, Step>, body: Term}

type Request is Data:
  TermRequest{}
  AtomRequest{}
  DoBodyRequest{steps: List<&2, Step>}

type Kont is Data:
  DoneKont{}
  AfterReturn{steps: List<&2, Step>}
  AfterBind{key: String, steps: List<&2, Step>}
  AfterParenDone{}
  AfterParenReturn{steps: List<&2, Step>}
  AfterParenBind{key: String, steps: List<&2, Step>}
  AfterParenAction{steps: List<&2, Step>}

type Outcome is Data:
  TermSuccess{value: Term, after: List<&2, Token>}
  TermFailure{after: List<&2, Token>}

# Administrative Term -> Atom and continuation resume happen in this invocation.
# Each driver self-call below receives a direct tail of the matched token input.
def drive(+tokens: List<&2, Token>, request: Request, kont: Kont) -> Outcome:
  match tokens request kont:
    case TkWord{key} <> rest TermRequest{} DoneKont{}:
      TermSuccess{Ref{key}, rest}
    case TkWord{key} <> rest TermRequest{} AfterReturn{steps}:
      TermSuccess{DoTerm{List.reverse(&2, Step, steps), Ref{key}}, rest}
    case TkWord{value} <> (TkSemi{} <> +after) TermRequest{} AfterBind{key, steps}:
      drive(after, DoBodyRequest{Bound{key, value, False{}} <> steps}, DoneKont{})
    case TkWord{value} <> (TkLine{} <> +after) TermRequest{} AfterBind{key, steps}:
      drive(after, DoBodyRequest{Bound{key, value, False{}} <> steps}, DoneKont{})
    case TkWord{value} <> rest TermRequest{} AfterBind{key, steps}:
      TermFailure{rest}
    case TkOpen{} <> +rest TermRequest{} DoneKont{}:
      drive(rest, AtomRequest{}, AfterParenDone{})
    case TkOpen{} <> +rest TermRequest{} AfterReturn{steps}:
      drive(rest, AtomRequest{}, AfterParenReturn{steps})
    case TkOpen{} <> +rest TermRequest{} AfterBind{key, steps}:
      drive(rest, AtomRequest{}, AfterParenBind{key, steps})
    case TkWord{key} <> (TkClose{} <> +rest) AtomRequest{} AfterParenDone{}:
      TermSuccess{Grouped{Ref{key}}, rest}
    case TkWord{key} <> (TkClose{} <> +rest) AtomRequest{} AfterParenReturn{steps}:
      TermSuccess{DoTerm{List.reverse(&2, Step, steps), Grouped{Ref{key}}}, rest}
    case TkWord{value} <> (TkClose{} <> (TkSemi{} <> +after)) AtomRequest{} AfterParenBind{key, steps}:
      drive(after, DoBodyRequest{Bound{key, value, True{}} <> steps}, DoneKont{})
    case TkWord{value} <> (TkClose{} <> (TkLine{} <> +after)) AtomRequest{} AfterParenBind{key, steps}:
      drive(after, DoBodyRequest{Bound{key, value, True{}} <> steps}, DoneKont{})
    case TkWord{value} <> (TkClose{} <> (TkSemi{} <> +after)) AtomRequest{} AfterParenAction{steps}:
      drive(after, DoBodyRequest{Act{value, True{}} <> steps}, DoneKont{})
    case TkWord{value} <> (TkClose{} <> (TkLine{} <> +after)) AtomRequest{} AfterParenAction{steps}:
      drive(after, DoBodyRequest{Act{value, True{}} <> steps}, DoneKont{})
    case TkDo{} <> (TkMonad{} <> (TkLt{} <> (TkArg{} <> (TkGt{} <> (TkColon{} <> +body))))) TermRequest{} DoneKont{}:
      drive(body, DoBodyRequest{Nil{}}, DoneKont{})
    case TkLine{} <> +rest DoBodyRequest{steps} DoneKont{}:
      drive(rest, DoBodyRequest{steps}, DoneKont{})
    case TkSemi{} <> +rest DoBodyRequest{steps} DoneKont{}:
      drive(rest, DoBodyRequest{steps}, DoneKont{})
    case TkReturn{} <> +rest DoBodyRequest{steps} DoneKont{}:
      drive(rest, TermRequest{}, AfterReturn{steps})
    case TkWord{key} <> (TkBind{} <> +value) DoBodyRequest{steps} DoneKont{}:
      drive(value, TermRequest{}, AfterBind{key, steps})
    case TkWord{value} <> (TkSemi{} <> +after) DoBodyRequest{steps} DoneKont{}:
      drive(after, DoBodyRequest{Act{value, False{}} <> steps}, DoneKont{})
    case TkWord{value} <> (TkLine{} <> +after) DoBodyRequest{steps} DoneKont{}:
      drive(after, DoBodyRequest{Act{value, False{}} <> steps}, DoneKont{})
    case TkOpen{} <> +rest DoBodyRequest{steps} DoneKont{}:
      drive(rest, AtomRequest{}, AfterParenAction{steps})
    case _ _ _:
      TermFailure{tokens}

def check_plain(result: Outcome) -> Bool:
  match result:
    case TermSuccess{Ref{"x"}, TkStop{} <> Nil{}}: True{}
    case _: False{}

def check_nested(result: Outcome) -> Bool:
  match result:
    case TermSuccess{Grouped{Ref{"x"}}, TkStop{} <> Nil{}}: True{}
    case _: False{}

def check_return(result: Outcome) -> Bool:
  match result:
    case TermSuccess{DoTerm{Nil{}, Ref{"x"}}, TkStop{} <> Nil{}}: True{}
    case _: False{}

def check_action(result: Outcome) -> Bool:
  match result:
    case TermSuccess{DoTerm{[Act{"action", False{}}], Ref{"x"}}, TkStop{} <> Nil{}}: True{}
    case _: False{}

def check_bind(result: Outcome) -> Bool:
  match result:
    case TermSuccess{DoTerm{[Bound{"x", "action", False{}}], Ref{"x"}}, TkStop{} <> Nil{}}: True{}
    case _: False{}

def check_two(result: Outcome) -> Bool:
  match result:
    case TermSuccess{DoTerm{[Act{"a", False{}}, Bound{"x", "b", False{}}], Ref{"x"}}, TkStop{} <> Nil{}}: True{}
    case _: False{}

def check_nested_action(result: Outcome) -> Bool:
  match result:
    case TermSuccess{DoTerm{[Act{"inner", True{}}], Ref{"x"}}, TkStop{} <> Nil{}}: True{}
    case _: False{}

def check_malformed(result: Outcome) -> Bool:
  match result:
    case TermFailure{TkStop{} <> Nil{}}: True{}
    case _: False{}

def check_remainder(result: Outcome) -> Bool:
  match result:
    case TermSuccess{DoTerm{Nil{}, Ref{"x"}}, TkLine{} <> (TkStop{} <> Nil{})}: True{}
    case _: False{}

def bool_text(value: Bool) -> String:
  match value:
    case True{}: "true"
    case False{}: "false"

law main:
  IO(Unit)

def main():
  IO.print(String.concat(["plain=", bool_text(check_plain(drive([TkWord{"x"}, TkStop{}], TermRequest{}, DoneKont{}))), ";nested=", bool_text(check_nested(drive([TkOpen{}, TkWord{"x"}, TkClose{}, TkStop{}], TermRequest{}, DoneKont{}))), ";return=", bool_text(check_return(drive([TkDo{}, TkMonad{}, TkLt{}, TkArg{}, TkGt{}, TkColon{}, TkReturn{}, TkWord{"x"}, TkStop{}], TermRequest{}, DoneKont{}))), ";action=", bool_text(check_action(drive([TkDo{}, TkMonad{}, TkLt{}, TkArg{}, TkGt{}, TkColon{}, TkWord{"action"}, TkSemi{}, TkReturn{}, TkWord{"x"}, TkStop{}], TermRequest{}, DoneKont{}))), ";bind=", bool_text(check_bind(drive([TkDo{}, TkMonad{}, TkLt{}, TkArg{}, TkGt{}, TkColon{}, TkWord{"x"}, TkBind{}, TkWord{"action"}, TkLine{}, TkReturn{}, TkWord{"x"}, TkStop{}], TermRequest{}, DoneKont{}))), ";two=", bool_text(check_two(drive([TkDo{}, TkMonad{}, TkLt{}, TkArg{}, TkGt{}, TkColon{}, TkWord{"a"}, TkSemi{}, TkWord{"x"}, TkBind{}, TkWord{"b"}, TkLine{}, TkReturn{}, TkWord{"x"}, TkStop{}], TermRequest{}, DoneKont{}))), ";nested-action=", bool_text(check_nested_action(drive([TkDo{}, TkMonad{}, TkLt{}, TkArg{}, TkGt{}, TkColon{}, TkOpen{}, TkWord{"inner"}, TkClose{}, TkSemi{}, TkReturn{}, TkWord{"x"}, TkStop{}], TermRequest{}, DoneKont{}))), ";malformed=", bool_text(check_malformed(drive([TkDo{}, TkMonad{}, TkLt{}, TkArg{}, TkGt{}, TkColon{}, TkReturn{}, TkStop{}], TermRequest{}, DoneKont{}))), ";remainder=", bool_text(check_remainder(drive([TkDo{}, TkMonad{}, TkLt{}, TkArg{}, TkGt{}, TkColon{}, TkReturn{}, TkWord{"x"}, TkLine{}, TkStop{}], TermRequest{}, DoneKont{})))]))
