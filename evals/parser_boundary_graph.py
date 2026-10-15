#!/usr/bin/env python3
"""Audit feedback-cut transitions in the current self-host parser graph.

python3 evals/parser_boundary_graph.py [--profile kont_entry|callsites|unweighted]
python3 evals/parser_boundary_graph.py --gateway parse_atom_scan --gateway ...

A gateway replaces ALL internal calls into that function with typed Request/Kont
transitions. A residual helper remains an ordinary definition in the resulting
DAG; reachability from a gateway is NOT a reason to convert it into a state.
This graph proof does not establish Bend typing, termination, or AST parity.
"""

import argparse
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASELINE = "0d0e204f"
SOURCE = "bend2/selfhost/parser.bend"
DEF = re.compile(r"^def ([A-Za-z_]\w*)\(")
CALL = re.compile(r"(?<![.\w])([A-Za-z_]\w*)\s*\(")
OLD_EIGHT = {
    "parse_do_return", "parse_do_return_scan", "parse_term", "parse_atom",
    "parse_atom_scan", "parse_do_atom", "parse_do_atom_args_result",
    "parse_do_atom_colon",
}


@dataclass(frozen=True)
class Site:
    caller: str
    callee: str
    line: int


def unquoted(line):
    """Mask quoted text/comments, preserving source positions."""
    out, quote, escaped = [], None, False
    for char in line:
        if quote:
            out.append(" ")
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in ('"', "'"):
            quote = char
            out.append(" ")
        elif char == "#":
            break
        else:
            out.append(char)
    return "".join(out)


def source_graph(source):
    lines = source.splitlines()
    definitions = {}
    for line, text in enumerate(lines, 1):
        found = DEF.match(text)
        if found:
            if found[1] in definitions:
                raise ValueError(f"duplicate definition {found[1]} at {line}")
            definitions[found[1]] = line
    if not definitions:
        raise ValueError("no parser definitions")
    bodies = defaultdict(list)
    owner = None
    for line, text in enumerate(lines, 1):
        found = DEF.match(text)
        if found:
            owner = found[1]
        elif text and not text[0].isspace() and not text.startswith("#"):
            owner = None
        elif owner is not None and text.startswith((" ", "\t")):
            bodies[owner].append((line, text))
    sites = [Site(owner, found[1], line)
             for owner, body in bodies.items()
             for line, text in body
             for found in CALL.finditer(unquoted(text))
             if found[1] in definitions]
    edges = {name: set() for name in definitions}
    for site in sites:
        edges[site.caller].add(site.callee)
    return definitions, bodies, sites, edges


def components(edges):
    index, number, low, stack, active, result = 0, {}, {}, [], set(), []

    def visit(node):
        nonlocal index
        number[node] = low[node] = index
        index += 1
        stack.append(node)
        active.add(node)
        for target in sorted(edges[node]):
            if target not in number:
                visit(target)
                low[node] = min(low[node], low[target])
            elif target in active:
                low[node] = min(low[node], number[target])
        if low[node] == number[node]:
            group = set()
            while True:
                item = stack.pop()
                active.remove(item)
                group.add(item)
                if item == node:
                    break
            result.append(group)

    for node in sorted(edges):
        if node not in number:
            visit(node)
    return result


def cyclic(edges):
    return [group for group in components(edges)
            if len(group) > 1 or any(node in edges[node] for node in group)]


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--profile", choices=("kont_entry", "callsites", "unweighted"),
                     default="kont_entry")
    cli.add_argument("--gateway", action="append", default=None,
                     help="explicit gateway name; repeat to replace a profile")
    args = cli.parse_args()
    # AST dependencies are authoritative; the lexical scan below supplies only
    # separately labeled source-callsite context and weighting evidence.
    from parser_feedback_vertices import ast_input
    raw = ast_input()
    source = raw["source"]
    definitions, bodies, sites, _ = source_graph(source)
    graph = {name: set(targets) for name, targets in raw["edges"].items()}
    core = next(group for group in components(graph) if "parse_term" in group)
    inside = [site for site in sites if site.caller in core and site.callee in core]
    edges = {name: graph[name] & core for name in core}
    # Import after the common graph primitives have been defined; the vertex
    # analyzer imports these primitives but never imports this CLI's main().
    from parser_feedback_vertices import (PROFILES, choose_cut,
                                          gateway_metrics, incoming_contexts,
                                          return_type)
    from parser_feedback_edges import site_context
    classified = incoming_contexts(bodies, definitions)
    if Counter((x.caller, x.callee, x.line) for x in classified) != Counter(
            (x.caller, x.callee, x.line) for x in sites):
        raise ValueError("callsite classification disagrees with graph")
    signatures = {name: return_type(source.splitlines()[definitions[name] - 1])
                  for name in core}
    metrics = gateway_metrics(core, classified, signatures)
    gateways = (set(args.gateway) if args.gateway is not None else
                choose_cut(edges, metrics, PROFILES[args.profile]))
    if not gateways or not gateways <= core:
        raise ValueError(f"gateway names outside main SCC: {sorted(gateways - core)}")
    residual = {name: edges[name] - gateways for name in core if name not in gateways}
    transitioned = {name: edges[name] - gateways for name in core}
    if cyclic(residual) or cyclic(transitioned):
        raise ValueError("feedback cut FAILED: non-singleton or self-recursive SCC remains")
    crossings = [s for s in classified if s.caller in core and s.callee in gateways]
    contexts = [s for s in classified if s.caller in core and s.callee in core]
    proven_non_tail = [s for s in contexts if s.non_tail]
    cut_non_tail = [s for s in crossings if s.non_tail]
    lines = {line: text for body in bodies.values() for line, text in body}
    kinds = {s: site_context(lines[s.line], s.column - 1) for s in crossings}
    if any((kind == "nested-argument") != s.non_tail for s, kind in kinds.items()):
        raise ValueError("independent non-tail classifications disagree")
    external_targets = [s for s in sites if s.caller not in core and s.callee in gateways]
    external_residual = [s for s in sites if s.caller not in core and s.callee in residual]

    # Uniform Control<T> lifting through the acyclic residual: every old SCC
    # helper can reach some boundary caller, but only crossing callsites are
    # Requests. This is a signature exposure count, NOT a machine state count.
    direct = {s.caller for s in crossings if s.caller in residual}
    reverse = {node: set() for node in residual}
    for caller in residual:
        for callee in residual[caller]:
            reverse[callee].add(caller)
    exposed = set(direct)
    todo = list(direct)
    while todo:
        for caller in reverse[todo.pop()] - exposed:
            exposed.add(caller)
            todo.append(caller)
    non_tail_residual_callers = {s.caller for s in proven_non_tail
                                 if s.callee not in gateways and s.caller in residual}
    semantic_residual = direct | non_tail_residual_callers
    prior = [s for s in inside if s.caller in OLD_EIGHT and s.callee not in OLD_EIGHT]
    families = {metrics[name]["family"] for name in gateways}
    print(f"{BASELINE}: graph=stage0-raw-HOAS main={len(core)} "
          f"ast_edges={sum(map(len, edges.values()))} "
          f"lexical_callsites={len(inside)} gateways={len(gateways)} "
          f"residual_nodes={len(residual)} residual_cycles=0 transition_cycles=0")
    print(f"profile={args.profile if args.gateway is None else 'explicit'} "
          f"gateway_names={','.join(sorted(gateways))}")
    print(f"boundary_edges={len({(s.caller, s.callee) for s in crossings})} "
          f"boundary_callsites={len(crossings)} proven_non_tail={len(cut_non_tail)} "
          f"source_visible_tail={sum(k in ('lambda-tail', 'branch-tail') for k in kinds.values())} "
          f"unclassified={sum(k not in ('nested-argument', 'lambda-tail', 'branch-tail') for k in kinds.values())} "
          f"result_families={','.join(sorted(families))} "
          f"external_gateway_entries={len(external_targets)}")
    print(f"uniform_lift_exposed={len(exposed)} direct_boundary_callers={len(direct)} "
          f"residual_non_tail_sites={len(proven_non_tail)-len(cut_non_tail)} "
          f"semantic_body_sites_lower_bound={len(semantic_residual | gateways)} "
          f"external_compatibility_targets={','.join(sorted({s.callee for s in external_residual}))}")
    print("prior_eight_outbound: " + "; ".join(
        f"{s.caller}:{s.line}->{s.callee}={'REQUEST' if s.callee in gateways else 'DAG'}"
        for s in sorted(prior, key=lambda item: item.line)))
    for gateway in sorted(gateways):
        rows = sorted((s for s in crossings if s.callee == gateway),
                      key=lambda site: (site.line, site.column))
        print(f"gateway {gateway} [{metrics[gateway]['family']}] ({len(rows)}): " +
              "; ".join(f"{s.caller}:{s.line}:{s.column}="
                        f"{'non-tail' if s.non_tail else kinds[s]}"
                        for s in rows))
    independent = sorted((sorted(group) for group in components(graph)
                          if len(group) > 1 and group != core),
                         key=lambda group: (-len(group), group))
    print("independent_non_singleton_sccs=" + repr(independent))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"feedback-cut audit failed: {error}", file=sys.stderr)
        sys.exit(2)
