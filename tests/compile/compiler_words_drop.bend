# Dropping an uncalled closure must release its captured compiler tape.
# Native heap pages remain bounded after allocation warm-up.
import Base

def captured_result(+x: U32, result: CompilerWords & U32) -> U32:
  match result:
    case Tuple{_, value}: U32.add(value, x)

def captured(words: CompilerWords, x: U32) -> U32:
  captured_result(x, CompilerWords.get(words, 12))

def dispose(f: U32 -> U32) -> IO(U32):
  import "./compiler_words_drop.c"
  import "./compiler_words_drop.js"

def loop(n: Nat, +value: U32, last: U32) -> IO(U32):
  match n:
    case 0n: IO.pure(U32, last)
    case 1n+rest:
      do IO<U32>:
        words : CompilerWords = CompilerWords.set(CompilerWords.new(4n), 12, value)
        result : U32 <- dispose(captured(words))
        loop(rest, value, result)

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    result : U32 <- loop(20000n, U32.from_nat(List.length(&1, String, args)), 0)
    IO.print(U32.show(result))

#|5
