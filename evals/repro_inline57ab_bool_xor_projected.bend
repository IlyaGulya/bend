# Reduced follow-up to c_target_bool_fields: preserve only the failing
# projected Bool.xor -> Bool.show path. No preceding IO or numeric consumer.
import Base

type Flags is Data:
  Flags{a: Bool, b: Bool}

def different(fs: Flags) -> Bool:
  match fs:
    case Flags{a, b}:
      Bool.xor(a, b)

def main() -> IO(Unit):
  IO.print(Bool.show(different(Flags{True{}, True{}})))

#|False
