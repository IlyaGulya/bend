import Base
import ../bend2/selfhost/checker_ir.bend as IR
import ../checkpoints/checker_core_steps_v1.bend as Checker

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
