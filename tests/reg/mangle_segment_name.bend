# regression witness: an internal segment's name must not take a macro spelling
# that a user name already holds. A closure gets a segment named after its def
# and the segment counter -- `main$c13` here -- and a def may well be named
# `main_c13`, which folds to the same FID_MAIN_C13. While the macro for an
# internal name was worked out from the name itself, the two met and the emitter
# refused the program ("two names mangle to FID_MAIN_C13"). An internal name is
# not an ABI, so it is the one that takes the suffix. The number is the counter
# this compiler emits; an edit that moves the counter moves the collision with
# it.
import Base

def main_c13(x: U32) -> U32:
  (x + 1 : U32)

def foo(f: U32 -> U32, g: U32 -> U32, h: U32 -> U32, i: U32 -> U32) -> U32:
  (f(g(h(i(1)))) : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(foo(x => (x + 1 : U32), x => (x + 2 : U32), x => (x + 3 : U32), x => (x + 4 : U32))))
    IO.print(U32.show(foo(x => (x + 5 : U32), x => (x + 6 : U32), x => (x + 7 : U32), x => (x + 8 : U32))))
    IO.print(U32.show(main_c13(41)))

#|11
#|27
#|42
