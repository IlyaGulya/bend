import {createHash, type Hash} from 'node:crypto';
import type {Body, Match, PVar} from '../bend2/bend.ts';

/**
 * Measurement-only keys; none of these maps contains a compilation result.
 *
 * K1 projects exactly the observer's domain: ordered e/p structural spelling
 * (absolute IDs, names and quantities, no s), row Body object identities, and
 * ordered remaining vars' i/q.$ only. Framing removes delimiter ambiguities in
 * the old observer's concatenated strings without dropping structural detail.
 *
 * K2 traverses the full matrix, then vars, depth-first: record fields in sorted
 * UTF-16 order, arrays in index order. Every numeric i in Var/PVar/Sub/Lam/All,
 * and every entry of Let.i, is assigned its first-occurrence ordinal in ONE
 * state-wide map. Occurrences before declarations are intentional (sorted
 * fields can visit bodies first). Only s and the k display-name fields of
 * Var/PVar/Lam/All/Let disappear. Ref/Ctr/PCtr/Mat/ADT and other names remain.
 * K3 uses the same rule/map, but visits e, ordered row patterns, then vars;
 * row f is never visited, so its binders cannot influence K3's numbering.
 * kAbsolute is K2's full structural projection with the same display names
 * excluded, but with absolute IDs: it isolates ID renaming from structural
 * row-body equality. Its own hash domain intentionally differs from K2.
 *
 * Alpha/absolute structures are compositional weak metadata templates. A node
 * records a structural hash with LOCAL ID ordinals, its ordered original-ID
 * list, and an absolute structural hash. Each parent hashes the child's local
 * hash AND maps every child-local ordinal to a parent-local ordinal. The same
 * instantiation happens into a state-wide map. Thus repeated IDs across child
 * boundaries remain visible; independent alpha hashes alone would lose them.
 * Inductively these templates induce the same equality partition as a full
 * serial alpha walk (modulo hash collisions), though digest bytes differ.
 * Cached descriptors contain only hashes/numeric arrays, never child ASTs.
 *
 * This is bijective renaming of the IR's unique lexical IDs, not name-based
 * scope resolution. Distinct IDs stay distinct even when display names shadow;
 * an ID repeated through substitutions/cloned patterns stays the same binder.
 * Inputs must be immutable acyclic source IR with unique lexical IDs, not an
 * IR that reuses one numeric ID for unrelated shadowed binders or runtime HTerm
 * share cells. Such reuse requires lexical resolution before using these keys.
 * K1's weak digest memo likewise assumes objects are not subsequently mutated.
 * Object sharing (except K1 row-body identity) does not affect structural keys.
 * SHA-256 collisions remain theoretically possible; keys are diagnostics, not
 * proof of semantic equivalence or permission to share compilation results.
 */
export class MatrixStateKeys {
  private readonly bodyIds = new WeakMap<Body, number>();
  private readonly exactDigests = new WeakMap<object, string>();
  private nextBodyId = 0;
  private readonly stateStream = new DigestStream();
  private readonly objectStream = new DigestStream();
  private readonly templates = new TemplateDigests();

  keys(m: Match, vars: PVar[]): {k1: string; k2: string; k3: string; kAbsolute: string} {
    const k1 = this.exactKey(m, vars);
    const k2 = this.alphaKey(m, vars, true);
    const k3 = this.alphaKey(m, vars, false);
    const kAbsolute = this.absoluteKey(m, vars);
    return {k1, k2, k3, kAbsolute};
  }

  private exactKey(m: Match, vars: PVar[]): string {
    const stream = this.stateStream;
    stream.begin('matrix-k1');
    stream.array(m.e.length);
    for (const expression of m.e) stream.text(this.exactDigest(expression));
    stream.array(m.r.length);
    for (const row of m.r) {
      stream.array(row.p.length);
      for (const pattern of row.p) stream.text(this.exactDigest(pattern));
      let id = this.bodyIds.get(row.f);
      if (id === undefined) {
        id = this.nextBodyId++;
        this.bodyIds.set(row.f, id);
      }
      stream.number(id);
    }
    stream.array(vars.length);
    for (const variable of vars) {
      stream.number(variable.i);
      stream.text(variable.q.$);
    }
    return stream.finish();
  }

  private exactDigest(value: object): string {
    const prior = this.exactDigests.get(value);
    if (prior !== undefined) return prior;
    this.objectStream.begin('exact-structure');
    serialize(this.objectStream, value);
    const digest = this.objectStream.finish();
    this.exactDigests.set(value, digest);
    return digest;
  }
  private absoluteKey(m: Match, vars: PVar[]): string {
    const matrix = this.templates.get(m);
    const remaining = this.templates.get(vars);
    const stream = this.stateStream;
    stream.begin('matrix-kAbsolute');
    stream.text(matrix.absolute);
    stream.text(remaining.absolute);
    return stream.finish();
  }

  private alphaKey(m: Match, vars: PVar[], includeBodies: boolean): string {
    const stream = this.stateStream;
    const ids = new Map<number, number>();
    stream.begin(includeBodies ? 'matrix-k2' : 'matrix-k3');
    if (includeBodies) {
      instantiate(stream, this.templates.get(m), ids);
    } else {
      instantiate(stream, this.templates.get(m.e), ids);
      stream.array(m.r.length);
      for (const row of m.r) instantiate(stream, this.templates.get(row.p), ids);
    }
    instantiate(stream, this.templates.get(vars), ids);
    return stream.finish();
  }
}

/** Fixed-size reusable buffer; strings are streamed as exact UTF-16 code units. */
class DigestStream {
  private readonly buffer = Buffer.allocUnsafe(4096);
  private used = 0;
  private hash: Hash | undefined;

  begin(domain: string): void {
    this.used = 0;
    this.hash = createHash('sha256');
    this.text(domain);
  }

  private flush(): void {
    if (this.used !== 0) {
      this.hash!.update(this.buffer.subarray(0, this.used));
      this.used = 0;
    }
  }

  byte(value: number): void {
    if (this.used === this.buffer.length) this.flush();
    this.buffer[this.used++] = value;
  }

  private count(value: number): void {
    const digits = String(value);
    for (let i = 0; i < digits.length; ++i) this.byte(digits.charCodeAt(i));
    this.byte(58); // ':' separates the decimal count from its payload.
  }

  text(value: string): void {
    this.byte(115); // s
    this.count(value.length);
    for (let i = 0; i < value.length; ++i) {
      const unit = value.charCodeAt(i);
      this.byte(unit & 255);
      this.byte(unit >>> 8);
    }
  }

  number(value: number): void {
    this.byte(100); // d; distinct from string and bigint.
    this.text(Object.is(value, -0) ? '-0' : String(value));
  }

  array(length: number): void {
    this.byte(91); // [
    this.count(length);
  }

  record(length: number): void {
    this.byte(123); // {
    this.count(length);
  }

  finish(): string {
    this.flush();
    const digest = this.hash!.digest('hex');
    this.hash = undefined;
    return digest;
  }
}

type Frame =
  | {kind: 'value'; value: unknown}
  | {kind: 'array'; value: readonly unknown[]; index: number}
  | {kind: 'record'; value: Record<string, unknown>; fields: string[]; index: number};

function hasBinderIds(tag: unknown): boolean {
  return tag === 'Var' || tag === 'PVar' || tag === 'Sub'
    || tag === 'Lam' || tag === 'All' || tag === 'Let';
}

function hasDisplayName(tag: unknown): boolean {
  return tag === 'Var' || tag === 'PVar' || tag === 'Lam'
    || tag === 'All' || tag === 'Let';
}

/** K1's original structural projection; streamed without recursive calls. */
function serialize(stream: DigestStream, root: unknown): void {
  const stack: Frame[] = [{kind: 'value', value: root}];
  while (stack.length !== 0) {
    const frame = stack.pop()!;
    if (frame.kind === 'array') {
      if (frame.index < frame.value.length) {
        const index = frame.index++;
        stack.push(frame);
        if (!Object.hasOwn(frame.value, index)) stream.byte(104);
        else stack.push({kind: 'value', value: frame.value[index]});
      }
      continue;
    }
    if (frame.kind === 'record') {
      if (frame.index < frame.fields.length) {
        const field = frame.fields[frame.index++];
        stream.text(field);
        stack.push(frame);
        stack.push({kind: 'value', value: frame.value[field]});
      }
      continue;
    }
    const value = frame.value;
    if (value !== null && typeof value === 'object') {
      if (Array.isArray(value)) {
        stream.array(value.length);
        stack.push({kind: 'array', value, index: 0});
      } else {
        const record = value as Record<string, unknown>;
        const fields = Object.keys(record).filter(field => field !== 's').sort();
        stream.record(fields.length);
        stack.push({kind: 'record', value: record, fields, index: 0});
      }
    } else {
      scalar(stream, value);
    }
  }
}

function scalar(stream: DigestStream, value: unknown): void {
  if (value === null) {
    stream.byte(110);
    return;
  }
  switch (typeof value) {
    case 'undefined': stream.byte(117); break;
    case 'boolean': stream.byte(value ? 116 : 102); break;
    case 'string': stream.text(value); break;
    case 'bigint': stream.byte(98); stream.text(String(value)); break;
    case 'number': stream.number(value); break;
    default:
      throw new TypeError(`Matrix state contains unsupported ${typeof value}; expected source IR`);
  }
}

type Descriptor = {
  alpha: string;
  absolute: string;
  ids: readonly number[];
};

const NO_IDS: readonly number[] = [];

/** Map a child's local ordinals into the parent's/state's shared namespace. */
function instantiate(stream: DigestStream, child: Descriptor, ids: Map<number, number>): void {
  stream.text(child.alpha);
  stream.array(child.ids.length);
  for (const original of child.ids) {
    let ordinal = ids.get(original);
    if (ordinal === undefined) {
      ordinal = ids.size;
      ids.set(original, ordinal);
    }
    stream.number(ordinal);
  }
}

type TemplateFrame = {
  value: object;
  binderIds: boolean;
  fields: string[] | undefined;
};

type TemplateJob =
  | {kind: 'visit'; value: object; binderIds: boolean}
  | {kind: 'finish'; frame: TemplateFrame};

/**
 * Weak per-object metadata only. Let.i arrays need a separate contextual memo:
 * the same numeric array interpreted as ordinary data must NOT rename IDs.
 */
class TemplateDigests {
  private readonly ordinary = new WeakMap<object, Descriptor>();
  private readonly binderArrays = new WeakMap<object, Descriptor>();
  private readonly alphaStream = new DigestStream();
  private readonly absoluteStream = new DigestStream();
  private readonly hole: Descriptor;

  constructor() {
    this.alphaStream.begin('template-hole');
    this.alphaStream.byte(104);
    const digest = this.alphaStream.finish();
    this.hole = {alpha: digest, absolute: digest, ids: NO_IDS};
  }

  get(value: object): Descriptor {
    const prior = this.ordinary.get(value);
    if (prior !== undefined) return prior;
    const jobs: TemplateJob[] = [{kind: 'visit', value, binderIds: false}];
    while (jobs.length !== 0) {
      const job = jobs.pop()!;
      if (job.kind === 'finish') {
        const descriptor = this.finish(job.frame);
        this.cache(job.frame.value, job.frame.binderIds).set(job.frame.value, descriptor);
        continue;
      }
      const cache = this.cache(job.value, job.binderIds);
      if (cache.has(job.value)) continue;
      const array = Array.isArray(job.value);
      const record = job.value as Record<string, unknown>;
      const fields = array ? undefined : Object.keys(record)
        .filter(field => field !== 's' && !(field === 'k' && hasDisplayName(record.$)))
        .sort();
      const frame: TemplateFrame = {value: job.value, binderIds: job.binderIds, fields};
      jobs.push({kind: 'finish', frame});
      if (array) {
        const values: readonly unknown[] = job.value as readonly unknown[];
        for (let i = values.length - 1; i >= 0; --i) {
          const child = values[i];
          if (Object.hasOwn(values, i) && child !== null && typeof child === 'object') {
            jobs.push({kind: 'visit', value: child, binderIds: job.binderIds});
          }
        }
      } else {
        for (let i = fields!.length - 1; i >= 0; --i) {
          const field = fields![i];
          const child = record[field];
          if (child !== null && typeof child === 'object') {
            jobs.push({
              kind: 'visit', value: child,
              binderIds: field === 'i' && hasBinderIds(record.$),
            });
          }
        }
      }
    }
    return this.ordinary.get(value)!;
  }

  private cache(value: object, binderIds: boolean): WeakMap<object, Descriptor> {
    return binderIds && Array.isArray(value) ? this.binderArrays : this.ordinary;
  }

  private child(value: unknown, binderIds: boolean): Descriptor {
    if (value !== null && typeof value === 'object') {
      return this.cache(value, binderIds).get(value)!;
    }
    this.alphaStream.begin('template-scalar');
    scalar(this.alphaStream, binderIds && typeof value === 'number' ? 0 : value);
    const alpha = this.alphaStream.finish();
    if (!binderIds || typeof value !== 'number') {
      return {alpha, absolute: alpha, ids: NO_IDS};
    }
    this.absoluteStream.begin('template-scalar');
    scalar(this.absoluteStream, value);
    return {alpha, absolute: this.absoluteStream.finish(), ids: [value]};
  }

  private finish(frame: TemplateFrame): Descriptor {
    // Resolve all child metadata BEFORE opening the parent hash streams.
    const children: Descriptor[] = [];
    if (frame.fields === undefined) {
      const values = frame.value as readonly unknown[];
      for (let i = 0; i < values.length; ++i) {
        children.push(Object.hasOwn(values, i) ? this.child(values[i], frame.binderIds) : this.hole);
      }
    } else {
      const record = frame.value as Record<string, unknown>;
      for (const field of frame.fields) {
        children.push(this.child(record[field], field === 'i' && hasBinderIds(record.$)));
      }
    }
    const alpha = this.alphaStream;
    const absolute = this.absoluteStream;
    alpha.begin('template-alpha-node');
    absolute.begin('template-absolute-node');
    if (frame.fields === undefined) {
      alpha.array(children.length);
      absolute.array(children.length);
    } else {
      alpha.record(children.length);
      absolute.record(children.length);
    }
    const ids = new Map<number, number>();
    for (let i = 0; i < children.length; ++i) {
      if (frame.fields !== undefined) {
        alpha.text(frame.fields[i]);
        absolute.text(frame.fields[i]);
      }
      instantiate(alpha, children[i], ids);
      absolute.text(children[i].absolute);
    }
    return {
      alpha: alpha.finish(), absolute: absolute.finish(),
      ids: ids.size === 0 ? NO_IDS : Array.from(ids.keys()),
    };
  }
}
