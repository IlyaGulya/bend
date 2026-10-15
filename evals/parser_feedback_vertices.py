#!/usr/bin/env python3
"""Compare weighted feedback-vertex cuts on the frozen stage-0 parser AST.

Usage: python3 evals/parser_feedback_vertices.py [--ast-stdin]

This is a counterfactual call-graph analysis, not a parser transformation: a
selected gateway means replacing *all internal calls into it* with Request/Kont
transitions. Ordinary reachable helpers outside the cut remain ordinary code.
The edges come from the raw stage-0 AST; lexical sites supply labeled weights.
"""

from collections import Counter, defaultdict
import argparse
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
import re
import subprocess
import sys

from parser_boundary_graph import CALL, DEF, components, source_graph, unquoted


REVISION = "0d0e204f"
SOURCE_SHA256 = "0009070688f8fffffbb8664e72bd4662bf1324675ba097297076d77939153df5"
SOURCE = "bend2/selfhost/parser.bend"
ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Incoming:
    caller: str
    callee: str
    line: int
    context: str
    # Only an argument to a surrounding call or an explicitly bound result
    # is source-proven non-tail. Other sites are UNKNOWN, not claimed tail.
    non_tail: bool
    column: int


def incoming_contexts(bodies, definitions):
    """Classify the lexical callsites with explicit, line-local evidence only."""
    result = []
    for owner, body in bodies.items():
        for line, text in body:
            code = unquoted(text)
            matches = list(CALL.finditer(code))
            for match in matches:
                callee = match[1]
                if callee not in definitions:
                    continue
                # Find the innermost earlier enclosing invocation, if any.
                # Lambdas inside the argument list are not necessarily
                # non-tail: only the pre-lambda portion is counted.
                prefix = code[:match.start()]
                enclosing = []
                for previous in matches:
                    if previous.start() >= match.start():
                        break
                    opening = previous.end() - 1
                    balance = 1
                    for char in code[opening + 1:match.start()]:
                        balance += (char == "(") - (char == ")")
                    if balance > 0 and "=>" not in code[opening + 1:match.start()]:
                        enclosing.append(previous[1])
                binding = re.search(r"(?:^|\s)([A-Za-z_]\w*)\s*=\s*$", prefix)
                if enclosing:
                    context = "argument:" + enclosing[-1]
                    non_tail = True
                elif binding:
                    context = "binding:" + binding[1]
                    non_tail = True
                else:
                    context = "unclassified"
                    non_tail = False
                result.append(Incoming(owner, callee, line, context, non_tail, match.start() + 1))
    return result


def cyclic_components(edges):
    return [group for group in components(edges)
            if len(group) > 1 or any(node in edges[node] for node in group)]


def return_type(signature):
    # Every definition has its last arrow outside the parameter list; this
    # parser signature convention makes the annotation directly auditable.
    if " -> " not in signature or not signature.endswith(":"):
        raise ValueError(f"unrecognized definition signature: {signature}")
    return re.sub(r"\s+", "", signature.rsplit(" -> ", 1)[1][:-1])


def result_family(annotation):
    if annotation.startswith("((List<&2,Ast.SyntaxTerm>"):
        return "term-list+tokens+line"
    if annotation.startswith("(List<&2,Ast.SyntaxTerm>"):
        return "term-list+tokens"
    if "Ast.SyntaxTerm" in annotation:
        return "term+tokens"
    return "other"


def gateway_metrics(core, sites, signatures):
    internal = defaultdict(list)
    external = defaultdict(list)
    for site in sites:
        if site.callee in core:
            (internal if site.caller in core else external)[site.callee].append(site)
    metrics = {}
    for node in core:
        inbound = internal[node]
        contexts = {site.context for site in inbound if site.context != "unclassified"}
        annotation = signatures[node]
        metrics[node] = {
            "incoming": len(inbound),
            "non_tail": sum(site.non_tail for site in inbound),
            "contexts": len(contexts),
            "external": len(external[node]),
            "external_callers": len({site.caller for site in external[node]}),
            "type": annotation,
            "family": result_family(annotation),
            "shape": 1 + min(len(re.findall(r"&(?!\d)", annotation)), 3),
            "non_tail_lines": sorted({site.line for site in inbound if site.non_tail}),
        }
    return metrics


# Transparent, deliberately contrasting weights (not runtime measurements).
# Non-tail counts are LOWER BOUNDS: unclassified does not mean tail.
PROFILES = {
    "unweighted": (0, 0, 0, 0, 0, 0),
    "callsites": (3, 1, 1, 1, 0, 1),
    "kont_entry": (1, 4, 5, 8, 2, 4),
}


def weight(metric, factors):
    incoming, non_tail, contexts, external, shape, family = factors
    family_cost = {"term+tokens": 0, "term-list+tokens": 1,
                   "term-list+tokens+line": 2}.get(metric["family"], 2)
    return (1 + incoming * metric["incoming"]
            + non_tail * metric["non_tail"]
            + contexts * metric["contexts"]
            + external * metric["external"]
            + shape * (metric["shape"] - 1)
            + family * family_cost)


def reduced_graph(edges, removed):
    return {node: targets - removed for node, targets in edges.items()
            if node not in removed}


def choose_cut(core_edges, metrics, factors):
    """Greedy cyclic-edge coverage per unit node cost, then reverse pruning.

    At each step only edges within current cyclic SCCs contribute; acyclic
    dependencies cannot inflate a node's benefit. Sorting all ties gives
    deterministic results across Python processes/platforms.
    """
    remaining = {node: set(targets) for node, targets in core_edges.items()}
    chosen = []
    while cyclic := cyclic_components(remaining):
        covered = Counter()
        for group in cyclic:
            for node in group:
                for target in remaining[node] & group:
                    covered[node] += 1
                    if target != node:
                        covered[target] += 1
        candidate = min(covered, key=lambda node: (
            weight(metrics[node], factors) / covered[node],
            weight(metrics[node], factors), node))
        chosen.append(candidate)
        remaining = reduced_graph(remaining, {candidate})
    # A removed node that became redundant later need not be a gateway.
    selected = set(chosen)
    for node in reversed(chosen):
        trial = selected - {node}
        if not cyclic_components(reduced_graph(core_edges, trial)):
            selected = trial
    return selected


def describe(label, cut, metrics, core_edges, sites, factors):
    internal = [site for site in sites if site.caller in core_edges and site.callee in cut]
    external = [site for site in sites if site.caller not in core_edges and site.callee in cut]
    residual = reduced_graph(core_edges, cut)
    residual_cycles = cyclic_components(residual)
    if residual_cycles:
        raise ValueError(f"{label}: removing gateways leaves cycles {residual_cycles}")
    # The counterfactual retains gateway vertices and their outbound ordinary
    # edges within the original main SCC, but replaces every internal incoming
    # call with a transition, including the self-edge. Other SCCs in the
    # complete parser graph are independent of this particular migration.
    transitioned = {node: targets - cut for node, targets in core_edges.items()}
    original_self = [(node, node) for node in cut if node in core_edges[node]]
    transition_cycles = cyclic_components(transitioned)
    if transition_cycles:
        raise ValueError(f"{label}: transition cut leaves cycles {transition_cycles}")
    if any(node in transitioned[node] for node in cut):
        raise ValueError(f"{label}: self-edge survived the cut")
    weight_total = sum(weight(metrics[node], factors) for node in cut)
    types = {metrics[node]["type"] for node in cut}
    families = {metrics[node]["family"] for node in cut}
    print(f"{label}: gateways={len(cut)} weighted_cost={weight_total} "
          f"incoming_internal_callsites={len(internal)} "
          f"incoming_internal_edges={len({(s.caller, s.callee) for s in internal})} "
          f"non_tail_proven_min={sum(s.non_tail for s in internal)} "
          f"context_shapes={len({s.context for s in internal if s.context != 'unclassified'})} "
          f"result_types={len(types)} result_families={len(families)} "
          f"external_entry_callsites={len(external)} "
          f"external_entry_callers={len({s.caller for s in external})} "
          f"removed_self_edges={len(original_self)} residual_cycles={len(residual_cycles)} "
          f"transition_non_singleton={sum(len(group) > 1 for group in components(transitioned))} "
          f"transition_self_cycles={len(transition_cycles)}")
    print(f"  families: {', '.join(sorted(families))}")
    for node in sorted(cut):
        m = metrics[node]
        print(f"  {node}: incoming={m['incoming']} non_tail_min={m['non_tail']} "
              f"contexts={m['contexts']} external={m['external']} "
              f"external_callers={m['external_callers']} family={m['family']} "
              f"result={m['type']} weight={weight(m, factors)} "
              f"non_tail_lines={','.join(map(str, m['non_tail_lines'])) or '-'}")


def ast_input():
    """Read the authoritative frozen graph; lexical scans never select edges."""
    return json.loads(subprocess.check_output(
        ["bun", "evals/parser_full_graph.ts", "--raw-stdout"],
        cwd=ROOT, text=True))


def analyze_full_graph(raw):
    source = raw["source"]
    if (raw["sourceCheckpoint"] != REVISION or raw["sourceSha256"] != SOURCE_SHA256
            or hashlib.sha256(source.encode()).hexdigest() != SOURCE_SHA256):
        raise ValueError("AST input differs from frozen checkpoint 0d0e204f")
    definitions, bodies, parsed_sites, lexical_graph = source_graph(source)
    graph = {name: set(targets) for name, targets in raw["edges"].items()}
    if set(graph) != set(definitions) or set(raw["definitions"]) != set(definitions):
        raise ValueError("AST and lexical definition inventories disagree")
    if any(target not in graph for targets in graph.values() for target in targets):
        raise ValueError("AST graph contains non-parser targets")
    sites = incoming_contexts(bodies, definitions)
    if Counter((s.caller, s.callee, s.line) for s in sites) != Counter(
            (s.caller, s.callee, s.line) for s in parsed_sites):
        raise ValueError("lexical callsite classification drifted")
    ast_pairs = {(caller, callee) for caller, targets in graph.items() for callee in targets}
    lexical_pairs = {(caller, callee) for caller, targets in lexical_graph.items() for callee in targets}
    groups = components(graph)
    core = next(group for group in groups if "parse_term" in group)
    core_edges = {node: graph[node] & core for node in core}
    lines = source.splitlines()
    weighted_members = set().union(*(group for group in groups if len(group) > 1))
    signatures = {name: return_type(lines[definitions[name] - 1]) for name in weighted_members}
    metrics = gateway_metrics(core, sites, signatures)

    def summary(edges, members, selected, group_metrics, factors):
        residual = reduced_graph(edges, selected)
        transitioned = {node: targets - selected for node, targets in edges.items()}
        if cyclic_components(residual) or cyclic_components(transitioned):
            raise ValueError("weighted feedback cut leaves a cyclic SCC")
        inbound = [site for site in sites if site.caller in members and site.callee in selected]
        return {
            "selected": sorted(selected),
            "weightedCost": sum(weight(group_metrics[node], factors) for node in selected),
            "internalBoundaryEdges": sum(len(targets & selected) for targets in edges.values()),
            "lexicalInternalBoundaryEdges": len({(s.caller, s.callee) for s in inbound}),
            "lexicalInternalBoundaryCallsites": len(inbound),
            "lexicalNonTailLowerBound": sum(site.non_tail for site in inbound),
            "lexicalExternalEntryCallsites": sum(
                site.caller not in members and site.callee in selected for site in sites),
            "residualNodes": len(residual),
            "residualCyclicComponents": [],
            "transitionedCyclicComponents": [],
        }

    profiles = {}
    for label, factors in PROFILES.items():
        selected = choose_cut(core_edges, metrics, factors)
        profiles[label] = {"factors": list(factors),
                           **summary(core_edges, core, selected, metrics, factors)}
    selected = set(profiles["kont_entry"]["selected"])
    independent = sorted((group for group in groups if len(group) > 1 and group != core),
                         key=lambda group: (-len(group), sorted(group)))
    independent_sccs = []
    additional = set()
    for group in independent:
        edges = {node: graph[node] & group for node in group}
        group_metrics = gateway_metrics(group, sites, signatures)
        gateways = choose_cut(edges, group_metrics, PROFILES["kont_entry"])
        additional |= gateways
        independent_sccs.append({
            "members": sorted(group), "internalEdges": sum(map(len, edges.values())),
            "lexicalInternalCallsites": sum(s.caller in group and s.callee in group for s in sites),
            "metrics": group_metrics,
            **summary(edges, group, gateways, group_metrics, PROFILES["kont_entry"]),
        })
    complete_selected = selected | additional
    residual = reduced_graph(graph, selected)
    complete_residual = reduced_graph(graph, complete_selected)
    complete_transitioned = {node: targets - complete_selected for node, targets in graph.items()}
    complete_non_singleton = [sorted(group) for group in components(complete_residual) if len(group) > 1]
    if complete_non_singleton or any(len(group) > 1 for group in components(complete_transitioned)):
        raise ValueError("independent SCC cuts leave mutual recursion")
    lexical_inventory = [
        {"caller": s.caller, "callee": s.callee, "line": s.line, "column": s.column,
         "context": s.context, "nonTailLowerBound": s.non_tail}
        for s in sorted(sites, key=lambda site: (site.line, site.column, site.caller, site.callee))
    ]
    return {
        "sourceCheckpoint": raw["sourceCheckpoint"], "sourceSha256": raw["sourceSha256"],
        "graphProvenance": raw["graphProvenance"], "definitions": sorted(graph),
        "definitionCount": len(graph),
        "edges": {name: sorted(graph[name]) for name in sorted(graph)},
        "edgeCount": sum(map(len, graph.values())),
        "mainSCC": sorted(core), "mainInternalEdges": sum(map(len, core_edges.values())),
        "selected": sorted(selected), "selectedProfile": "kont_entry", "profiles": profiles,
        "mainMetrics": {name: metrics[name] for name in sorted(metrics)},
        "independentSCCs": independent_sccs, "additionalSelected": sorted(additional),
        "completeSelected": sorted(complete_selected),
        "residualComponents": sorted((sorted(group) for group in components(residual)),
                                     key=lambda group: (-len(group), group)),
        "residualNonSingletonSCCs": sorted(
            (sorted(group) for group in components(residual) if len(group) > 1),
            key=lambda group: (-len(group), group)),
        "completeResidualNonSingletonSCCs": complete_non_singleton,
        "completeResidualSelfRecursive": sorted(node for node in complete_residual
                                                if node in complete_residual[node]),
        "completeTransitionedSelfRecursive": sorted(node for node in complete_transitioned
                                                    if node in complete_transitioned[node]),
        "astReferences": raw["astReferences"],
        "unresolvedReferences": raw["unresolvedReferences"], "comparisons": raw["comparisons"],
        "lexicalMetrics": {
            "provenance": "line-local name(...) scan, not authoritative AST edges",
            "mainInternalCallsites": sum(s.caller in core and s.callee in core for s in sites),
            "callsites": lexical_inventory,
            "astOnlyEdges": sorted([list(pair) for pair in ast_pairs - lexical_pairs]),
            "lexicalOnlyEdges": sorted([list(pair) for pair in lexical_pairs - ast_pairs]),
        },
    }


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("--ast-stdin", action="store_true",
                     help="emit full cut JSON from parser_full_graph.ts raw graph")
    args = cli.parse_args()
    raw = json.load(sys.stdin) if args.ast_stdin else ast_input()
    result = analyze_full_graph(raw)
    if args.ast_stdin:
        print(json.dumps(result, sort_keys=True))
        return 0
    source = raw["source"]
    definitions, bodies, _, _ = source_graph(source)
    graph = {name: set(targets) for name, targets in raw["edges"].items()}
    core = set(result["mainSCC"])
    core_edges = {node: graph[node] & core for node in core}
    sites = incoming_contexts(bodies, definitions)
    metrics = result["mainMetrics"]
    self_edges = sorted(node for node in core if node in core_edges[node])
    print(f"revision={REVISION} source={SOURCE} main_scc={len(core)} "
          f"internal_ast_edges={sum(map(len, core_edges.values()))} "
          f"lexical_internal_callsites={result['lexicalMetrics']['mainInternalCallsites']} "
          f"self_edges={','.join(self_edges) or '-'}")
    print("non_tail_proven_min: only source-visible nested-call arguments before "
          "a lambda and bound results; all other sites remain unclassified. "
          "context_shapes are syntactic proxies, not measured Kont constructors. "
          "external entries count only calls visible inside parser.bend.")
    for label, factors in PROFILES.items():
        cut = set(result["profiles"][label]["selected"])
        describe(label, cut, metrics, core_edges, sites, factors)
    print("independent_non_singleton_sccs=" +
          json.dumps([group["members"] for group in result["independentSCCs"]]))
    print("additional_kont_entry_gateways=" + ",".join(result["additionalSelected"]))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"feedback-vertex analysis error: {error}", file=sys.stderr)
        sys.exit(2)
