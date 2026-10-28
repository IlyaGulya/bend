// The effect is dispatched while the caller's split still holds its captures.
// Reentering compiled code here must leave the outer frame intact, and a throw
// raised inside the machine has to restore the same base before the next call.
function host_reenter(f, x, g, h) {
  const first = f(x);
  if (first !== 17) {
    throw new Error("reentered chain printed " + first);
  }
  let threw = false;
  try {
    g(281474976710655);
  } catch (e) {
    threw = String(e).includes("Nat past the largest immediate");
  }
  if (!threw) {
    throw new Error("the overflowing call did not throw");
  }
  const third = h(x);
  if (third !== 10009) {
    throw new Error("post-exception chain printed " + third);
  }
  return first + third;
}

io_eff(CID(Host.reenter), host_reenter);
