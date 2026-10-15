/** Measurement only: object identity, ownership, and selected-row ancestry. */
export interface WildLink {
  splitId: number;
  side: 'constructor' | 'default';
  order: 'before' | 'between' | 'after';
  sourceRow: number;
  previous?: WildLink;
}

export type LamReason = 'skipped-parameter' | 'constructor-field' | 'reply-parameter' | 'other';
type Side = WildLink['side'];
type Order = WildLink['order'];
type SideOrder = `${Side}/${Order}`;

export interface NodeCounts {
  graphObjects: number;
  Sub: number;
  Lam: number;
  Mat: number;
  other: number;
}

export interface RootContribution {
  splitId: number;
  sourceRow: number;
  side: Side;
  order: Order;
  /** Distinct final root identities for this origin, not lowering call count. */
  roots: number;
  /** Recorded selections/envelopes; the same root can be returned repeatedly. */
  rootOccurrences: number;
  /** Sum of tree-expanded root weights; null if any contributing root is cyclic. */
  weightedSubtreeGraphObjects: number | null;
  /** Exact identity union of final root descendants; populated for selectedBody, null for envelopes. */
  uniqueFinalGraphObjects: number | null;
  uniqueFinalNodeKinds: Pick<NodeCounts, 'Sub' | 'Lam' | 'Mat' | 'other'> | null;
}

export interface DescendantUnion {
  roots: number;
  graphObjects: number;
  percentageOfFinalGraphObjects: number;
  sourceOwnedGraphObjects: number;
  /** Each entry is an exact identity union, never a sum of memberships. */
  bySide: Record<Side, number>;
  byOrder: Record<Order, number>;
  bySideOrder: Record<SideOrder, number>;
}

export interface Report {
  graphObjects: number;
  /** Arrays are Array; objects without a string $ tag are Object. */
  nodeKinds: Record<string, number>;
  sourceOwned: NodeCounts;
  unowned: NodeCounts;
  perOwner: Array<NodeCounts & { owner: number }>;
  lamEmissions: Record<LamReason, { finalLams: number; weightedSubtreeGraphObjects: number | null }>;
  weightedSubtrees: {
    definition: string;
    overlap: string;
    safeIntegerWeights: boolean;
    objectsWithCyclicSubtrees: number;
  };
  wildcards: {
    selectedBody: {
      definition: string;
      union: DescendantUnion;
      bySplitSourceRowSideOrder: RootContribution[];
    };
    branchEnvelope: {
      definition: string;
      union: DescendantUnion;
      bySplitSourceRowSideOrder: RootContribution[];
    };
    overlap: string;
  };
}

interface Ownership {
  owner: number;
  lamReason?: LamReason;
}
interface LeafSelection {
  history: WildLink | undefined;
  sourceRow: number;
}
interface WeightFrame {
  node: object;
  children: object[];
  next: number;
  weight: number | null;
}

const sides: readonly Side[] = ['constructor', 'default'];
const orders: readonly Order[] = ['before', 'between', 'after'];
const sideOrders: readonly SideOrder[] = [
  'constructor/before', 'constructor/between', 'constructor/after',
  'default/before', 'default/between', 'default/after',
];

function graphObject(value: unknown): value is object {
  return value !== null && typeof value === 'object';
}

/** Exactly the probe's enumerable graph edges, including arrays and excluding s. */
function children(node: object): object[] {
  const result: object[] = [];
  for (const [key, value] of Object.entries(node)) {
    if (key !== 's' && graphObject(value)) result.push(value);
  }
  return result;
}

function kind(node: object): string {
  if (Array.isArray(node)) return 'Array';
  if ('$' in node && typeof node.$ === 'string') return node.$;
  return 'Object';
}

function counts(): NodeCounts {
  return { graphObjects: 0, Sub: 0, Lam: 0, Mat: 0, other: 0 };
}

function countNode(target: NodeCounts, nodeKind: string): void {
  target.graphObjects++;
  if (nodeKind === 'Sub' || nodeKind === 'Lam' || nodeKind === 'Mat') target[nodeKind]++;
  else target.other++;
}

function bit(link: WildLink): number {
  return 1 << (sides.indexOf(link.side) * orders.length + orders.indexOf(link.order));
}

/** Deduplicate a linked ancestry by numeric origin, not by link object identity. */
function ancestry(history: WildLink | undefined, sourceRow?: number): Map<string, WildLink> {
  const origins = new Map<string, WildLink>();
  const seen = new Set<WildLink>();
  for (let link = history; link !== undefined && !seen.has(link); link = link.previous) {
    seen.add(link);
    if (sourceRow === undefined || link.sourceRow === sourceRow) {
      origins.set(`${link.splitId}/${link.sourceRow}/${link.side}/${link.order}`, link);
    }
  }
  return origins;
}

/** A newly discovered origin is propagated even through previously visited nodes. */
class UnionTracker {
  private readonly masks = new WeakMap<object, number>();
  readonly report: DescendantUnion = {
    roots: 0,
    graphObjects: 0,
    percentageOfFinalGraphObjects: 0,
    sourceOwnedGraphObjects: 0,
    bySide: { constructor: 0, default: 0 },
    byOrder: { before: 0, between: 0, after: 0 },
    bySideOrder: {
      'constructor/before': 0, 'constructor/between': 0, 'constructor/after': 0,
      'default/before': 0, 'default/between': 0, 'default/after': 0,
    },
  };

  constructor(private readonly source: WeakSet<object>) {}

  add(root: object, mask: number): void {
    this.report.roots++;
    const pending = [root];
    while (pending.length > 0) {
      const node = pending.pop()!;
      const old = this.masks.get(node) ?? 0;
      const added = mask & ~old;
      if (added === 0) continue;
      const next = old | added;
      this.masks.set(node, next);
      if (old === 0) {
        this.report.graphObjects++;
        if (this.source.has(node)) this.report.sourceOwnedGraphObjects++;
      }
      for (let index = 0; index < sideOrders.length; index++) {
        if (added & (1 << index)) this.report.bySideOrder[sideOrders[index]]++;
      }
      for (let index = 0; index < sides.length; index++) {
        const sideMask = 7 << (index * orders.length);
        if (!(old & sideMask) && (next & sideMask)) this.report.bySide[sides[index]]++;
      }
      for (let index = 0; index < orders.length; index++) {
        const orderMask = (1 << index) | (1 << (index + orders.length));
        if (!(old & orderMask) && (next & orderMask)) this.report.byOrder[orders[index]]++;
      }
      for (const child of children(node)) pending.push(child);
    }
  }

  finish(graphObjects: number): DescendantUnion {
    this.report.percentageOfFinalGraphObjects = graphObjects === 0 ? 0 : 100 * this.report.graphObjects / graphObjects;
    return this.report;
  }
}

/** No source/intermediate graph is retained outside weak keys. */
export class LoweringNodeAttribution {
  private readonly source = new WeakSet<object>();
  private readonly ownership = new WeakMap<object, Ownership>();
  private readonly selections = new WeakMap<object, LeafSelection[]>();
  private readonly envelopes = new WeakMap<object, Array<readonly WildLink[]>>();

  constructor(rawRoot: unknown) {
    const pending = graphObject(rawRoot) ? [rawRoot] : [];
    while (pending.length > 0) {
      const node = pending.pop()!;
      if (this.source.has(node)) continue;
      this.source.add(node);
      for (const child of children(node)) pending.push(child);
    }
  }

  mark(root: unknown, owner: number, lamReason?: LamReason): void {
    if (!graphObject(root) || this.source.has(root)) return;
    const pending = [root];
    while (pending.length > 0) {
      const node = pending.pop()!;
      if (this.source.has(node) || this.ownership.has(node)) continue;
      this.ownership.set(node, { owner });
      for (const child of children(node)) pending.push(child);
    }
    // Only an actual marked Lam factory root receives its emission class.
    // Recursive observation of a Lam child must not prevent a later factory tag.
    const metadata = this.ownership.get(root);
    if (metadata !== undefined && metadata.lamReason === undefined && kind(root) === 'Lam' && lamReason !== undefined) {
      metadata.lamReason = lamReason;
    }
  }

  leaf(root: unknown, history: WildLink | undefined, sourceRow: number): void {
    if (!graphObject(root)) return;
    const selections = this.selections.get(root);
    const selection = { history, sourceRow };
    if (selections === undefined) this.selections.set(root, [selection]);
    else selections.push(selection);
  }

  branch(root: unknown, histories: readonly WildLink[]): void {
    if (!graphObject(root) || histories.length === 0) return;
    const envelopes = this.envelopes.get(root);
    // Copy only numeric ancestry metadata, never the branch's graph.
    const envelope = histories.slice();
    if (envelopes === undefined) this.envelopes.set(root, [envelope]);
    else envelopes.push(envelope);
  }

  analyze(root: unknown): Report {
    const nodeKinds: Record<string, number> = Object.create(null);
    const sourceOwned = counts(), unowned = counts();
    const owners = new Map<number, NodeCounts & { owner: number }>();
    const lamEmissions: Report['lamEmissions'] = {
      'skipped-parameter': { finalLams: 0, weightedSubtreeGraphObjects: 0 },
      'constructor-field': { finalLams: 0, weightedSubtreeGraphObjects: 0 },
      'reply-parameter': { finalLams: 0, weightedSubtreeGraphObjects: 0 },
      other: { finalLams: 0, weightedSubtreeGraphObjects: 0 },
    };
    const selectedUnion = new UnionTracker(this.source), envelopeUnion = new UnionTracker(this.source);
    const selectedGroups = new Map<string, RootContribution>(), envelopeGroups = new Map<string, RootContribution>();
    // Only final roots discovered by this analysis are held here, never intermediate ASTs.
    const selectedFinalRoots = new Map<string, object[]>();
    let graphObjects = 0, safeIntegerWeights = true, objectsWithCyclicSubtrees = 0;

    function sum(a: number | null, b: number | null): number | null {
      if (a === null || b === null) return null;
      const result = a + b;
      if (!Number.isSafeInteger(result)) safeIntegerWeights = false;
      return result;
    }

    function contribute(
      node: object,
      weight: number | null,
      events: Iterable<Map<string, WildLink>>,
      groups: Map<string, RootContribution>,
      union: UnionTracker,
      finalRoots?: Map<string, object[]>,
    ): void {
      const distinct = new Map<string, WildLink>();
      for (const origins of events) {
        for (const [key, link] of origins) {
          let contribution = groups.get(key);
          if (contribution === undefined) {
            contribution = {
              splitId: link.splitId, sourceRow: link.sourceRow, side: link.side, order: link.order,
              roots: 0, rootOccurrences: 0, weightedSubtreeGraphObjects: 0,
              uniqueFinalGraphObjects: null, uniqueFinalNodeKinds: null,
            };
            groups.set(key, contribution);
          }
          contribution.rootOccurrences++;
          distinct.set(key, link);
        }
      }
      let mask = 0;
      for (const [key, link] of distinct) {
        const contribution = groups.get(key)!;
        contribution.roots++;
        contribution.weightedSubtreeGraphObjects = sum(contribution.weightedSubtreeGraphObjects, weight);
        if (finalRoots !== undefined) {
          const roots = finalRoots.get(key);
          if (roots === undefined) finalRoots.set(key, [node]);
          else roots.push(node);
        }
        mask |= bit(link);
      }
      if (mask !== 0) union.add(node, mask);
    }

    const weights = new WeakMap<object, number | null>();
    const active = new WeakSet<object>();
    const pending: WeightFrame[] = [];
    if (graphObject(root)) {
      pending.push({ node: root, children: children(root), next: 0, weight: 1 });
      active.add(root);
    }
    while (pending.length > 0) {
      const frame = pending[pending.length - 1];
      if (frame.next < frame.children.length) {
        const child = frame.children[frame.next];
        if (weights.has(child)) {
          frame.weight = sum(frame.weight, weights.get(child)!);
          frame.next++;
        } else if (active.has(child)) {
          // Graph counts/unions remain exact. Tree expansion of a cycle is undefined.
          frame.weight = null;
          frame.next++;
        } else {
          active.add(child);
          pending.push({ node: child, children: children(child), next: 0, weight: 1 });
        }
        continue;
      }
      pending.pop();
      active.delete(frame.node);
      weights.set(frame.node, frame.weight);
      graphObjects++;
      if (frame.weight === null) objectsWithCyclicSubtrees++;
      const nodeKind = kind(frame.node);
      nodeKinds[nodeKind] = (nodeKinds[nodeKind] ?? 0) + 1;
      const metadata = this.ownership.get(frame.node);
      if (this.source.has(frame.node)) countNode(sourceOwned, nodeKind);
      else if (metadata === undefined) countNode(unowned, nodeKind);
      else {
        let owner = owners.get(metadata.owner);
        if (owner === undefined) {
          owner = { owner: metadata.owner, ...counts() };
          owners.set(metadata.owner, owner);
        }
        countNode(owner, nodeKind);
      }
      if (nodeKind === 'Lam') {
        const reason = this.source.has(frame.node) ? 'other' : metadata?.lamReason ?? 'other';
        const emission = lamEmissions[reason];
        emission.finalLams++;
        emission.weightedSubtreeGraphObjects = sum(emission.weightedSubtreeGraphObjects, frame.weight);
      }
      const selections = this.selections.get(frame.node);
      if (selections !== undefined) {
        contribute(frame.node, frame.weight,
          selections.map(selection => ancestry(selection.history, selection.sourceRow)), selectedGroups, selectedUnion, selectedFinalRoots);
      }
      const envelopes = this.envelopes.get(frame.node);
      if (envelopes !== undefined) {
        contribute(frame.node, frame.weight, envelopes.map(histories => {
          const origins = new Map<string, WildLink>();
          for (const history of histories) {
            for (const [key, link] of ancestry(history)) origins.set(key, link);
          }
          return origins;
        }), envelopeGroups, envelopeUnion);
      }
    }

    // Each origin gets its own identity union. Counts remain inclusive across
    // different origins, but sharing within one origin is counted only once.
    for (const [key, roots] of selectedFinalRoots) {
      const seen = new WeakSet<object>();
      const unique = counts();
      const pending = [...roots];
      while (pending.length > 0) {
        const node = pending.pop()!;
        if (seen.has(node)) continue;
        seen.add(node);
        countNode(unique, kind(node));
        for (const child of children(node)) pending.push(child);
      }
      const contribution = selectedGroups.get(key)!;
      contribution.uniqueFinalGraphObjects = unique.graphObjects;
      contribution.uniqueFinalNodeKinds = {
        Sub: unique.Sub, Lam: unique.Lam, Mat: unique.Mat, other: unique.other,
      };
    }
    selectedFinalRoots.clear();

    const compareContributions = (a: RootContribution, b: RootContribution): number =>
      a.splitId - b.splitId || a.sourceRow - b.sourceRow || sides.indexOf(a.side) - sides.indexOf(b.side) || orders.indexOf(a.order) - orders.indexOf(b.order);
    return {
      graphObjects, nodeKinds, sourceOwned, unowned,
      perOwner: [...owners.values()].sort((a, b) => a.owner - b.owner),
      lamEmissions,
      weightedSubtrees: {
        definition: 'One object per root plus recursively tree-expanded enumerable object edges, including arrays/Quant/Patt and excluding s; memoized only during analysis. Cyclic subtree weights are null.',
        overlap: 'Weighted subtree totals overlap through shared objects and ancestor roots; never sum them as unique final graph percentages.',
        safeIntegerWeights, objectsWithCyclicSubtrees,
      },
      wildcards: {
        selectedBody: {
          definition: 'Exact final identity union descended from Body outputs actually selected by leaf; ancestry is restricted to that selected source row. Includes reused source-owned objects, not a claim that every descendant is newly allocated or avoidable.',
          union: selectedUnion.finish(graphObjects),
          bySplitSourceRowSideOrder: [...selectedGroups.values()].sort(compareContributions),
        },
        branchEnvelope: {
          definition: 'Exact final identity union descended from branch result roots carrying duplicated wildcard candidates. Branch envelopes include non-selected candidates and are NOT causal wildcard Body allocation.',
          union: envelopeUnion.finish(graphObjects),
          bySplitSourceRowSideOrder: [...envelopeGroups.values()].sort(compareContributions),
        },
        overlap: 'Per-split/source-row contributions are inclusive and non-additive across nested splits and shared roots. Side/order unions overlap each other; only each explicitly computed union has a unique final percentage.',
      },
    };
  }
}
