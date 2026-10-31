#!/usr/bin/env python3
"""Read-only N11 post-run verification. Usage: REPO EXPERIMENT OUTPUT_JSON.

Run only after the parent runner has settled. No compiler/runtime is executed.
Exit 0 means internally verified evidence (including honestly failed cells), not
compiler acceptance; exit 1 means evidence errors. Output must not already exist.
All binary/C hashing and equality checks stream fixed-size chunks. JSON metadata
and individual JSONL records have explicit size caps; oversized data is rejected,
not silently truncated or accepted. No timestamps are added to the output.
"""
import argparse
import hashlib
import json
import math
import re
import sys
from pathlib import Path

CHUNK = 1024 * 1024
JSON_LIMIT = 64 * CHUNK
LINE_LIMIT = CHUNK
BOUNDARY_LIMIT = 4096
SHA = re.compile(r"[0-9a-f]{64}\Z")
FINE = re.compile(r"^(prepare|c-definition|c-spin)-")
PASS = re.compile(r"c-pass-(\d+)-(before|close-before|close-after|after)\Z")
FACTS = ("ownFacts", "hotFacts", "staticFacts")
PHASES = ("graphs", "metadata", "tabs", "spins", "segs", "runtime", "ids", "reset")
GUARD = {"memoryMiB": 8192, "rssMiB": 8192, "pollMs": 10,
         "timeoutMs": 600000, "termGraceMs": 1000}
CASES = [{"id": s + "_" + h, "source": s,
          "gcRamHint": "4294967296" if h == "hint" else None}
         for h in ("hint", "unset") for s in ("R12", "G39")]
ACCEPTED_C = "2290a096f114201665d4b943db3470889ca700ec205b875612178ea263e27ffb"


def reject_constant(value):
    raise ValueError("non-finite JSON number: " + value)


def decode(data):
    return json.loads(data, parse_constant=reject_constant)


def load_json(path):
    with Path(path).open("rb") as stream:
        data = stream.read(JSON_LIMIT + 1)
    if len(data) > JSON_LIMIT:
        raise ValueError("JSON metadata exceeds 64 MiB cap: " + str(path))
    return decode(data)


def digest(path):
    sha, size = hashlib.sha256(), 0
    with Path(path).open("rb") as stream:
        while True:
            block = stream.read(CHUNK)
            if not block:
                break
            sha.update(block)
            size += len(block)
    return {"sha256": sha.hexdigest(), "bytes": size}


def byte_equal(a, b):
    with Path(a).open("rb") as left, Path(b).open("rb") as right:
        while True:
            x, y = left.read(CHUNK), right.read(CHUNK)
            if x != y:
                return False
            if not x:
                return True


def key(row):
    if not isinstance(row, dict):
        return None
    return {k: row.get(k) for k in ("sequence", "stage", "name", "pass")}


def number(value):
    return type(value) in (int, float) and math.isfinite(value) and value >= 0


def boundary(stage):
    return not (FINE.match(stage) or stage == "release-after")


class Verifier:
    def __init__(self, repo, experiment):
        self.repo, self.experiment = repo, experiment
        self.run = experiment / "run-01"
        self.errors, self.warnings, self.cache = [], [], {}
        self.result = {"schemaVersion": 1, "experiment": "N11",
                       "diagnosticOnly": True, "compilerAccepted": False,
                       "performanceAccepted": False, "newFixedpointClaim": False,
                       "fullCompilerNativeExecutableVerified": False,
                       "historicalFailedCellEnvironments": "UNKNOWN",
                       "cells": [], "limitations": [
                           "Process memory and cumulative CPU/elapsed boundary samples only; not live/retained bytes, allocation attribution, exclusive CPU, or performance acceptance.",
                           "Maximum observed boundary RSS is not a process high-water mark; guardian peaks are separate process-tree observations.",
                           "Sparse progress does not reconstruct the all-observer structural trace hash; that digest is preserved as a worker claim only.",
                           "Failure progress identifies the latest recorded operation, not an engine allocation cause or a completed unrecorded stage.",
                           "Full compiler C construction does not establish native compilation, bootstrap, stage equality, or compiler acceptance.",
                           "Smoke original/shadow equality is attested by the authenticated smoke producer; only its shadow C was retained for independent byte hashing.",
                           "pollMs and termGraceMs are authenticated plan/runner settings, not independent fields emitted by the guardian receipt."]}

    def check(self, condition, where, message):
        if not condition:
            self.errors.append({"where": where, "message": message})
        return bool(condition)

    def warn(self, where, message):
        self.warnings.append({"where": where, "message": message})

    def path(self, value):
        p = Path(value)
        return p if p.is_absolute() else self.repo / p

    def hash_file(self, path):
        p = str(self.path(path))
        if p not in self.cache:
            self.cache[p] = digest(p)
        return self.cache[p]

    def pin(self, pin, where):
        result = {"path": pin.get("path"), "expectedSha256": pin.get("sha256")}
        try:
            actual = self.hash_file(pin["path"])
            result.update(actual)
            ok = self.check(bool(SHA.fullmatch(str(pin.get("sha256", "")))) and
                            actual["sha256"] == pin["sha256"], where, "SHA-256 pin mismatch")
            if "bytes" in pin:
                ok = self.check(actual["bytes"] == pin["bytes"], where, "byte-size pin mismatch") and ok
            result["matches"] = ok
        except (OSError, ValueError, KeyError) as error:
            self.check(False, where, str(error))
            result["matches"] = False
        return result

    def guardian(self, record, command, where, require_pass=False):
        g = record.get("guardian") or {}
        self.check(record.get("command") == command and g.get("command") == command,
                   where, "command differs from pinned invocation")
        self.check(g.get("reportPhase") == "complete" and g.get("ownedTreeStopped") is True,
                   where, "guardian has not confirmed complete owned-tree shutdown")
        self.check(g.get("memoryLimitBytes") == 8192 * CHUNK and
                   g.get("rssLimitBytes") == 8192 * CHUNK and g.get("timeoutMs") == 600000,
                   where, "original guardian limits differ")
        self.check(g.get("status") in ("PASS", "FAIL", "RESOURCE_LIMIT", "LOCK_BUSY"),
                   where, "unknown guardian outcome")
        if require_pass or g.get("status") == "PASS":
            self.check(g.get("status") == "PASS" and g.get("exitCode") == 0 and
                       g.get("supervisorExitCode") == 0 and g.get("commandExitCode") == 0 and
                       g.get("commandSignal") == 0, where, "guardian PASS/exit evidence inconsistent")
        return {k: g.get(k) for k in ("status", "reason", "reportPhase", "ownedTreeStopped",
                "exitCode", "supervisorExitCode", "commandExitCode", "commandSignal",
                "memoryLimitBytes", "rssLimitBytes", "timeoutMs", "elapsedMs",
                "peakRssBytes", "peakFootprintBytes")}

    def authenticate(self):
        plan = self.plan
        self.check(plan.get("experiment") == "N11" and plan.get("cases") == CASES,
                   "plan", "expected distinct four-cell source/hint matrix")
        self.check(plan.get("guard") == GUARD and plan.get("originalGuardUnchanged") is True,
                   "plan", "original limits not preserved")
        self.check(plan.get("expectedCheckedDefinitions") == 12456 and
                   plan.get("expectedBookEvents") == 13050, "plan", "canonical coverage changed")
        auth = {"tools": [], "lanes": {}, "origins": [], "binaries": []}
        for i, pin in enumerate(plan["toolPins"]):
            auth["tools"].append(self.pin(pin, "toolPins/" + str(i)))
        for name in ("bun", "node"):
            auth["binaries"].append({"runtime": name, **self.pin(plan[name], name)})
        origins = {}
        self.check(set(plan["lanes"]) == {"R12", "G39"}, "plan", "unexpected lanes")
        for name, lane in sorted(plan["lanes"].items()):
            self.check(len(lane["inputs"]) == 90, name, "expected 90 pinned sources")
            self.check(len({p["logicalPath"] for p in lane["inputs"]}) == 90,
                       name, "duplicate logical input paths")
            auth["lanes"][name] = [self.pin(p, name + "/" + p["logicalPath"]) for p in lane["inputs"]]
            for p in lane["inputs"]:
                origin = p["origin"]
                self.check(origin.get("kind") == "file", name, "unsupported source origin")
                origins[(origin["path"], origin["sha256"])] = origin
                if p.get("measurementOnlyPatch"):
                    self.check(p["logicalPath"] == "bend2/comp.ts" and
                               p["sha256"] == plan["instrumentation"]["shadowCompSha256"] and
                               origin["sha256"] == p.get("uninstrumentedSha256") ==
                               plan["instrumentation"]["originalCompSha256"], name, "shadow pin mismatch")
                else:
                    self.check(p["sha256"] == origin["sha256"], name + "/" + p["logicalPath"],
                               "unmarked source/origin byte difference")
        auth["origins"] = [self.pin(p, "origin/" + p["path"]) for _, p in sorted(origins.items())]
        auth["priorEvidence"] = self.pin(plan["priorEvidence"], "priorEvidence")
        auth["instrumentation"] = self.pin(plan["instrumentation"]["patch"], "instrumentation")
        self.result["authentication"] = auth
        restored_path = self.repo / "checkpoints/local2039g39e12-restored/restored.json"
        restored = load_json(restored_path)
        baseline = {"authority": {"path": str(restored_path), **digest(restored_path)}}
        for field, count in (("baselineSourceChecks", 21), ("generatedSources", 3)):
            rows = restored[field]
            self.check(len(rows) == count and len({r["path"] for r in rows}) == count,
                       field, "baseline cardinality mismatch")
            baseline[field] = [self.pin(p, field + "/" + p["path"]) for p in rows]
        self.check(set(restored["acceptedArtifacts"]) == {"native", "image"},
                   "acceptedArtifacts", "expected two accepted artifacts")
        baseline["acceptedArtifacts"] = {k: self.pin(v, "acceptedArtifacts/" + k)
                                         for k, v in sorted(restored["acceptedArtifacts"].items())}
        baseline["unchanged"] = all(p["matches"] for field in ("baselineSourceChecks", "generatedSources")
                                    for p in baseline[field]) and all(p["matches"] for p in baseline["acceptedArtifacts"].values())
        self.result["baseline"] = baseline
        accepted = plan["acceptedC"]
        authority = self.pin(accepted["receipt"], "acceptedC/receipt")
        # The accepted build receipt embeds large raw compiler logs. Scan bounded
        # lines for its top-level C fields instead of decoding those log strings.
        fields = {}
        with self.path(accepted["receipt"]["path"]).open("rb") as stream:
            for _ in range(200):
                line = stream.readline(LINE_LIMIT + 1)
                if len(line) > LINE_LIMIT:
                    raise ValueError("accepted C authority header line exceeds cap")
                match = re.fullmatch(rb'  "(cPath|cSha256)": ("[^"\r\n]*"),?\s*', line)
                if match:
                    fields[match[1].decode()] = decode(match[2])
                if len(fields) == 2 or not line:
                    break
        self.check(fields.get("cSha256") == accepted["sha256"] == ACCEPTED_C and
                   fields.get("cPath") == accepted["path"], "acceptedC", "accepted receipt C authority mismatch")
        self.accepted = self.pin(accepted, "acceptedC/file")
        self.result["acceptedCAuthority"] = {"receipt": authority, "actualC": self.accepted}

    def smoke(self, receipt):
        smoke = receipt.get("smoke") or {}
        sr = str(self.run / "smoke.json")
        binary = str(self.run / "smoke-native")
        commands = {
            "emit": [self.plan["bun"]["path"], str(self.experiment / "smoke.mjs"), str(self.plan_path), sr],
            "clang": ["/usr/bin/clang", "-std=c11", "-O1", "-pthread", sr + ".c", "-lm", "-o", binary],
            "execution": [self.plan["node"]["path"], self.plan["captureSource"],
                          str(self.run / "smoke.stdout"), str(self.run / "smoke.stderr"), binary]}
        guards = {k: self.guardian(smoke.get(k) or {}, v, "smoke/" + k, True)
                  for k, v in commands.items()}
        data = load_json(sr)
        self.check(data == smoke.get("receipt"), "smoke", "embedded smoke receipt differs")
        self.check(smoke.get("status") == "PASS_EXACT_ORIGINAL_BYTES_AND_ACTUAL_C_CONSUMER" and
                   data.get("status") == "PASS_EXACT_ORIGINAL_C_BYTES", "smoke", "equality smoke did not pass")
        self.check(data.get("source") == self.plan["smoke"]["source"] and
                   data.get("inputSha256") == self.hash_file(data["source"])["sha256"], "smoke", "source pin mismatch")
        self.check(data.get("originalCompilerSha256") == self.plan["instrumentation"]["originalCompSha256"] and
                   data.get("shadowCompilerSha256") == self.plan["instrumentation"]["shadowCompSha256"],
                   "smoke", "compiler pin mismatch")
        self.check(data.get("runtime") == {"bun": self.plan["bun"]["version"], "execArgv": []},
                   "smoke", "runtime mismatch")
        stages = ["c-" + p + "-" + end for p in PHASES for end in ("before", "after")]
        self.check([r.get("stage") for r in data.get("events", [])] == stages,
                   "smoke", "instrumentation phase sequence mismatch")
        self.check(data.get("output") == sr + ".c", "smoke", "unexpected output path")
        output = self.pin({"path": sr + ".c", "sha256": data.get("outputSha256"),
                           "bytes": data.get("outputBytes")}, "smoke/C")
        expected = self.plan["smoke"]["expected"]
        with (self.run / "smoke.stdout").open("rb") as stream:
            actual = stream.read(len(expected.encode()) + 1)
        self.check(actual == expected.encode() and smoke.get("actual") == expected and
                   smoke.get("expected") == expected, "smoke", "actual C stdout differs")
        self.result["smoke"] = {"status": smoke.get("status"), "guardians": guards,
                                "C": output, "actualCStdoutMatches": actual == expected.encode(),
                                "stdout": digest(self.run / "smoke.stdout"),
                                "stderr": digest(self.run / "smoke.stderr"),
                                "native": digest(binary), "receipt": digest(sr)}

    def log(self, path, worker, complete, where):
        sha, size, lines, valid, previous = hashlib.sha256(), 0, 0, 0, 0
        last, first_bad, issues, boundaries, last_completed = None, None, [], [], None
        last_before = None
        with Path(path).open("rb") as stream:
            while True:
                raw = stream.readline(LINE_LIMIT + 1)
                if not raw:
                    break
                lines += 1
                start = size
                sha.update(raw)
                size += len(raw)
                oversized = len(raw) > LINE_LIMIT
                if oversized:
                    while raw and not raw.endswith(b"\n"):
                        raw = stream.readline(LINE_LIMIT + 1)
                        sha.update(raw)
                        size += len(raw)
                terminated = raw.endswith(b"\n")
                try:
                    if oversized:
                        raise ValueError("record exceeds 1 MiB cap")
                    row = decode(raw)
                    if not isinstance(row, dict) or type(row.get("sequence")) is not int or row["sequence"] <= previous:
                        raise ValueError("missing/non-increasing sequence")
                    if not isinstance(row.get("stage"), str) or not isinstance(row.get("name"), str) or type(row.get("pass")) is not int:
                        raise ValueError("invalid progress key")
                    previous = row["sequence"]
                    valid += 1
                    if first_bad is None:
                        last = row
                    if row["stage"].endswith("-before"):
                        last_before = key(row)
                    if boundary(row["stage"]):
                        if len(boundaries) >= BOUNDARY_LIMIT:
                            raise ValueError("boundary count exceeds cap")
                        boundaries.append(row)
                        if row["stage"].endswith("-after") or row["stage"] in ("loaded", "validated", "compile-return", "c-published"):
                            last_completed = row
                except (ValueError, TypeError, UnicodeError) as error:
                    if first_bad is None:
                        first_bad = lines
                    if len(issues) < 16:
                        issues.append({"line": lines, "byteOffset": start, "error": str(error),
                                       "newlineTerminated": terminated})
                if not terminated:
                    issues.append({"line": lines, "byteOffset": start, "error": "unterminated final record"})
        terminal_hash = worker.get("progressSha256")
        matches = sha.hexdigest() == terminal_hash if terminal_hash else None
        if terminal_hash:
            self.check(matches, where, "worker terminal progress SHA mismatch")
            self.check(worker.get("terminal") is True, where, "progress digest without worker terminal record")
        elif complete or worker.get("terminal"):
            self.check(False, where, "terminal progress SHA missing")
        else:
            self.warn(where, "No worker terminal digest: log hash is post-run observation, not worker-authenticated closure")
        if issues:
            if complete or terminal_hash or (first_bad is not None and first_bad != lines):
                self.check(False, where, "progress parse/termination issues")
            else:
                self.warn(where, "Failed-cell progress has a partial final tail; retained as incomplete evidence")
        saved_boundaries = worker.get("boundaries", [])
        self.check(boundaries[:len(saved_boundaries)] == saved_boundaries,
                   where, "saved boundaries not an exact prefix of streamed boundaries")
        if worker.get("terminal"):
            self.check(boundaries == saved_boundaries, where, "terminal boundary list incomplete")
        return {"path": str(path), "sha256": sha.hexdigest(), "bytes": size,
                "lines": lines, "validRows": valid, "terminalHashMatches": matches,
                "issues": issues, "firstInvalidLine": first_bad, "lastProgress": last,
                "lastBeforeKey": last_before, "lastCompletedBoundary": last_completed}, boundaries

    def phases(self, rows, complete, where):
        expected = ["loaded", "validated", "c-reachability-before", "c-reachability-after"]
        suffix = ["c-" + p + "-" + end for p in PHASES for end in ("before", "after")]
        suffix += ["compile-return", "c-published"]
        index, pass_number, pass_part, suffix_index = 0, 1, 0, None
        pass_start, previous_end, passes = None, None, []
        order_ok = True
        for row in rows:
            stage = row["stage"]
            if index < len(expected):
                want = expected[index]
                index += 1
            elif suffix_index is not None:
                want = suffix[suffix_index] if suffix_index < len(suffix) else "<no later boundary>"
                suffix_index += 1
            else:
                want = "c-pass-%d-%s" % (pass_number, ("before", "close-before", "close-after", "after")[pass_part])
            if not self.check(stage == want, where, "phase order: expected %s, observed %s" % (want, stage)):
                order_ok = False
                break
            m = PASS.fullmatch(stage)
            if m:
                state = row.get("state", {})
                counts = {k: state.get(k) for k in FACTS}
                if not self.check(all(type(v) is int and v >= 0 for v in counts.values()), where, "missing/invalid convergence facts"):
                    order_ok = False
                    break
                if m[2] == "before":
                    pass_start = counts
                    if previous_end is not None:
                        self.check(counts == previous_end, where, "facts changed between pass boundaries")
                if m[2] == "after":
                    self.check(all(counts[k] >= pass_start[k] for k in FACTS), where, "nonmonotone convergence facts")
                    settled = sum(counts.values()) == sum(pass_start.values())
                    passes.append({"pass": pass_number, "before": pass_start, "after": counts,
                                   "delta": {k: counts[k] - pass_start[k] for k in FACTS}, "settled": settled})
                    previous_end = counts
                    pass_number += 1
                    if settled:
                        suffix_index = 0
                pass_part = (pass_part + 1) % 4
        reached_end = order_ok and suffix_index == len(suffix)
        if complete:
            self.check(reached_end and bool(passes) and passes[-1]["settled"], where,
                       "complete cell lacks full ordered publication/converged pass evidence")
        return {"orderedPrefixValid": order_ok, "allConstructionBoundariesReached": reached_end,
                "completedPasses": passes, "converged": bool(passes) and passes[-1]["settled"],
                "observedBoundaryStages": [r["stage"] for r in rows]}

    def measurements(self, rows, where):
        result, previous, maximum = [], None, None
        for row in rows:
            memory, cpu = row.get("processMemory", {}), row.get("processCpuUs", {})
            valid = all(number(memory.get(k)) for k in ("rss", "heapUsed", "heapTotal", "external", "arrayBuffers"))
            valid = valid and all(number(cpu.get(k)) for k in ("user", "system")) and number(row.get("elapsedMs"))
            if not self.check(valid, where, "boundary memory/CPU/elapsed sample invalid"):
                continue
            sample = {**key(row), "phase": row.get("phase"), "elapsedMs": row["elapsedMs"],
                      "codegenElapsedMs": row.get("codegenElapsedMs"), "processMemory": memory,
                      "processCpuUs": cpu, "state": row.get("state", {})}
            if previous:
                self.check(row["elapsedMs"] >= previous["elapsedMs"] and
                           all(cpu[k] >= previous["processCpuUs"][k] for k in ("user", "system")),
                           where, "nonmonotone elapsed/cumulative CPU samples")
                sample["sincePreviousBoundary"] = {
                    "elapsedMs": row["elapsedMs"] - previous["elapsedMs"],
                    "processCpuUs": {k: cpu[k] - previous["processCpuUs"][k] for k in ("user", "system")},
                    "rssBytesDelta": memory["rss"] - previous["processMemory"]["rss"]}
            result.append(sample)
            if maximum is None or memory["rss"] > maximum["processMemory"]["rss"]:
                maximum = sample
            previous = row
        return {"boundarySamples": result, "maximumObservedRSSBoundary": maximum}

    def cell(self, cell, spec):
        where = spec["id"]
        before_errors = len(self.errors)
        report_path = self.run / (where + ".json")
        command = [self.plan["bun"]["path"], str(self.experiment / "worker.mjs"), str(self.plan_path), where, str(report_path)]
        self.check(all(cell.get(k) == v for k, v in spec.items()), where, "cell identity mismatch")
        self.check(cell.get("report") == str(report_path), where, "report path mismatch")
        guard = self.guardian(cell, command, where)
        output = {**spec, "reportedStatus": cell.get("status"), "guardian": guard,
                  "verifiedCompleteCConstruction": False, "environmentVerified": False,
                  "workerReason": cell.get("workerReason")}
        self.result["cells"].append(output)
        if not report_path.exists() or report_path.stat().st_size == 0:
            self.check(cell.get("status") != "COMPLETE_C_CONSTRUCTION", where, "complete cell has no worker report")
            if report_path.exists():
                self.pin({"path": str(report_path), "sha256": cell.get("reportSha256")}, where + "/report")
            else:
                self.check(cell.get("reportSha256") is None, where, "missing report has claimed hash")
            self.warn(where, "No saved worker report: runtime environment and stage reachability unavailable")
            output["reachability"] = "NO_WORKER_REPORT"
            return
        worker = load_json(report_path)
        output["report"] = self.pin({"path": str(report_path), "sha256": cell.get("reportSha256")}, where + "/report")
        self.check(worker.get("caseId") == where and worker.get("source") == spec["source"] and
                   worker.get("gcRamHint") == spec["gcRamHint"], where, "worker identity mismatch")
        self.check(worker.get("plan", {}).get("sha256") == self.plan_hash["sha256"] and
                   worker.get("plan", {}).get("path") == str(self.plan_path), where, "worker plan mismatch")
        for field in ("runtime", "boundaries", "checkedDefinitions", "eventsFullyValidated", "loadedInputs",
                      "progressSha256", "structuralTraceSha256", "output", "outputPublished", "expectedAcceptedC", "phase"):
            default = [] if field in ("boundaries", "loadedInputs") else None
            self.check(cell.get(field, default) == worker.get(field, default), where, "runner/worker field mismatch: " + field)
        self.check(cell.get("lastSaved") == worker.get("last") and cell.get("workerStatus") == worker.get("status") and
                   cell.get("workerTerminal") == worker.get("terminal") and cell.get("workerReason") == worker.get("reason"),
                   where, "runner/worker terminal or last-key mismatch")
        self.check(worker.get("checksExcluded") == 0 and worker.get("outputPatches") == 0 and
                   worker.get("compilerAccepted") is False and worker.get("performanceAccepted") is False and
                   worker.get("newFixedpointClaim") is False, where, "omission/patch/acceptance claims changed")
        runtime = worker.get("runtime", {})
        runtime_error_start = len(self.errors)
        environment = runtime.get("environment", {})
        expected_env = dict(self.receipt.get("inheritedRuntimeEnvironment", {}))
        expected_env.pop("BUN_JSC_forceRAMSize", None)
        if spec["gcRamHint"] is not None:
            expected_env["BUN_JSC_forceRAMSize"] = spec["gcRamHint"]
        self.check(environment == expected_env, where, "actual child environment differs from source/hint intervention")
        self.check(not any(re.match(r"^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$)", k)
                           and k != "BUN_JSC_forceRAMSize" for k in environment), where, "conflicting runtime environment")
        self.check(runtime.get("versions", {}).get("bun") == self.plan["bun"]["version"] and
                   runtime.get("execArgv") == [] and runtime.get("manualGC") is False,
                   where, "runtime version/flags/manual-GC mismatch")
        self.check(Path(runtime.get("execPath", "")).resolve() == Path(self.plan["bun"]["path"]).resolve(),
                   where, "worker executable differs from pinned Bun")
        argv = runtime.get("argv", [])
        self.check(len(argv) == len(command) and argv[1:] == command[1:] and
                   Path(argv[0]).resolve() == Path(self.plan["bun"]["path"]).resolve(),
                   where, "worker argv differs from pinned invocation")
        output["environmentVerified"] = len(self.errors) == runtime_error_start
        output["environment"] = environment
        output["runtime"] = {k: runtime.get(k) for k in ("execPath", "execArgv", "versions", "manualGC")}
        is_complete = (guard["status"] == "PASS" and worker.get("terminal") is True and
                       worker.get("status") == "COMPLETE_C_CONSTRUCTION" and worker.get("outputPublished") is True and
                       bool(worker.get("output", {}).get("sha256")))
        classification = "COMPLETE_C_CONSTRUCTION" if is_complete else "RESOURCE_LIMIT" if guard["status"] == "RESOURCE_LIMIT" else "FAIL"
        self.check(cell.get("status") == classification, where, "runner status misclassifies worker/guardian")
        expected_log = str(report_path) + ".progress.jsonl"
        self.check(worker.get("eventPath") == expected_log and cell.get("progressPath") == expected_log,
                   where, "progress path mismatch")
        progress, rows = self.log(expected_log, worker, is_complete, where)
        self.check(progress["lastProgress"] == cell.get("lastProgress"), where, "runner last progress differs from streamed prefix")
        self.check(bool(cell.get("progressParseError")) == (progress["firstInvalidLine"] is not None),
                   where, "runner/parser disagreement on malformed progress")
        last = key(progress["lastProgress"])
        output["progress"] = {**progress, "lastProgress": last,
                              "lastCompletedBoundary": key(progress["lastCompletedBoundary"])}
        output["lastSaved"] = worker.get("last")
        output["workerTerminal"] = worker.get("terminal")
        output["workerStatus"] = worker.get("status")
        output["phase"] = worker.get("phase")
        output["structuralTrace"] = {"workerReportedSha256": worker.get("structuralTraceSha256"),
                                      "independentlyRecomputed": False}
        if worker.get("terminal"):
            self.check(bool(SHA.fullmatch(str(worker.get("structuralTraceSha256", "")))), where, "missing terminal structural trace digest")
            self.check(sum(worker.get("stageCounts", {}).values()) == worker.get("observerEvents"),
                       where, "observer count differs from stage-count total")
        output["construction"] = self.phases(rows, is_complete, where)
        output["measurements"] = self.measurements(rows, where)
        validated = any(r["stage"] == "validated" for r in rows)
        if validated or is_complete:
            self.check(worker.get("checkedDefinitions") == 12456 and worker.get("eventsFullyValidated") == 13050,
                       where, "canonical full validation not evidenced")
        output["validation"] = {"checkedDefinitions": worker.get("checkedDefinitions"),
                                "bookEvents": worker.get("eventsFullyValidated"), "observedValidatedBoundary": validated}
        lane = self.plan["lanes"][spec["source"]]
        allowed = {str(Path(p["path"]).resolve()) for p in lane["inputs"]}
        loaded = worker.get("loadedInputs", [])
        self.check(len(loaded) == len(set(loaded)) and set(loaded) <= allowed, where, "loaded source outside authenticated lane")
        if validated:
            self.check({str(Path(lane[k]).resolve()) for k in ("root", "bridge")} <= set(loaded),
                       where, "validated worker missing root/bridge loading evidence")
        actual = worker.get("output")
        if actual:
            self.check(actual.get("path") == str(report_path) + ".c", where, "actual C path mismatch")
            output["actualC"] = self.pin(actual, where + "/C")
        if is_complete:
            self.check(worker.get("phase") == "complete", where, "complete worker phase mismatch")
            published = next((r for r in rows if r["stage"] == "c-published"), {})
            self.check(published.get("state", {}).get("bytes") == actual["bytes"], where, "published byte count differs")
            for stage in ("c-ids-after", "c-reset-after", "compile-return"):
                row = next((r for r in rows if r["stage"] == stage), {})
                self.check(row.get("state", {}).get("outputUTF16Units") == actual.get("utf16Units"),
                           where, "output UTF-16 length differs at " + stage)
            if spec["source"] == "R12":
                equal = byte_equal(actual["path"], self.plan["acceptedC"]["path"])
                self.check(actual["sha256"] == ACCEPTED_C and actual["bytes"] == self.accepted["bytes"] and equal,
                           where, "R12 actual C differs from accepted byte authority")
                self.check(worker.get("expectedAcceptedC") == {"sha256": ACCEPTED_C, "matches": True},
                           where, "R12 accepted-C claim mismatch")
                output["acceptedCByteIdentical"] = equal
            else:
                self.check(worker.get("expectedAcceptedC") is None, where, "G39 has unexpected R12 equality claim")
        output["verifiedCompleteCConstruction"] = is_complete and len(self.errors) == before_errors
        if not is_complete:
            output["failureAttribution"] = {
                "guardianReason": guard["reason"], "workerReason": worker.get("reason"),
                "lastCompletedBoundary": key(progress["lastCompletedBoundary"]),
                "lastRecordedProgressKey": last, "lastRecordedBeforeKey": progress["lastBeforeKey"],
                "scope": "Latest observed key only; no fabricated later-stage completion or causal allocation attribution."}

    def run_all(self):
        self.plan_path = self.experiment / "plan.json"
        self.plan = load_json(self.plan_path)
        self.plan_hash = digest(self.plan_path)
        self.result["plan"] = {"path": str(self.plan_path), **self.plan_hash}
        self.authenticate()
        receipt_path = self.run / "receipt.json"
        self.receipt = load_json(receipt_path)
        self.result["runnerReceipt"] = {"path": str(receipt_path), **digest(receipt_path)}
        receipt = self.receipt
        self.check(receipt.get("allCellsExecuted") is True and receipt.get("status") in
                   ("COMPLETE_FULL_CONSTRUCTION_MATRIX", "COMPLETE_MATRIX_WITH_FAILED_CELLS"),
                   "runner", "runner not settled; do not verify a running experiment")
        if receipt.get("allCellsExecuted") is not True:
            return
        self.check(receipt.get("plan") == {"path": str(self.plan_path), "sha256": self.plan_hash["sha256"]},
                   "runner", "plan pin mismatch")
        self.check(receipt.get("guard") == GUARD, "runner", "guard settings mismatch")
        self.check(receipt.get("diagnosticOnly") is True and all(receipt.get(k) is False for k in
                   ("compilerAccepted", "performanceAccepted", "newFixedpointClaim")), "runner", "nonclaim flags mismatch")
        self.smoke(receipt)
        cells = receipt.get("cells", [])
        self.check([c.get("id") for c in cells] == [c["id"] for c in CASES], "runner", "four distinct cells missing/reordered")
        for spec in CASES:
            matches = [c for c in cells if c.get("id") == spec["id"]]
            if len(matches) != 1:
                continue
            try:
                self.cell(matches[0], spec)
            except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
                self.check(False, spec["id"], type(error).__name__ + ": " + str(error))
        pairs = {}
        for source in ("R12", "G39"):
            pair = [next((c for c in self.result["cells"] if c["id"] == source + "_" + hint), None)
                    for hint in ("hint", "unset")]
            comparable = all(c and c.get("verifiedCompleteCConstruction") for c in pair)
            entry = {"comparable": comparable, "byteIdentical": None}
            if comparable:
                a, b = (c["actualC"] for c in pair)
                entry.update({"byteIdentical": byte_equal(a["path"], b["path"]),
                              "hint": {k: a[k] for k in ("sha256", "bytes")},
                              "unset": {k: b[k] for k in ("sha256", "bytes")}})
                self.check(entry["byteIdentical"] == (a["sha256"] == b["sha256"] and a["bytes"] == b["bytes"]),
                           source, "stream equality and digest/size disagree")
                self.check(receipt.get("sameSourceOutputEquality", {}).get(source) ==
                           {"comparable": True, "byteIdentical": entry["byteIdentical"]}, source, "runner pair equality differs")
            else:
                entry["reason"] = "Both cells must independently verify complete; partial output is not comparable acceptance evidence."
            pairs[source] = entry
        self.result["sameSourceCByteComparison"] = pairs
        reported_all = all(c.get("status") == "COMPLETE_C_CONSTRUCTION" for c in cells) and len(cells) == 4
        self.check(receipt.get("status") == ("COMPLETE_FULL_CONSTRUCTION_MATRIX" if reported_all else "COMPLETE_MATRIX_WITH_FAILED_CELLS"),
                   "runner", "matrix status inconsistent with cells")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path)
    parser.add_argument("experiment", type=Path)
    parser.add_argument("output_json", type=Path)
    args = parser.parse_args()
    if args.output_json.exists():
        parser.error("OUTPUT_JSON already exists; choose a fresh output (no evidence overwrite)")
    verifier = Verifier(args.repo.absolute(), args.experiment.absolute())
    try:
        verifier.run_all()
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        verifier.check(False, "verification", type(error).__name__ + ": " + str(error))
    result = verifier.result
    result["errors"], result["warnings"] = verifier.errors, verifier.warnings
    result["evidenceVerified"] = not verifier.errors
    result["status"] = "EVIDENCE_INVALID" if verifier.errors else "VERIFIED_DIAGNOSTIC_EVIDENCE"
    result["allFourCompleteCConstruction"] = (not verifier.errors and len(result["cells"]) == 4 and
                                               all(c.get("verifiedCompleteCConstruction") for c in result["cells"]))
    result["allFourEnvironmentsVerified"] = (not verifier.errors and len(result["cells"]) == 4 and
                                             all(c.get("environmentVerified") for c in result["cells"]))
    result["verifier"] = {"path": str(Path(__file__).absolute()), **digest(__file__),
                          "chunkBytes": CHUNK, "jsonMetadataCapBytes": JSON_LIMIT,
                          "jsonlRecordCapBytes": LINE_LIMIT, "boundaryCountCap": BOUNDARY_LIMIT}
    with args.output_json.open("x", encoding="utf-8") as stream:
        json.dump(result, stream, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)
        stream.write("\n")
    print(json.dumps({"status": result["status"], "errors": len(verifier.errors),
                      "allFourCompleteCConstruction": result["allFourCompleteCConstruction"],
                      "output": str(args.output_json)}, sort_keys=True))
    return 1 if verifier.errors else 0


if __name__ == "__main__":
    sys.exit(main())
