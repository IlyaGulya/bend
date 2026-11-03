import {describe, expect, test} from 'bun:test';
import {classifyRatio, independentDifference, pairedStats, studentT95} from './selfhost_corpus_calibration.ts';

describe('calibration uncertainty', () => {
  test('uses small-sample Student intervals rather than normal confidence', () => {
    expect(studentT95(1)).toBeCloseTo(12.7062047364, 8);
    expect(studentT95(5)).toBeCloseTo(2.5705818356, 8);
    expect(studentT95(10)).toBeCloseTo(2.2281388520, 8);
    const observed = pairedStats([100, 100], [90, 110]);
    expect(observed.ci95![0]).toBeLessThan(0.9);
    expect(observed.ci95![1]).toBeGreaterThan(1.1);
    expect(classifyRatio(observed.ci95, 0.02)).toBe('inconclusive');
  });

  test('does not qualify a lone fast sample', () => {
    const observed = pairedStats([100], [50]);
    expect(observed.geometricMeanRatio).toBe(0.5);
    expect(observed.ci95).toBeNull();
    expect(classifyRatio(observed.ci95, 0.02)).toBe('inconclusive');
  });

  test('classifies only intervals wholly outside or within the practical band', () => {
    expect(classifyRatio([0.94, 0.97], 0.02)).toBe('improvement');
    expect(classifyRatio([1.03, 1.06], 0.02)).toBe('regression');
    expect(classifyRatio([0.98, 1.02], 0.02)).toBe('equivalent');
    expect(classifyRatio([0.97, 1.01], 0.02)).toBe('inconclusive');
    expect(classifyRatio([0.99, 1.03], 0.02)).toBe('inconclusive');
  });

  test('uses paired ratios rather than dividing pooled medians', () => {
    const observed = pairedStats([100, 200, 400], [90, 220, 360]);
    expect(observed.geometricMeanRatio!).toBeCloseTo(Math.cbrt(0.9 * 1.1 * 0.9), 12);
    expect(observed.geometricMeanRatio).not.toBe(220 / 200);
    expect(classifyRatio(observed.ci95, 0.02)).toBe('inconclusive');
  });

  test('retains independent full and screen uncertainty in magnitude comparison', () => {
    const screen = pairedStats([100, 100, 100, 100], [90, 110, 92, 108]);
    const full = pairedStats([100, 100, 100, 100], [91, 109, 93, 107]);
    const comparison = independentDifference(screen, full)!;
    expect(comparison.ci95[0]).toBeLessThan(-0.03);
    expect(comparison.ci95[1]).toBeGreaterThan(0.03);
    expect(comparison.degreesOfFreedom!).toBeGreaterThan(3);
  });

  test('handles a constant paired ratio without inventing variance', () => {
    const screen = pairedStats([100, 200, 400], [50, 100, 200]);
    const full = pairedStats([20, 40, 80], [10, 20, 40]);
    expect(screen.varianceLog).toBe(0);
    expect(screen.ci95).toEqual([0.5, 0.5]);
    expect(independentDifference(screen, full)!.ci95).toEqual([0, 0]);
    expect(classifyRatio(screen.ci95, 0.02)).toBe('improvement');
  });

  test('rejects unpaired, zero and nonfinite timing data', () => {
    expect(() => pairedStats([1, 2], [1])).toThrow();
    expect(() => pairedStats([0], [1])).toThrow();
    expect(() => pairedStats([1], [Infinity])).toThrow();
    expect(() => studentT95(0)).toThrow();
  });
});
