export type FloatFixture = { literal: string; category: string; pinnedBits?: string };

// Pi is deliberately first: --minimal-only is the first compiled regression.
// Decimal ratios use exact 24-bit limbs; mantissas and scales need not fit U48.
export const floatFixtures: readonly FloatFixture[] = [
  { literal: '3.14159265', category: 'pi', pinnedBits: '0x40490fdb' },
  { literal: '3.14159264', category: 'pi-neighbor' },
  { literal: '3.14159266', category: 'pi-neighbor' },
  { literal: '3.1415926', category: 'pi-neighbor', pinnedBits: '0x40490fda' },
  { literal: '3.1415927', category: 'pi-neighbor' },
  { literal: '0.5', category: 'exact-fraction', pinnedBits: '0x3f000000' },
  { literal: '1.0', category: 'exact-integer', pinnedBits: '0x3f800000' },
  { literal: '3.14', category: 'short-decimal', pinnedBits: '0x4048f5c3' },
  { literal: '0.0', category: 'zero', pinnedBits: '0x00000000' },
  { literal: '2.0', category: 'exact-integer', pinnedBits: '0x40000000' },
  { literal: '42.0', category: 'exact-integer', pinnedBits: '0x42280000' },
  { literal: '8388608.0', category: 'exact-integer', pinnedBits: '0x4b000000' },
  { literal: '16777216.0', category: 'exact-integer', pinnedBits: '0x4b800000' },
  { literal: '16777218.0', category: 'exact-integer', pinnedBits: '0x4b800001' },
  { literal: '1.00000005', category: 'rounding-boundary-below', pinnedBits: '0x3f800000' },
  { literal: '1.00000006', category: 'rounding-boundary-above', pinnedBits: '0x3f800001' },
  { literal: '8388608.4', category: 'rounding-boundary-below', pinnedBits: '0x4b000000' },
  { literal: '8388608.6', category: 'rounding-boundary-above', pinnedBits: '0x4b000001' },
  { literal: '8388608.5', category: 'ties-to-even-down', pinnedBits: '0x4b000000' },
  { literal: '8388609.5', category: 'ties-to-even-up', pinnedBits: '0x4b000002' },
  { literal: '16777217.0', category: 'ties-to-even-down', pinnedBits: '0x4b800000' },
  { literal: '16777219.0', category: 'ties-to-even-up', pinnedBits: '0x4b800002' },
  { literal: '3.14159265e0', category: 'decimal-exponent', pinnedBits: '0x40490fdb' },
  { literal: '3.14159265E+0', category: 'decimal-exponent', pinnedBits: '0x40490fdb' },
  { literal: '31.4159265e-1', category: 'decimal-exponent', pinnedBits: '0x40490fdb' },
  { literal: '0.314159265e+1', category: 'decimal-exponent', pinnedBits: '0x40490fdb' },
  { literal: '5.0e-1', category: 'decimal-exponent', pinnedBits: '0x3f000000' },
  { literal: '1.0e+2', category: 'decimal-exponent', pinnedBits: '0x42c80000' },
  { literal: '1.0e-8', category: 'bounded-small-normal' },
  { literal: '1.0e-9', category: 'bounded-small-normal' },
  { literal: '1.0e+8', category: 'bounded-large-normal' },
  { literal: '1.0e-10', category: 'bounded-small-normal' },
  { literal: '1.0e+10', category: 'bounded-large-normal' },
  { literal: '28147497671065.5', category: 'maximum-model-mantissa' },
  { literal: '0.00000000000001', category: 'minimum-model-normal' },
  { literal: '1.0e14', category: 'bounded-large-normal' },
  { literal: '1.40737488355328e14', category: 'extreme-model-normal' },
  { literal: '3.14159265358979323846', category: 'long-decimal' },
  { literal: '1.000000059604644775390625', category: 'long-decimal-ties-to-even', pinnedBits: '0x3f800000' },
  { literal: '1.0e+15', category: 'large-decimal-scale' },
  { literal: '1.0e-14', category: 'small-decimal-scale' },
  { literal: '1.0e-45', category: 'smallest-subnormal', pinnedBits: '0x00000001' },
  { literal: '1.1754942e-38', category: 'largest-subnormal', pinnedBits: '0x007fffff' },
  { literal: '1.17549435e-38', category: 'smallest-normal', pinnedBits: '0x00800000' },
  { literal: '1.152921504606847e18', category: 'base-hypot-large-mantissa' },
];

export type FloatExclusion = {
  literal: string;
  category: 'stage0-unsupported-notation';
  reason: string;
  stage0ShouldAccept: boolean;
};

// These are separate oracle-only observations, never dynamically skipped
// supported fixtures. A rejection or mismatch in floatFixtures always fails.
export const floatExclusions: readonly FloatExclusion[] = [
  { literal: '-3.14159265', category: 'stage0-unsupported-notation', reason: 'Stage0 has no unary-minus numeric literal syntax.', stage0ShouldAccept: false },
  { literal: '-0.5', category: 'stage0-unsupported-notation', reason: 'Stage0 has no unary-minus numeric literal syntax.', stage0ShouldAccept: false },
  { literal: '-0.0', category: 'stage0-unsupported-notation', reason: 'Negative-zero notation is not a stage0 numeric literal.', stage0ShouldAccept: false },
  { literal: '1e3', category: 'stage0-unsupported-notation', reason: 'Stage0 exponent syntax requires a decimal point and fractional digits.', stage0ShouldAccept: false },
  { literal: '.5', category: 'stage0-unsupported-notation', reason: 'Stage0 requires digits before the decimal point.', stage0ShouldAccept: false },
  { literal: '1.', category: 'stage0-unsupported-notation', reason: 'Stage0 requires digits after the decimal point.', stage0ShouldAccept: false },
  { literal: '140737488355328.', category: 'stage0-unsupported-notation', reason: 'Stage0 requires fractional digits.', stage0ShouldAccept: false },
  { literal: '1.e-14', category: 'stage0-unsupported-notation', reason: 'Stage0 requires fractional digits before the exponent.', stage0ShouldAccept: false },
];
