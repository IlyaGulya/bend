#!/usr/bin/env python3
"""Counterfactual edge (and gateway-vertex) cuts for f640d749 parser.bend.

Run `python3 evals/parser_feedback_edges.py [--sites] [--json]`. The only
input is the parser at the pinned commit, read with git show. Calls are lexical
name(...) references in function bodies, excluding strings/comments and names
qualified with a dot. This is a planning estimate, not a Bend type checker.
Every selected *directed edge* means converting ALL of its listed callsites;
ordinary uncut helpers may remain reachable, provided their graph is acyclic.
"""

import argparse
from collections import Counter, defaultdict
from dataclasses import dataclass
import json
from pathlib import Path
import random
import re
import subprocess


REVISION = "f640d749"
PARSER = "bend2/selfhost/parser.bend"
ROOT = Path(__file__).resolve().parents[1]
DEF = re.compile(r"^def ([A-Za-z_]\w*)\(")
CALL = re.compile(r"(?<![.\w])([A-Za-z_]\w*)\s*\(")


@dataclass(frozen=True)
class Site:
    caller: str
    callee: str
    line: int
    column: int
    context: str
    source: str

    @property
    def cost(self):
        # Calls used as arguments need an explicit continuation/state frame.
        # Units are heuristic rewrite effort, not elapsed time.
        return 1 + 2 * (self.context == "nested-argument")


def unquoted(line):
    """Mask quoted strings/comments while preserving offsets for callsite columns."""
    out = []
    quote = None
    escaped = False
    for ch in line:
        if quote:
            out.append(" ")
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
        elif ch in ("'", '"'):
            quote = ch
            out.append(" ")
        elif ch == "#":
            break
        else:
            out.append(ch)
    return "".join(out)


def site_context(text, offset):
    """Distinguish outer arguments from tail expressions inside lambdas."""
    clean = unquoted(text)
    prefix = clean[:offset]
    match = CALL.match(clean, offset)
    if match is None:
        raise ValueError(f"expected call at column {offset + 1}: {text}")
    depth = 0
    close = None
    for pos in range(match.end() - 1, len(clean)):
        if clean[pos] == "(":
            depth += 1
        elif clean[pos] == ")":
            depth -= 1
            if depth == 0:
                close = pos
                break
    if close is None:
        raise ValueError(f"unclosed call at column {offset + 1}: {text}")
    suffix = clean[close + 1:]
    # An arrow before this call starts a lambda body: its expression is not
    # evaluated as the enclosing combinator's argument call.
    if re.search(r"=>\s*$", prefix) and re.fullmatch(r"\)*\s*", suffix):
        return "lambda-tail"
    stack = []
    for pos, char in enumerate(prefix):
        if char == "(":
            before = prefix[:pos]
            stack.append(bool(re.search(r"(?<![.\w])[A-Za-z_]\w*\s*$", before)))
        elif char == ")" and stack:
            stack.pop()
    if any(stack):
        return "nested-argument"
    if re.search(r"\b[A-Za-z_]\w*\s*=\s*$", prefix):
        return "assignment"
    if not prefix.strip() and not suffix.strip():
        return "branch-tail"
    return "unclassified"


def extract(source):
    lines = source.splitlines()
    definitions = {}
    for n, line in enumerate(lines, 1):
        match = DEF.match(line)
        if match:
            if match[1] in definitions:
                raise ValueError(f"duplicate definition {match[1]} at {n}")
            definitions[match[1]] = line
    sites = []
    owner = None
    for n, line in enumerate(lines, 1):
        match = DEF.match(line)
        if match:
            owner = match[1]
        elif line and not line[0].isspace() and not line.startswith("#"):
            owner = None
        elif owner is not None and line.startswith((" ", "\t")):
            for call in CALL.finditer(unquoted(line)):
                if call[1] in definitions:
                    sites.append(Site(owner, call[1], n, call.start() + 1,
                                      site_context(line, call.start()), line.strip()))
    edges = {name: set() for name in definitions}
    by_edge = defaultdict(list)
    for site in sites:
        edges[site.caller].add(site.callee)
        by_edge[site.caller, site.callee].append(site)
    return definitions, sites, edges, by_edge


def sccs(nodes, edges):
    index = 0
    seen = {}
    low = {}
    stack = []
    active = set()
    groups = []

    def visit(node):
        nonlocal index
        seen[node] = low[node] = index
        index += 1
        active.add(node)
        stack.append(node)
        for nxt in sorted(edges[node]):
            if nxt not in seen:
                visit(nxt)
                low[node] = min(low[node], low[nxt])
            elif nxt in active:
                low[node] = min(low[node], seen[nxt])
        if low[node] == seen[node]:
            group = set()
            while True:
                nxt = stack.pop()
                active.remove(nxt)
                group.add(nxt)
                if nxt == node:
                    break
            groups.append(group)

    for node in sorted(nodes):
        if node not in seen:
            visit(node)
    return groups


def family(signature):
    """Retain full return shape; term/list-of-terms and line-bearing lists differ."""
    result = re.sub(r"\s+", "", signature.rsplit(" -> ", 1)[-1].removesuffix(":"))
    readable = {
        "(Ast.SyntaxTerm&List<&2,Lexer.Token>)&Bool": "term+tokens+bool",
        "(List<&2,Ast.SyntaxTerm>&List<&2,Lexer.Token>)&Bool": "terms+tokens+bool",
        "((List<&2,Ast.SyntaxTerm>&List<&2,Lexer.Token>)&Nat)&Bool": "terms+tokens+nat+bool",
    }
    return readable.get(result, result)


def candidate_metrics(cuts, by_edge, definitions, core, sites):
    cut_sites = [site for edge in sorted(cuts) for site in by_edge[edge]]
    targets = {dst for _, dst in cuts}
    external = [site for site in sites if site.caller not in core and site.callee in targets]
    return {
        "cut_edges": len(cuts),
        "cut_callsites": len(cut_sites),
        "weighted_site_units": sum(site.cost for site in cut_sites),
        "proven_nested_argument_sites": sum(site.context == "nested-argument" for site in cut_sites),
        "source_visible_tail_sites": sum(site.context in ("branch-tail", "lambda-tail") for site in cut_sites),
        "assignment_sites": sum(site.context == "assignment" for site in cut_sites),
        "unclassified_sites": sum(site.context == "unclassified" for site in cut_sites),
        "target_nodes": len(targets),
        "target_result_families": dict(sorted(Counter(family(definitions[node]) for node in targets).items())),
        "external_entry_callsites_into_targets": len(external),
        "external_entry_distinct_callers": len({site.caller for site in external}),
        "caller_callee_context_variants": len({(s.caller, s.callee, s.context) for s in cut_sites}),
    }

def workload(cuts, by_edge, definitions, external):
    """Heuristic rewrite units, counting shared gateway setup only once."""
    targets = {dst for _, dst in cuts}
    contexts = {(edge, site.context) for edge in cuts for site in by_edge[edge]}
    return (sum(site.cost for edge in cuts for site in by_edge[edge])
            + len(contexts)
            + 2 * len(targets)
            + 3 * len({family(definitions[node]) for node in targets})
            + sum(external[node] for node in targets))




def order_cut(order, core_edges):
    rank = {node: i for i, node in enumerate(order)}
    return {(src, dst) for src in order for dst in core_edges[src]
            if rank[src] >= rank[dst]}


def weighted_order(core, edges, weights, score, rng):
    """Weighted sink/source peeling, then locally improve insert positions."""
    remaining = set(core)
    left, right = [], []
    while remaining:
        incoming = {n: sum(weights[p, n] for p in remaining if n in edges[p])
                    for n in remaining}
        outgoing = {n: sum(weights[n, t] for t in edges[n] if t in remaining)
                    for n in remaining}
        sinks = [n for n in remaining if not outgoing[n]]
        sources = [n for n in remaining if not incoming[n]]
        if sinks:
            chosen = rng.choice(sorted(sinks))
            right.append(chosen)
        elif sources:
            chosen = rng.choice(sorted(sources))
            left.append(chosen)
        else:
            best = max(outgoing[n] - incoming[n] for n in remaining)
            chosen = rng.choice(sorted(n for n in remaining
                                       if outgoing[n] - incoming[n] == best))
            left.append(chosen)
        remaining.remove(chosen)
    order = left + list(reversed(right))
    # Inserting one node only changes edges incident to it. Deterministic
    # ascending-index tie break; stop when no strict improvement remains.
    for _ in range(8):
        improved = False
        for node in list(order):
            current = order_cut(order, edges)
            incident = {(src, dst) for src, dst in current if src == node or dst == node}
            other = current - incident
            rest = [n for n in order if n != node]
            rank = {n: i for i, n in enumerate(rest)}
            neighbors = {dst for dst in edges[node] if dst != node}
            neighbors.update(src for src in rest if node in edges[src])
            positions = {0, len(rest)}
            for neighbor in neighbors:
                positions.update((rank[neighbor], rank[neighbor] + 1))
            old = score(current)
            best_cost, best_position = old, None
            for position in sorted(positions):
                moved = set(other)
                if node in edges[node]:
                    moved.add((node, node))
                moved.update((node, dst) for dst in edges[node]
                             if dst != node and position > rank[dst])
                moved.update((src, node) for src in rest
                             if node in edges[src] and rank[src] >= position)
                cost = score(moved)
                if cost < best_cost:
                    best_cost, best_position = cost, position
            if best_position is not None:
                order = rest[:best_position] + [node] + rest[best_position:]
                improved = True
        if not improved:
            break
    return order


def gateway_greedy(core, edges, by_edge, sites, definitions):
    """Independent vertex baseline: remove incoming edges into chosen nodes."""
    external = Counter(site.callee for site in sites if site.caller not in core)
    selected = set()
    while True:
        residual = {node: edges[node] - selected for node in core}
        cyclic = [group for group in sccs(core, residual) if len(group) > 1
                  or any(node in residual[node] for node in group)]
        if not cyclic:
            break
        allowed = set().union(*cyclic)
        # Benefit is SCC-internal incoming edges; cost includes all internal
        # callsites, nested argument context, distinct caller/Kont shapes, and
        # external entry sites into the selected gateway.
        score = lambda n: ((sum(sum(site.cost for site in by_edge[p, n]) + 1
                                 for p in core if n in edges[p])
                             + 2 + 2 * external[n] + (family(definitions[n]) != "SyntaxTerm")) /
                            max(1, sum(n in residual[p] for p in core if p in allowed)))
        selected.add(min(sorted(allowed), key=score))
    cut = {(src, dst) for src in core for dst in edges[src] if dst in selected}
    return sorted(selected), cut


def run():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sites", action="store_true", help="print every selected cut callsite")
    parser.add_argument("--json", action="store_true", help="emit full machine-readable candidate and site data")
    args = parser.parse_args()
    source = subprocess.check_output(["git", "show", f"{REVISION}:{PARSER}"], cwd=ROOT).decode()
    definitions, sites, edges, by_edge = extract(source)
    core = next(group for group in sccs(definitions, edges) if "parse_term" in group)
    internal = {node: edges[node] & core for node in core}
    internal_edges = {(node, dst) for node in core for dst in internal[node]}
    internal_sites = sum(len(by_edge[edge]) for edge in internal_edges)
    assert (len(core), len(internal_edges), internal_sites,
            sum(src == dst for src, dst in internal_edges)) == (161, 262, 301, 1), \
        "unexpected immutable parser graph: inspect extractor/commit"
    external = Counter(site.callee for site in sites if site.caller not in core)
    weights = {edge: sum(site.cost for site in by_edge[edge])
               + len({site.context for site in by_edge[edge]})
               + 2 + external[edge[1]] for edge in internal_edges}
    score = lambda cut: workload(cut, by_edge, definitions, external)
    # Reproducible weighted greedy order restarts and insertion improvement.
    variants = []
    for seed in range(12):
        order = weighted_order(core, internal, weights, score, random.Random(seed))
        cut = order_cut(order, internal)
        variants.append((score(cut), len(cut), seed, cut, order))
    variants.sort(key=lambda item: (item[0], item[1], item[2]))
    primary = variants[0]
    others = [item for item in variants[1:] if item[3] != primary[3]]
    alternative = min(others, key=lambda item: (len(item[3]), item[0], item[2])) if others else None
    # Shadow alternative: keep local-values entry helpers ordinary and cut
    # another edge of that small cycle. Penalty is a search constraint only;
    # reported workload below always uses the same unpenalized cost model.
    shadow_targets = {"parse_local_values", "parse_local_values_same_line"}
    shadow_score = lambda cut: score(cut) + 100 * len(
        shadow_targets & {dst for _, dst in cut})
    shadow_weights = {edge: weight + (100 if edge[1] in shadow_targets else 0)
                      for edge, weight in weights.items()}
    shadow_variants = []
    for seed in range(6):
        order = weighted_order(core, internal, shadow_weights, shadow_score, random.Random(seed))
        cut = order_cut(order, internal)
        if cut not in (primary[3], alternative[3] if alternative else set()):
            shadow_variants.append((shadow_score(cut), len(cut), seed, cut, order))
    shadow = min(shadow_variants) if shadow_variants else None
    gateway_nodes, gateway_cut = gateway_greedy(core, internal, by_edge, sites, definitions)
    gateway_residual = {node: internal[node] - {dst for src, dst in gateway_cut if src == node}
                        for node in core}
    assert max(map(len, sccs(core, gateway_residual))) == 1
    assert not any(node in gateway_residual[node] for node in core)
    baseline = {"gateway_nodes": gateway_nodes,
                "gateway_internal_incoming": candidate_metrics(gateway_cut, by_edge, definitions, core, sites),
                "weighted_workload_units": score(gateway_cut)}
    candidates = []
    for name, variant in (("weighted-order", primary), ("few-edges-order", alternative),
                          ("local-values-shadow", shadow)):
        if variant is None:
            continue
        _, _, seed, cut, order = variant
        residual = {node: internal[node] - {dst for src, dst in cut if src == node} for node in core}
        components = sccs(core, residual)
        assert max(map(len, components)) == 1 and not any(node in residual[node] for node in core)
        candidates.append({"name": name, "seed": seed, "metrics": candidate_metrics(
            cut, by_edge, definitions, core, sites), "weighted_workload_units": score(cut),
            "target_nodes": sorted({dst for _, dst in cut}),
            "residual_largest_scc": 1,
            "residual_self_edges": 0,
            "topological_order": order,
            "edges": [{"caller": src, "callee": dst,
                       "callsites": [{"line": site.line, "column": site.column,
                                      "context": site.context, "source": site.source}
                                     for site in by_edge[src, dst]]}
                      for src, dst in sorted(cut)]})
    report = {"revision": REVISION,
              "graph": {"main_scc_nodes": len(core), "internal_edges": len(internal_edges),
                        "internal_callsites": internal_sites},
              "cost_model": "1/site + 2/proven nested named-call argument + 1/distinct edge-context + 2/target + 3/result family + 1/external-entry site; tail labels require whole-expression source evidence",
              "gateway_comparison": baseline, "candidates": candidates}
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"{REVISION}: SCC {len(core)} nodes, {len(internal_edges)} internal edges, "
              f"{internal_sites} internal callsites")
        print(f"independently derived gateway-vertex baseline: {len(gateway_nodes)} nodes, "
              f"{baseline['gateway_internal_incoming']['cut_callsites']} internal incoming sites, "
              f"{baseline['weighted_workload_units']} weighted workload units "
              f"(full names in --json)")
        for candidate in candidates:
            metric = candidate["metrics"]
            print(f"{candidate['name']} seed={candidate['seed']}: "
                  f"{metric['cut_edges']} edges, {metric['cut_callsites']} sites, "
                  f"{candidate['weighted_workload_units']} workload units "
                  f"({metric['weighted_site_units']} site units), "
                  f"{metric['proven_nested_argument_sites']} proven nested, "
                  f"{metric['source_visible_tail_sites']} source-visible tail, "
                  f"{metric['external_entry_callsites_into_targets']} external entry sites into "
                  f"{metric['target_nodes']} targets, result families="
                  f"{metric['target_result_families']}, residual SCC="
                  f"{candidate['residual_largest_scc']}")
            for edge in candidate["edges"]:
                print(f"  {edge['caller']} -> {edge['callee']} @"
                      f"{','.join(str(site['line']) + ':' + str(site['column']) for site in edge['callsites'])}")
            if args.sites:
                for edge in candidate["edges"]:
                    for site in edge["callsites"]:
                        print(f"  {edge['caller']} -> {edge['callee']} "
                              f"{PARSER}:{site['line']}:{site['column']} "
                              f"[{site['context']}] {site['source']}")
    return report


if __name__ == "__main__":
    run()
