# Packed compiler words preserve values, wrapping, zero fill and affine owners
# through direct calls, native function values and captured partial applications.
import Base

type WordsOps is Type:
  WordsOps{build: @+depth: Nat -> CompilerWords, expand: CompilerWords -> CompilerWords}

type WordsReader is Type:
  WordsReader{read: @+index: U32 -> CompilerWords & U32}

type WordsWriter is Type:
  WordsWriter{write: @+index: U32 -> @+value: U32 -> CompilerWords}

def finish(result: CompilerWords & U32) -> U32:
  match result:
    case Tuple{_, value}: value

def check_step(expected: List<&2, U32>, +index: U32, ok: Bool, result: CompilerWords & U32) -> Bool:
  match expected result:
    case Nil{} Tuple{_, _}: ok
    case +head <> Nil{} Tuple{_, value}: Bool.and(ok, U32.is_eq(value, head))
    case +head <> rest Tuple{words, value}:
      check_step(rest, U32.add(index, 1), Bool.and(ok, U32.is_eq(value, head)), CompilerWords.get(words, U32.add(index, 1)))

def check(words: CompilerWords, +index: U32, expected: List<&2, U32>) -> Bool:
  check_step(expected, index, True{}, CompilerWords.get(words, index))

def from_ops(ops: WordsOps, depth: Nat) -> CompilerWords:
  match ops:
    case WordsOps{build, expand}: expand(build(depth))

def hold_read(words: CompilerWords) -> WordsReader:
  WordsReader{CompilerWords.get(words)}

def read_held(reader: WordsReader, index: U32) -> U32:
  match reader:
    case WordsReader{read}: finish(read(index))

def hold_write(words: CompilerWords) -> WordsWriter:
  WordsWriter{CompilerWords.set(words)}

def write_held(writer: WordsWriter, index: U32, value: U32) -> CompilerWords:
  match writer:
    case WordsWriter{write}: write(index, value)

def seed() -> CompilerWords:
  CompilerWords.set(CompilerWords.set(CompilerWords.set(CompilerWords.set(CompilerWords.new(2n), 0, 2147483648), 1, 4294967295), 2, 2863311530), 3, 7)

def report(label: String, ok: Bool) -> IO(Unit):
  IO.print(String.append(label, U32.show(Bool.to_u32(ok))))

def main() -> IO(Unit):
  do IO<Unit>:
    report("new-zero:", check(CompilerWords.new(3n), 0, [0, 0, 0, 0, 0, 0, 0, 0]))
    report("grow-min:", check(CompilerWords.grow(CompilerWords.set(CompilerWords.new(0n), 4294967295, 4294967295)), 0, [4294967295, 0]))
    report("grow-chain:", check(CompilerWords.grow(CompilerWords.grow(seed())), 0, [2147483648, 4294967295, 2863311530, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))
    report("wrap-index:", check(CompilerWords.set(CompilerWords.set(CompilerWords.new(3n), 4294967295, 4294967295), 2147483648, 2147483648), 2147483648, [2147483648, 0, 0, 0, 0, 0, 0, 4294967295]))
    report("native-values:", check(from_ops(WordsOps{CompilerWords.new, CompilerWords.grow}, 2n), 0, [0, 0, 0, 0, 0, 0, 0, 0]))
    IO.print(U32.show(read_held(hold_read(CompilerWords.grow(CompilerWords.set(CompilerWords.new(0n), 0, 41))), 4294967294)))
    IO.print(U32.show(finish(CompilerWords.get(write_held(hold_write(CompilerWords.new(1n)), 4294967295, 4294967295), 3))))

#|new-zero:1
#|grow-min:1
#|grow-chain:1
#|wrap-index:1
#|native-values:1
#|41
#|4294967295
