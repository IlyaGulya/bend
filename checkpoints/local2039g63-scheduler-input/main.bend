import Base
import ../../bend2/selfhost/checker_ir.bend as IR
import ../checker_core_steps_v1.bend as Checker

# Chunk fuel counts scheduler transitions, not source recursion or stack depth.
# A completed inner result still needs its continuation and final stack pop.
def increment(box: Checker.CheckerValue<U32>) -> Checker.CheckerProgress<U32>:
  match box:
    case Checker.CheckerValue{value}:
      Checker.CheckerFinished{Checker.CheckerValue{U32.add(value, 1)}}

def wrap(count: Nat, progress: Checker.CheckerProgress<U32>) -> Checker.CheckerProgress<U32>:
  match count:
    case 0n: progress
    case 1n+rest: wrap(rest, Checker.CheckerBound{U32, progress, increment})

def run(progress: Checker.CheckerProgress<U32>) -> Checker.CheckerRun<U32>:
  Checker.CheckerRunState{U32, progress, Checker.CheckerStackDone{{==}}}

def pure(count: Nat) -> Checker.CheckerRun<U32>:
  run(wrap(count, Checker.CheckerFinished{Checker.CheckerValue{0}}))

def request() -> Checker.CheckerRequest:
  Checker.CheckerRequestGroup_0{Checker.CheckerRequest_occurrence_term{IR.TypedOccurrence{17, 0, None{}, None{}, [], []}}}

def pending(count: Nat) -> Checker.CheckerRun<U32>:
  run(wrap(count, Checker.CheckerPending{request(), box => Checker.CheckerFinished{box}}))

def direct(count: Nat) -> Checker.CheckerRun<U32>:
  run(wrap(count, Checker.CheckerDirect{U32, request(), 40,
    argument => Checker.CheckerFinished{Checker.CheckerValue{U32.add(argument, 1)}},
    box => Checker.CheckerFinished{box}}))

def score(value: Checker.CheckerRun<U32>) -> U32:
  match value:
    case Checker.CheckerRunFinished{Checker.CheckerValue{result}}: result
    case Checker.CheckerRunState{_, _, _}: 4294967295

def heterogeneous() -> Checker.CheckerRun<Bool>:
  Checker.CheckerRunState{U32, Checker.CheckerFinished{Checker.CheckerValue{7}},
    Checker.CheckerStackMore{Bool,
      box => Checker.CheckerFinished{Checker.CheckerValue{U32.is_eq(Checker.checker_unbox(U32, box), 7)}},
      Checker.CheckerStackDone{{==}}}}

def bool_score(value: Checker.CheckerRun<Bool>) -> U32:
  match value:
    case Checker.CheckerRunFinished{Checker.CheckerValue{result}}: Bool.to_u32(result)
    case Checker.CheckerRunState{_, _, _}: 2

# Observe yielded progress and stack through the public typed constructors.
# Hundreds identify progress; low digits count frames. RunFinished is zero.
def progress_tag(-A: Type, progress: Checker.CheckerProgress<A>) -> U32:
  match progress:
    case Checker.CheckerFinished{_}: 100
    case Checker.CheckerPending{_, _}: 200
    case Checker.CheckerDirect{_, _, _, _, _}: 300
    case Checker.CheckerBound{_, _, _}: 400

def stack_depth(-A: Type, -R: Type, stack: Checker.CheckerStack<A, R>) -> U32:
  match stack:
    case Checker.CheckerStackDone{_}: 0
    case Checker.CheckerStackMore{B, _, rest}: U32.add(1, stack_depth(B, R, rest))

def boundary(-R: Type, value: Checker.CheckerRun<R>) -> U32:
  match value:
    case Checker.CheckerRunFinished{_}: 0
    case Checker.CheckerRunState{A, progress, stack}:
      U32.add(progress_tag(A, progress), stack_depth(A, R, stack))

# This affine capture crosses Direct.invoke, its resume, and a nested Bound.
# Each level costs four transitions (including its later increment pop);
# the final StackDone pop costs one. Sixteen levels finish at tick 65, not 64.
type Token is Type:
  Token{value: U32}

def consume(token: Token) -> Checker.CheckerProgress<U32>:
  match token:
    case Token{value}: Checker.CheckerFinished{Checker.CheckerValue{value}}

def nested(count: Nat, token: Token) -> Checker.CheckerProgress<U32>:
  match count:
    case 0n: consume(token)
    case 1n+rest:
      Checker.CheckerDirect{Token, request(), token, consume,
        box => Checker.CheckerBound{U32,
          nested(rest, Token{U32.add(Checker.checker_unbox(U32, box), 1)}), increment}}

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(score(Checker.checker_chunk(U32, 0n, pure(0n)))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 0n, Checker.CheckerRunFinished{Checker.CheckerValue{37}}))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 1n, pure(0n)))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 2n, pure(1n)))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 3n, pure(1n)))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 63n, pure(31n)))))
    IO.print(U32.show(score(Checker.checker_step(U32, pure(32n)))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 1n, Checker.checker_step(U32, pure(32n))))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 33n, Checker.checker_chunk(U32, 32n, pure(32n))))))
    IO.print(U32.show(score(Checker.checker_step(U32, pending(31n)))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 1n, Checker.checker_step(U32, pending(31n))))))
    IO.print(U32.show(score(Checker.checker_step(U32, direct(31n)))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 1n, Checker.checker_step(U32, direct(31n))))))
    IO.print(U32.show(bool_score(Checker.checker_chunk(Bool, 1n, heterogeneous()))))
    IO.print(U32.show(bool_score(Checker.checker_chunk(Bool, 2n, heterogeneous()))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 0n, pure(32n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 1n, pure(32n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 63n, pure(32n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 64n, pure(32n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 65n, pure(32n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 0n, pending(0n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 1n, pending(0n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 31n, pending(31n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 63n, pending(31n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 64n, pending(31n)))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 65n, pending(31n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 0n, direct(0n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 1n, direct(0n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 31n, direct(31n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 63n, direct(31n)))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 64n, direct(31n)))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 65n, direct(31n)))))
    IO.print(U32.show(boundary(Bool, Checker.checker_chunk(Bool, 0n, heterogeneous()))))
    IO.print(U32.show(boundary(Bool, Checker.checker_chunk(Bool, 1n, heterogeneous()))))
    IO.print(U32.show(bool_score(Checker.checker_chunk(Bool, 63n, heterogeneous()))))
    IO.print(U32.show(bool_score(Checker.checker_chunk(Bool, 64n, heterogeneous()))))
    IO.print(U32.show(bool_score(Checker.checker_chunk(Bool, 65n, heterogeneous()))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 1n, Checker.CheckerRunFinished{Checker.CheckerValue{37}}))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 63n, Checker.CheckerRunFinished{Checker.CheckerValue{37}}))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 64n, Checker.CheckerRunFinished{Checker.CheckerValue{37}}))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 65n, Checker.CheckerRunFinished{Checker.CheckerValue{37}}))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 0n, run(nested(16n, Token{9}))))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 1n, run(nested(16n, Token{9}))))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 63n, run(nested(16n, Token{9}))))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 64n, run(nested(16n, Token{9}))))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 65n, run(nested(16n, Token{9}))))))
    IO.print(U32.show(boundary(U32, Checker.checker_chunk(U32, 0n,
      Checker.checker_chunk(U32, 1n, run(nested(16n, Token{9})))))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 64n, Checker.checker_chunk(U32, 0n,
      Checker.checker_chunk(U32, 1n, run(nested(16n, Token{9}))))))))
    IO.print(U32.show(score(Checker.checker_chunk(U32, 1n, Checker.checker_step(U32, run(nested(16n, Token{9})))))))

#|4294967295
#|37
#|0
#|4294967295
#|1
#|31
#|4294967295
#|32
#|32
#|4294967295
#|48
#|4294967295
#|72
#|2
#|1
#|400
#|401
#|101
#|100
#|0
#|200
#|101
#|231
#|101
#|100
#|48
#|300
#|101
#|331
#|101
#|100
#|72
#|101
#|100
#|1
#|1
#|1
#|37
#|37
#|37
#|37
#|300
#|101
#|101
#|100
#|41
#|101
#|41
#|41
