# Nested constructor fields preserve source order and the shared value needed
# by a later field. Execute the stored affine IO actions only after unpacking.
import Base

type CtorActions is Type:
  CtorActions{first: IO(Unit), rest: CtorActionsTail}

type CtorActionsTail is Type:
  CtorActionsTail{second: IO(Unit), third: IO(Unit)}

def actions(+text: String) -> CtorActions:
  CtorActions{IO.print(text), CtorActionsTail{IO.print("middle"), IO.print(text)}}

def run(value: CtorActions) -> IO(Unit):
  match value:
    case CtorActions{first, rest}:
      match rest:
        case CtorActionsTail{second, third}:
          do IO<Unit>:
            Unit <- first
            Unit <- second
            third

def main() -> IO(Unit):
  run(actions("shared"))

#|shared
#|middle
#|shared
