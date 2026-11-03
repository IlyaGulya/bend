import Base

type Token is Type:
  Token{value: U32}
type Pair is Type:
  Pair{left: Token, right: Token}

# Deliberately unused: check-only must validate every source body, not only main.
def duplicate(value: Token) -> Pair:
  Pair{value, value}

def main() -> U32:
  0
