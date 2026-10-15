/** Render real pre-flatten source bodies without relying on declaration names.
 * Binder IDs select references; printed names and dense printer indices are
 * assigned only at the source boundary. Input ASTs are never mutated.
 */
import { patt_term, quant_show, term_show, type Body, type Book, type LTerm, type Patt } from "../bend2/bend.ts";
import type { ParserParameter } from "./parser_full_graph.ts";
import type { Binding, LexicalTypes } from "./parser_full_type_env.ts";

type PrintedBinding = Readonly<{ name: string; index: number; value?: { term: LTerm; scope: Scope } }>;
type Scope = ReadonlyMap<number, PrintedBinding>;

export type BodyRenderContext = Readonly<{
  binderMap: ReadonlyMap<number, string>;
  renderTerm: (term: LTerm, extraBindings?: ReadonlyMap<number, string>) => string;
  environment?: ReadonlyMap<number, Binding>;
}>;
export type BodyRenderOptions = Readonly<{
  /** Return the terminal expression (possibly multiline), not its indentation. */
  emitTerminal?: (term: LTerm, context: BodyRenderContext) => string;
  /** Receives an alpha-renamed, private AST, safe for alias remapping. */
  showTerm?: (term: LTerm, boundNames: string[], precedence: number) => string;
  types?: Pick<LexicalTypes, "environmentAt">;
  /** Reserve constructor/global names, including declarations unused in this body. */
  book?: Book;
  indent?: string;
}>;
export type RenderedBody = Readonly<{
  body: string;
  parameters: string;
  binderMap: ReadonlyMap<number, string>;
  /** Source binder identities to their declaration-wide printable names. */
  printedBinders: ReadonlyMap<number, string>;
  /** Render in the helper parameter scope. Terminal hooks get their local scope. */
  renderTerm: (term: LTerm, extraBindings?: ReadonlyMap<number, string>) => string;
}>;

/** IDs need not be dense, consecutive, or tied to their original source names. */
export function renderBody(body: Body, parameters: readonly ParserParameter[], options: BodyRenderOptions = {}): RenderedBody {
  const indent = options.indent ?? "  ";
  const show = options.showTerm ?? ((term: LTerm, names: string[], precedence: number) => term_show(term, precedence, names));
  const generated = new Map<number, string>();
  const reserved = new Set([...Object.keys(options.book?.tlds ?? {}), ...Object.keys(options.book?.ctrs ?? {})]);
  const nameOf = (id: number, original: string): string => {
    if (original === "_") return "_";
    const existing = generated.get(id);
    if (existing) return existing;
    let name = `v_${id < 0 ? "neg_" + -id : id}`;
    while (reserved.has(name)) name += "_";
    generated.set(id, name); reserved.add(name);
    return name;
  };
  function bind(scope: Scope, names: readonly string[], id: number, original: string): [Scope, string[]] {
    const name = nameOf(id, original);
    const inner = new Map(scope); inner.set(id, { name, index: names.length });
    return [inner, [...names, name]];
  }
  function alpha(term: LTerm, scope: Scope, names: readonly string[]): LTerm {
    switch (term.$) {
      case "Var": {
        const binding = scope.get(term.i);
        if (!binding) throw Error(`Cannot render unbound source binder ${term.i} (${term.k})`);
        return binding.value ? alpha(binding.value.term, binding.value.scope, names)
          : { $: "Var", k: binding.name, i: binding.index, s: term.s };
      }
      case "Lam": {
        const [inner, bound] = bind(scope, names, term.i, term.k);
        return { ...term, ...(term.q ? { q: { ...term.q } } : {}), k: bound[bound.length - 1]!, i: names.length, f: alpha(term.f, inner, bound) };
      }
      case "All": {
        const A = alpha(term.A, scope, names);
        const [inner, bound] = bind(scope, names, term.i, term.k);
        return { ...term, q: { ...term.q }, k: bound[bound.length - 1]!, i: names.length, A, B: alpha(term.B, inner, bound) };
      }
      case "Let": {
        const values = term.v.map(value => alpha(value, scope, names));
        let inner = scope, bound = [...names];
        for (let i = 0; i < term.i.length; i++) [inner, bound] = bind(inner, bound, term.i[i]!, term.k[i]!);
        return { ...term, k: bound.slice(names.length), i: term.i.map((_, i) => names.length + i),
          q: term.q.map(quantity => ({ ...quantity })), v: values, f: alpha(term.f, inner, bound) };
      }
      case "Sub": {
        // Sub is an alias, not a printed declaration. Resolve it before printing:
        // term_show intentionally elides this node and would otherwise lose its RHS.
        const value = patt_term(term.v);
        const inner = new Map(scope); inner.set(term.i, { name: "", index: -1, value: { term: value, scope } });
        return alpha(term.f, inner, names);
      }
      case "Typ": return { ...term, g: alpha(term.g, scope, names) };
      case "Min": return { ...term, a: alpha(term.a, scope, names), b: alpha(term.b, scope, names) };
      case "App": return { ...term, f: alpha(term.f, scope, names), x: alpha(term.x, scope, names) };
      case "ADT": return { ...term, x: term.x.map(value => alpha(value, scope, names)), r: [...term.r] };
      case "Ctr": return { ...term, x: term.x.map(value => alpha(value, scope, names)) };
      case "Mat": return { ...term, h: alpha(term.h, scope, names), m: alpha(term.m, scope, names) };
      case "Eql": return { ...term, a: alpha(term.a, scope, names), b: alpha(term.b, scope, names), T: alpha(term.T, scope, names) };
      case "Rwt": return { ...term, e: alpha(term.e, scope, names), p: alpha(term.p, scope, names), f: alpha(term.f, scope, names) };
      case "Ann": return { ...term, x: alpha(term.x, scope, names), T: alpha(term.T, scope, names) };
      case "Qua": return { ...term, q: { ...term.q } };
      case "Ref": case "Lit": case "Qnt": case "Efq": case "Rfl": case "Hol": return { ...term };
      default: return unreachable(term);
    }
  }
  function renderTerm(term: LTerm, scope: Scope, names: readonly string[], precedence = -1): string {
    return show(alpha(term, scope, names), [...names], precedence);
  }
  function renderExtended(term: LTerm, scope: Scope, names: readonly string[], extraBindings?: ReadonlyMap<number, string>): string {
    if (!extraBindings?.size) return renderTerm(term, scope, names);
    const inner = new Map(scope), bound = [...names];
    for (const [id, name] of extraBindings) {
      const existing = inner.get(id);
      if (existing) {
        if (existing.name !== name) throw Error(`Cannot rename existing source binder ${id}`);
        continue;
      }
      if (bound.includes(name)) throw Error(`Synthetic binder ${id} shadows printed name ${name}`);
      inner.set(id, { name, index: bound.length }); bound.push(name);
    }
    return renderTerm(term, inner, bound);
  }
  function binderMap(scope: Scope): ReadonlyMap<number, string> {
    return new Map([...scope].filter(([, binding]) => !binding.value).map(([id, binding]) => [id, binding.name]));
  }
  function patterns(patterns: readonly Patt[], scope: Scope, names: readonly string[]): { text: string[]; scope: Scope; names: string[] } {
    let inner = scope, bound = [...names];
    const printNames: string[] = [];
    function visit(pattern: Patt, successorTail = false): LTerm {
      if (pattern.$ === "PCtr") return { $: "Ctr", k: pattern.k,
        x: pattern.x.map((child, index) => visit(child, pattern.k === "Succ" && index === 0)), s: pattern.s };
      const name = nameOf(pattern.i, pattern.k);
      [inner, bound] = bind(inner, bound, pattern.i, pattern.k);
      // Quantity markings belong to the pattern spelling, not its bound name.
      // Keep the successor '+' and a quantity marker as separate tokens.
      const marked = (successorTail && pattern.q.$ !== "Lone" ? " " : "")
        + quant_show(pattern.q) + name;
      let index = printNames.indexOf(marked);
      if (index < 0) { index = printNames.length; printNames.push(marked); }
      return { $: "Var", k: marked, i: index, s: pattern.s };
    }
    const terms = patterns.map(pattern => visit(pattern));
    return { text: terms.map(term => show(term, [...printNames], -1)), scope: inner, names: bound };
  }
  function visit(node: Body, scope: Scope, names: readonly string[], prefix: string): string {
    switch (node.$) {
      case "Local": {
        const values = node.v.map(value => renderTerm(value, scope, names, 1));
        const bound = patterns(node.k, scope, names);
        const erased = node.q.$ === "None" ? "-" : "";
        return prefix + erased + bound.text.join(" ") + " = " + values.join(" ") + "\n"
          + visit(node.f, bound.scope, bound.names, prefix);
      }
      case "Match": {
        const scrutinees = node.e.map(value => renderTerm(value, scope, names));
        const rows = node.r.map(row => {
          const bound = patterns(row.p, scope, names);
          return prefix + indent + "case " + bound.text.join(", ") + ":\n"
            + visit(row.f, bound.scope, bound.names, prefix + indent + indent);
        });
        return prefix + "match " + scrutinees.join(", ") + ":\n" + rows.join("\n");
      }
      default: {
        const context: BodyRenderContext = {
          binderMap: binderMap(scope), renderTerm: (term, extraBindings) => renderExtended(term, scope, names, extraBindings),
          ...(options.types ? { environment: options.types.environmentAt(node) } : {}),
        };
        const expression = options.emitTerminal ? options.emitTerminal(node, context) : context.renderTerm(node);
        return expression.split("\n").map(line => prefix + line).join("\n");
      }
    }
  }
  let scope: Scope = new Map(), names: string[] = [];
  const declarations: string[] = [];
  for (const [quantity, original, id, type] of parameters) {
    const domain = renderTerm(type, scope, names);
    [scope, names] = bind(scope, names, id, original);
    declarations.push(quant_show(quantity) + names[names.length - 1]! + ": " + domain);
  }
  return { body: visit(body, scope, names, indent), parameters: declarations.join(", "),
    binderMap: binderMap(scope), printedBinders:generated, renderTerm: (term, extraBindings) => renderExtended(term, scope, names, extraBindings) };
}
function unreachable(node: never): never { throw Error(`Unsupported source AST ${(node as Body | LTerm).$}`); }
