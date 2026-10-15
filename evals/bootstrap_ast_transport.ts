import { createHash } from "node:crypto";
import { types } from "node:util";
import { openSync, closeSync, writeFileSync, createReadStream } from "node:fs";
import type { Node, Value } from "./parser_full_semantic_normalize.ts";
import {StringDecoder} from "node:string_decoder";

// References keep the JSON envelope at constant depth, even for linked bodies.
// Unlike a tagged JSON replacer, these disjoint slots cannot collide with a ctor.
type Slot = ["ref", number] | ["value", string | number | boolean | null]
  | ["bigint", string] | ["undefined"] | ["number", string];
type Record = ["object" | "array", number, [string, Slot][]];
type Envelope = { format: "bend-native-ast-v1"; root: Slot; records: Record[] };
export type NativeValue = string | number | boolean | bigint | null | undefined | NativeValue[] | NativeObject;
export type NativeObject = { [key: string]: NativeValue };
type Properties = { [key: string]: unknown };

const constructorFields = Symbol.for("bend.fields");
function validateConstructorFields(value: Properties, keys: readonly string[]): void {
  if (!(constructorFields in value) || !Object.prototype.hasOwnProperty.call(value, constructorFields)) return;
  const slots = value[constructorFields];
  if (typeof value.$ !== "string" || !Array.isArray(slots)) throw Error("Invalid native constructor field metadata");
  let index = 0;
  for (const key of keys) {
    if (key === "$") continue;
    if (index >= slots.length || !Object.is(value[key], slots[index++])) throw Error("Native constructor positional/named fields disagree");
  }
  if (index !== slots.length) throw Error("Native constructor positional/named field count differs");
}

/** Preserve enumerable string fields, their order, arrays (including holes),
 * BigInt, and sharing/cycles. Canonical constructor symbol metadata is validated
 * as positional aliases of the complete named payload, not serialized twice.
 * Prototypes and other non-enumerable/symbol properties are outside this ABI. */
function* nativeAstChunks(native: unknown): Generator<string> {
  const objects: object[] = [], ids = new Map<object, number>();
  function slot(value: unknown): Slot {
    switch (typeof value) {
      case "undefined": return ["undefined"];
      case "bigint": return ["bigint", String(value)];
      case "number": return Number.isFinite(value) && !Object.is(value, -0)
        ? ["value", value] : ["number", String(Object.is(value, -0) ? "-0" : value)];
      case "string": case "boolean": return ["value", value];
      case "object": {
        if (value === null) return ["value", null];
        let id = ids.get(value);
        if (id === undefined) {
          id = objects.length;
          ids.set(value, id);
          objects.push(value);
        }
        return ["ref", id];
      }
      default: throw Error("Unsupported native AST value: " + typeof value);
    }
  }
  const root = slot(native);
  yield '{"format":"bend-native-ast-v1","root":' + JSON.stringify(root) + ',"records":[';
  for (let i = 0; i < objects.length; i++) {
    // Object.keys has established that these are own string-keyed properties.
    const value = objects[i] as Properties, entries: [string, Slot][] = [], keys = Object.keys(value);
    validateConstructorFields(value, keys);
    for (const key of keys) entries.push([key, slot(value[key])]);
    if (i) yield ",";
    yield JSON.stringify([Array.isArray(value) ? "array" : "object", Array.isArray(value) ? value.length : 0, entries] satisfies Record);
  }
  yield "]}";
}

export function encodeNativeAst(native: unknown): string {
  return Array.from(nativeAstChunks(native)).join("");
}

/** Write the identical envelope without retaining a second records graph or
 * its complete JSON string beside the live native AST. */
export function writeNativeAst(path: string, native: unknown): {bytes: number; sha256: string} {
  const fd = openSync(path, "wx"), hash = createHash("sha256");
  let buffer = "", bytes = 0;
  const flush = () => {
    if (!buffer) return;
    writeFileSync(fd, buffer);
    hash.update(buffer);
    bytes += Buffer.byteLength(buffer);
    buffer = "";
  };
  try {
    for (const chunk of nativeAstChunks(native)) {
      buffer += chunk;
      if (buffer.length >= 65536) flush();
    }
    flush();
    return {bytes, sha256: hash.digest("hex")};
  } finally {
    closeSync(fd);
  }
}

function validateSlot(input: unknown, recordCount: number): asserts input is Slot {
  if (!Array.isArray(input)) throw Error("Invalid native AST transport slot");
  const [kind, payload] = input;
  if (kind === "undefined" && input.length === 1) return;
  if (input.length !== 2) throw Error("Invalid native AST transport slot");
  if (kind === "value" && (payload === null || typeof payload === "string" || typeof payload === "boolean"
    || typeof payload === "number" && Number.isFinite(payload))) return;
  if (kind === "ref" && typeof payload === "number" && Number.isSafeInteger(payload)
    && payload >= 0 && payload < recordCount) return;
  if (kind === "bigint" && typeof payload === "string" && /^-?\d+$/.test(payload)) return;
  if (kind === "number" && (payload === "-0" || payload === "NaN" || payload === "Infinity" || payload === "-Infinity")) return;
  throw Error("Invalid native AST transport slot");
}

function validateRecord(input: unknown, recordCount: number): asserts input is Record {
  if (!Array.isArray(input) || input.length !== 3 || (input[0] !== "object" && input[0] !== "array")
    || !Number.isSafeInteger(input[1]) || input[1] < 0 || input[1] > 0xffffffff || !Array.isArray(input[2]))
    throw Error("Invalid native AST transport record");
  for (const entry of input[2]) {
    if (!Array.isArray(entry) || entry.length !== 2 || typeof entry[0] !== "string") throw Error("Invalid native AST transport field");
    validateSlot(entry[1], recordCount);
  }
}

function slotValue(slot: Slot, objects: (NativeObject | NativeValue[])[], strings: Map<string, string>): NativeValue {
  switch (slot[0]) {
    case "ref": return objects[slot[1]];
    case "value": {
      const value = slot[1];
      if (typeof value !== "string") return value;
      const prior = strings.get(value);
      if (prior !== undefined) return prior;
      strings.set(value, value);
      return value;
    }
    case "bigint": return BigInt(slot[1]);
    case "undefined": return undefined;
    case "number": return Number(slot[1]);
  }
}

/** Validate the shallow JSON envelope in place: no duplicate records/slots tree.
 * Materialize references iteratively, releasing each consumed envelope record.
 * Sharing, cycles, field order and scalar transport semantics remain unchanged. */
export function decodeNativeAst(encoded: string): NativeValue {
  const parsed: unknown = JSON.parse(encoded);
  if (!parsed || typeof parsed !== "object" || !("format" in parsed) || parsed.format !== "bend-native-ast-v1"
    || !("records" in parsed) || !Array.isArray(parsed.records) || !("root" in parsed)) {
    throw Error("Invalid native AST transport envelope");
  }
  const recordInputs = parsed.records;
  validateSlot(parsed.root, recordInputs.length);
  const root = parsed.root;
  for (const input of recordInputs) validateRecord(input, recordInputs.length);
  // Every record, including unreachable ones, is validated before graph creation.
  const records = recordInputs as Record[];
  const strings = new Map<string, string>();
  const objects: (NativeObject | NativeValue[])[] = records.map(record => record[0] === "array" ? new Array<NativeValue>(record[1]) : {});
  for (let i = 0; i < objects.length; i++) {
    for (const [key, slot] of records[i][2]) {
      Object.defineProperty(objects[i], key, { value: slotValue(slot, objects, strings), writable: true, enumerable: true, configurable: true });
    }
    recordInputs[i] = undefined;
  }
  return slotValue(root, objects, strings);
}

/** Read the canonical envelope emitted by writeNativeAst, one shallow record
 * at a time. UTF-8 and quoted JSON strings may cross any file-buffer boundary. */
async function* fileRecords(path: string, header: (root: unknown) => void, bytes: (chunk: Buffer) => void): AsyncGenerator<Iterable<unknown>> {
  const decoder = new StringDecoder("utf8"), marker = ',"records":[', whitespace = /\s/;
  let prefix = "", carry = "", depth = 0, quoted = false, escaped = false, afterComma = false;
  let state: "prefix" | "record" | "separator" | "end" | "done" = "prefix";
  function* scan(input: string): Generator<unknown> {
    let text = input, start = 0;
    if (state === "prefix") {
      prefix += text;
      const at = prefix.indexOf(marker);
      if (at < 0) return;
      const parsed = JSON.parse(prefix.slice(0, at) + ',"records":[]}');
      if (parsed.format !== "bend-native-ast-v1" || !("root" in parsed)) throw Error("Invalid native AST transport envelope");
      header(parsed.root);
      text = prefix.slice(at + marker.length); prefix = ""; state = "record";
    }
    for (let i = 0; i < text.length; i++) {
      const ch = text[i];
      if (depth) {
        if (quoted) {
          if (escaped) escaped = false;
          else if (ch === "\\") escaped = true;
          else if (ch === '"') quoted = false;
        } else if (ch === '"') quoted = true;
        else if (ch === "[" || ch === "{") depth++;
        else if (ch === "]" || ch === "}") depth--;
        if (!depth) {
          const record = JSON.parse(carry + text.slice(start, i + 1));
          carry = ""; state = "separator"; yield record;
        }
        continue;
      }
      if (whitespace.test(ch)) continue;
      if (state === "record" && ch === "[") {
        start = i; depth = 1; quoted = false; escaped = false; afterComma = false;
      } else if ((state === "record" && !afterComma || state === "separator") && ch === "]") state = "end";
      else if (state === "separator" && ch === ",") { state = "record"; afterComma = true; }
      else if (state === "end" && ch === "}") state = "done";
      else throw Error("Invalid native AST transport envelope syntax");
    }
    if (depth) carry += text.slice(start);
  }
  // Await once per file chunk, not once per shallow record. Consumers drain
  // this synchronous iterator before requesting the next bounded chunk.
  for await (const chunk of createReadStream(path)) {
    const buffer = chunk as Buffer; bytes(buffer); yield scan(decoder.write(buffer));
  }
  yield scan(decoder.end());
  if (state !== "done" || depth || carry) throw Error("Incomplete native AST transport envelope");
}

/** Two bounded passes preserve all fields and forward references without a
 * co-resident parsed JSON envelope. Both passes must observe identical bytes. */
export async function readNativeAst(path: string): Promise<{value: NativeValue; sha256: string}> {
  const objects: (NativeObject | NativeValue[])[] = [], firstHash = createHash("sha256");
  const strings = new Map<string, string>();
  let root: unknown;
  for await (const records of fileRecords(path, value => { root = value; }, chunk => { firstHash.update(chunk); })) {
    for (const input of records) {
      validateRecord(input, Infinity);
      objects.push(input[0] === "array" ? new Array<NativeValue>(input[1]) : {});
    }
  }
  validateSlot(root, objects.length);
  const expected = firstHash.digest("hex"), secondHash = createHash("sha256");
  let index = 0;
  for await (const records of fileRecords(path, value => {
    validateSlot(value, objects.length);
    if (JSON.stringify(value) !== JSON.stringify(root)) throw Error("Native AST transport changed between passes");
  }, chunk => { secondHash.update(chunk); })) {
    for (const input of records) {
      validateRecord(input, objects.length);
      if (index >= objects.length || Array.isArray(objects[index]) !== (input[0] === "array")
        || input[0] === "array" && (objects[index] as NativeValue[]).length !== input[1])
        throw Error("Native AST transport changed between passes");
      for (const [key, slot] of input[2])
        Object.defineProperty(objects[index], key, {value: slotValue(slot, objects, strings), writable: true, enumerable: true, configurable: true});
      index++;
    }
  }
  if (index !== objects.length || secondHash.digest("hex") !== expected) throw Error("Native AST transport changed between passes");
  return {value: slotValue(root, objects, strings), sha256: expected};
}

/** Current-run transport arena: original record IDs, flat fields and interned
 * scalar strings. Semantic decoding consumes one original declaration at a time;
 * compiler inputs continue using the complete native decoder above. */
export class NativeAstArena {
  readonly root: number;
  private readonly recordKinds: Uint8Array;
  private readonly lengths: Uint32Array;
  private readonly offsets: Uint32Array;
  private readonly keys: Uint32Array;
  private readonly kinds: Uint8Array;
  private readonly payloads: Float64Array;
  private readonly strings: string[];
  constructor(root: number, recordKinds: Uint8Array, lengths: Uint32Array,
    offsets: Uint32Array, keys: Uint32Array, kinds: Uint8Array,
    payloads: Float64Array, strings: string[]) {
    this.root = root; this.recordKinds = recordKinds; this.lengths = lengths;
    this.offsets = offsets; this.keys = keys; this.kinds = kinds;
    this.payloads = payloads; this.strings = strings;
  }
  private record(cursor: number): number {
    if (this.kinds[cursor] !== 8) throw Error("Expected native AST record reference");
    return this.payloads[cursor];
  }
  private scalar(cursor: number): NativeValue {
    const payload = this.payloads[cursor];
    switch (this.kinds[cursor]) {
      case 0: return payload;
      case 1: return this.strings[payload];
      case 2: return false;
      case 3: return true;
      case 4: return null;
      case 5: return undefined;
      case 6: return BigInt(this.strings[payload]);
      default: throw Error("Expected native AST scalar");
    }
  }
  field(cursor: number, key: string): number {
    const record = this.record(cursor);
    // Object.defineProperty preserves the first key position but the last value.
    for (let i = this.offsets[record + 1] - 1; i >= this.offsets[record]; i--)
      if (this.strings[this.keys[i]] === key) return i;
    throw Error("Missing native AST field " + key);
  }
  tag(cursor: number): string {
    const value = this.scalar(this.field(cursor, "$"));
    if (typeof value !== "string") throw Error("Expected native AST constructor");
    return value.split(".").at(-1)!;
  }
  *list(cursor: number): Generator<number> {
    const seen = new Set<number>();
    for (;;) {
      const tag = this.tag(cursor);
      if (tag === "Nil") return;
      if (tag !== "Con") throw Error("Invalid native list");
      const record = this.record(cursor);
      if (seen.has(record)) throw Error("Cyclic native AST list");
      seen.add(record);
      yield this.field(cursor, "head");
      cursor = this.field(cursor, "tail");
    }
  }
  private arrayIndex(field: number): number {
    const key = this.strings[this.keys[field]], index = Number(key);
    return Number.isInteger(index) && index >= 0 && index < 0xffffffff && String(index) === key ? index : NaN;
  }
  private ownFields(record: number, skipTag = false): number[] {
    const fields: number[] = [];
    let numeric = false;
    for (let field = this.offsets[record]; field < this.offsets[record + 1]; field++) {
      if (skipTag && this.strings[this.keys[field]] === "$") continue;
      let prior = 0;
      while (prior < fields.length && this.keys[fields[prior]] !== this.keys[field]) prior++;
      if (prior === fields.length) fields.push(field); else fields[prior] = field;
      if (!Number.isNaN(this.arrayIndex(field))) numeric = true;
    }
    if (numeric) fields.sort((left, right) => {
      const a = this.arrayIndex(left), b = this.arrayIndex(right);
      return Number.isNaN(a) ? Number.isNaN(b) ? 0 : 1 : Number.isNaN(b) ? -1 : a - b;
    });
    return fields;
  }
  /** Decode only the requested declaration directly into semantic constructors
   * and flat argument/telescope vectors, never rebuilding intermediate Con cells. */
  semantic(cursor: number): Value {
    const root: Value[] = [], decoded = new Map<number, Value>();
    const tasks: {cursor: number; out: Value[]; index: number}[] = [{cursor, out: root, index: 0}];
    while (tasks.length) {
      const task = tasks.pop()!;
      if (this.kinds[task.cursor] !== 8) {
        const value = this.scalar(task.cursor);
        // Native scalar identity is part of transport: the release's Nat is a
        // number, while arbitrary BigInts remain BigInts, never rounded indexes.
        task.out[task.index] = value as Value;
        continue;
      }
      const record = this.record(task.cursor), prior = decoded.get(record);
      if (prior !== undefined) { task.out[task.index] = prior; continue; }
      const fields: Value[] = [];
      if (this.recordKinds[record]) {
        const own = this.ownFields(record);
        fields.length = this.lengths[record];
        decoded.set(record, fields); task.out[task.index] = fields;
        for (const field of own) {
          if (this.strings[this.keys[field]] === "length") throw Error("Invalid native AST array length property");
          const index = this.arrayIndex(field);
          if (!Number.isNaN(index)) {
            if (index >= fields.length) fields.length = index + 1;
            tasks.push({cursor: field, out: fields, index});
          }
        }
      } else {
        const tag = this.tag(task.cursor);
        if (tag === "Nil" || tag === "Con") {
          decoded.set(record, fields); task.out[task.index] = fields;
          let index = 0;
          for (const head of this.list(task.cursor)) tasks.push({cursor: head, out: fields, index: index++});
          fields.length = index;
        } else {
          const value: Node = {tag, fields};
          decoded.set(record, value); task.out[task.index] = value;
          const own = this.ownFields(record, true);
          fields.length = own.length;
          for (let index = own.length - 1; index >= 0; index--) tasks.push({cursor: own[index], out: fields, index});
        }
      }
    }
    return root[0];
  }
}

/** Authenticate both complete byte passes; retain no native object per record.
 * All fields, including unreachable records, undergo the same slot validation. */
export async function readNativeAstArena(path: string): Promise<{arena: NativeAstArena; sha256: string}> {
  const firstHash = createHash("sha256");
  let root: unknown, recordsCount = 0, fieldsCount = 0;
  for await (const records of fileRecords(path, value => { root = value; }, chunk => { firstHash.update(chunk); })) {
    for (const input of records) {
      validateRecord(input, Infinity);
      recordsCount++; fieldsCount += input[2].length;
      if (recordsCount >= 0xffffffff || fieldsCount >= 0xffffffff) throw Error("Native AST arena exceeds 32-bit addressing");
    }
  }
  validateSlot(root, recordsCount);
  const expected = firstHash.digest("hex"), secondHash = createHash("sha256");
  const recordKinds = new Uint8Array(recordsCount), lengths = new Uint32Array(recordsCount);
  const offsets = new Uint32Array(recordsCount + 1), keys = new Uint32Array(fieldsCount + 1);
  const kinds = new Uint8Array(fieldsCount + 1), payloads = new Float64Array(fieldsCount + 1);
  const strings: string[] = [], stringIds = new Map<string, number>();
  const intern = (value: string): number => {
    let id = stringIds.get(value);
    if (id === undefined) { id = strings.length; stringIds.set(value, id); strings.push(value); }
    return id;
  };
  const store = (index: number, slot: Slot) => {
    switch (slot[0]) {
      case "ref": kinds[index] = 8; payloads[index] = slot[1]; break;
      case "bigint": kinds[index] = 6; payloads[index] = intern(slot[1]); break;
      case "undefined": kinds[index] = 5; break;
      case "number": payloads[index] = Number(slot[1]); break;
      case "value":
        if (typeof slot[1] === "string") { kinds[index] = 1; payloads[index] = intern(slot[1]); }
        else if (slot[1] === false) kinds[index] = 2;
        else if (slot[1] === true) kinds[index] = 3;
        else if (slot[1] === null) kinds[index] = 4;
        else payloads[index] = slot[1];
    }
  };
  let record = 0, field = 0;
  for await (const records of fileRecords(path, value => {
    validateSlot(value, recordsCount);
    if (JSON.stringify(value) !== JSON.stringify(root)) throw Error("Native AST transport changed between passes");
  }, chunk => { secondHash.update(chunk); })) {
    for (const input of records) {
      validateRecord(input, recordsCount);
      if (record >= recordsCount || field + input[2].length > fieldsCount) throw Error("Native AST transport changed between passes");
      recordKinds[record] = input[0] === "array" ? 1 : 0;
      lengths[record] = input[1]; offsets[record] = field;
      for (const [key, slot] of input[2]) { keys[field] = intern(key); store(field++, slot); }
      record++;
    }
  }
  if (record !== recordsCount || field !== fieldsCount || secondHash.digest("hex") !== expected)
    throw Error("Native AST transport changed between passes");
  offsets[recordsCount] = fieldsCount; store(fieldsCount, root);
  return {arena: new NativeAstArena(fieldsCount, recordKinds, lengths, offsets, keys, kinds, payloads, strings), sha256: expected};
}

/** Decode constructors/lists without recursion or scalar coercion. Native Nat
 * indexes are checked by their consumers, never narrowed by graph transport. */
export function nativeAstValue(native: unknown): Value {
  const root: Value[] = [];
  type Task = { native: unknown; out: Value[]; index: number };
  const tasks: Task[] = [{ native, out: root, index: 0 }];
  const decoded = new Map<object, Value>();
  while (tasks.length) {
    const task = tasks.pop()!, value = task.native;
    if (value === null || typeof value !== "object") {
      task.out[task.index] = value as Value;
    } else if (decoded.has(value)) {
      task.out[task.index] = decoded.get(value)!;
    } else {
      const fields: Value[] = [];
      if (Array.isArray(value)) {
        fields.length = value.length;
        decoded.set(value, fields); task.out[task.index] = fields;
        for (let i = value.length - 1; i >= 0; i--) {
          if (i in value) tasks.push({ native: value[i], out: fields, index: i });
        }
      } else {
        // The constructor check below validates the discriminant; its complete
        // enumerable payload is decoded rather than projected to a schema.
        const ctor = value as Properties;
        if (typeof ctor.$ !== "string") throw Error("Expected native AST constructor");
        const tag = ctor.$.split(".").at(-1)!;
        if (tag === "Nil" || tag === "Con") {
          decoded.set(value, fields); task.out[task.index] = fields;
          const seen = new Set<object>();
          let cell: unknown = value, i = 0;
          while (cell && typeof cell === "object") {
            const item = cell as Properties;
            if (typeof item.$ !== "string" || item.$.split(".").at(-1) !== "Con") break;
            validateConstructorFields(item, Object.keys(item));
            if (seen.has(cell)) throw Error("Cyclic native AST list");
            seen.add(cell);
            tasks.push({ native: item.head, out: fields, index: i++ });
            cell = item.tail;
          }
          if (!cell || typeof cell !== "object" || !("$" in cell) || typeof cell.$ !== "string"
            || cell.$.split(".").at(-1) !== "Nil") throw Error("Invalid native list");
          validateConstructorFields(cell as Properties, Object.keys(cell));
          fields.length = i;
        } else {
          const result: Node = { tag, fields };
          decoded.set(value, result); task.out[task.index] = result;
          const keys = Object.keys(value).filter(key => key !== "$");
          validateConstructorFields(ctor, keys);
          fields.length = keys.length;
          for (let i = keys.length - 1; i >= 0; i--) tasks.push({ native: ctor[keys[i]], out: fields, index: i });
        }
      }
    }
  }
  return root[0];
}

/** Exactly the JSON.stringify text, emitted in bounded chunks using
 * an explicit depth-first cursor. Only primitive strings are JSON-stringified.
 * JSON's omissions, key order, toJSON, boxed primitives and cycle errors apply. */
export function writeSemanticJSON(value: unknown, consume: (text: string) => void): void {
  let buffer = "";
  function emit(text: string) {
    buffer += text;
    if (buffer.length >= 65536) { consume(buffer); buffer = ""; }
  }
  function prepare(value: unknown, key: string): unknown {
    if (value !== null && (typeof value === "object" || typeof value === "function" || typeof value === "bigint")) {
      // JSON invokes toJSON before unboxing, including for callable objects.
      const withJSON = value as { toJSON?: unknown };
      const toJSON = withJSON.toJSON;
      if (typeof toJSON === "function") value = toJSON.call(value, key);
    }
    if (types.isNumberObject(value)) value = Number(value);
    else if (types.isStringObject(value)) value = String(value);
    else if (types.isBooleanObject(value)) value = Boolean.prototype.valueOf.call(value);
    else if (types.isBigIntObject(value)) value = BigInt.prototype.valueOf.call(value);
    if (typeof value === "bigint") throw TypeError("Do not know how to serialize a BigInt");
    return value;
  }
  const omitted = (value: unknown) => value === undefined || typeof value === "function" || typeof value === "symbol";
  type Frame = { value: Properties; keys: string[] | null; index: number; length: number; emitted: boolean };
  const frames: Frame[] = [], active = new Set<object>();
  // The raw JSON brand is optional on older supported Node/Bun runtimes.
  const json = JSON as typeof JSON & { isRawJSON?: (value: unknown) => boolean };
  function start(value: unknown) {
    if (value === null) emit("null");
    else if (typeof value === "string") emit(JSON.stringify(value));
    else if (typeof value === "number") emit(Number.isFinite(value) ? String(value === 0 ? 0 : value) : "null");
    else if (typeof value === "boolean") emit(value ? "true" : "false");
    else if (typeof value === "object" && value !== null) {
      if (json.isRawJSON?.(value)) {
        const raw = value as { rawJSON: string };
        emit(raw.rawJSON); return;
      }
      if (active.has(value)) throw TypeError("Converting circular structure to JSON");
      active.add(value);
      const keys = Array.isArray(value) ? null : Object.keys(value);
      // Cursor access uses the keys/length established for this JSON container.
      const properties = value as Properties;
      frames.push({ value: properties, keys, index: 0, length: Array.isArray(value) ? value.length : keys!.length, emitted: false });
      emit(keys === null ? "[" : "{");
    }
    else throw TypeError("Unsupported JSON value");
  }
  const root = prepare(value, "");
  if (omitted(root)) throw TypeError("Semantic hash requires a JSON-serializable root");
  start(root);
  while (frames.length) {
    const frame = frames[frames.length - 1];
    if (frame.index === frame.length) {
      emit(frame.keys === null ? "]" : "}"); active.delete(frame.value); frames.pop(); continue;
    }
    const key = frame.keys === null ? String(frame.index++) : frame.keys[frame.index++];
    const child = prepare(frame.value[key], key);
    if (frame.keys !== null && omitted(child)) continue;
    if (frame.emitted) emit(",");
    frame.emitted = true;
    if (frame.keys !== null) { emit(JSON.stringify(key)); emit(":"); }
    start(omitted(child) ? null : child);
  }
  if (buffer) consume(buffer);
}

export function semanticHash(value: unknown): string {
  const hash = createHash("sha256");
  writeSemanticJSON(value, text => { hash.update(text); });
  return hash.digest("hex");
}
