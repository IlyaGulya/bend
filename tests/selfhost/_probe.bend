import Base

def sum_divmod(result: (Nat & Nat) & Bool) -> Nat:
  match result:
    case ((first, second), True{}):
      first + second
    case _:
      0n

law main:
  IO(Unit)

def main():
  IO.print(Nat.show(sum_divmod((3n, 4n, True{}))))
