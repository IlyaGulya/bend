import Base
import ../evals/checker_arena_growth_smoke.bend as Growth

# The same source exercises every affine arena pool, 63/64/65 growth,
# reserve, rewind/regrowth, retained prefixes and discarded-slot zeroing.
def main() -> U32:
  U32.add(Growth.mixed(), Growth.reserved())

#|0
