import Base

# A literal and an odd-word arm overlap the default. Captured formals and
# returned binder identities must remain distinct when coverage is compared.
def overlap(n: U32, live: U32) -> U32:
  match n:
    case 0: U32.add(live, 10)
    case U32{WCon{True{}, _}}: U32.add(live, 20)
    case _: U32.add(live, 30)

def binder(n: U32, live: U32) -> U32 -> U32 -> U32:
  match n:
    case 0: x => y => U32.add(x, live)
    case U32{WCon{True{}, _}}: x => y => U32.add(y, live)
    case _: x => y => U32.add(x, live)

def main() -> IO(Unit):
  IO.print(String.join([
    U32.show(overlap(0, 7)),
    U32.show(overlap(1, 7)),
    U32.show(overlap(2, 7)),
    U32.show(overlap(3, 7)),
    U32.show(overlap(4294967295, 7)),
    U32.show(overlap(4294967294, 7)),
    U32.show(binder(0, 7)(5)(9)),
    U32.show(binder(1, 7)(5)(9)),
    U32.show(binder(2, 7)(5)(9)),
    U32.show(binder(3, 7)(5)(9)),
    U32.show(binder(4294967295, 7)(5)(9)),
    U32.show(binder(4294967294, 7)(5)(9))
  ], ","))

#|17,27,37,27,27,37,12,16,12,16,16,12
