import Base

type Token is Type:
  Token{value: U32}

def read(token: Token) -> U32:
  match token:
    case Token{value}: value

def main() -> U32:
  read(Token{42})

#|42
