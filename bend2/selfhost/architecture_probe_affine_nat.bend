import Base

def share_nat(+code: Nat) -> Nat & Bool:
  (code, Nat.is_lt(64n, code))

law main:
  Nat & Bool

def main():
  share_nat(65n)

#|(65n, True{})
