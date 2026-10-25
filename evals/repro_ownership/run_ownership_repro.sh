#!/bin/sh
# Focused ownership repro driver. MUST run as the command of the repaired
# evals/heavy_gate.ts lane; it refuses to start without that authenticated
# lease so no compiler, clang or C run happens unguarded.
#
# TARGET=c  (default) emit C, clang, run each witness; prints exact H_BUMP
#           page readings around each measurement window.
# TARGET=js emit JS and run it with node: same source, values only.
#
# Required environment (literal values are in the READY message):
#   CANDIDATE CANDIDATE_HOST PARSER BASE RUNTIME_C NODE OUT
# Optional: TARGET, CASES (default "own_cons own_rebox"), CC (default clang).
# The whole-parent value witness is opt-in: CASES=alias_whole_parent.
#
# There is exactly one deadline mechanism: the outer evals/heavy_gate.ts
# guardian (600 s, whole owned process tree). This script adds no timeout
# wrapper, no lock and no process-group engine of its own. Raw stdout/stderr
# are kept whole, never filtered. If the guardian stops the tree mid-stage,
# the finished stages keep their exit rows and the interrupted stage has none.
set -eu
: "${HEAVY_GATE_LEASE_TOKEN:?run under evals/heavy_gate.ts: lease missing}"
: "${CANDIDATE:?}" "${CANDIDATE_HOST:?}" "${PARSER:?}" "${BASE:?}" "${RUNTIME_C:?}" "${NODE:?}" "${OUT:?}"
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TARGET=${TARGET:-c}
CASES=${CASES:-own_cons own_rebox}
CC=${CC:-clang}
if command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$1"; }
elif command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$1"; }
else
  printf 'missing sha256 tool (shasum or sha256sum)\n' >&2
  exit 64
fi
mkdir -p "$OUT"
: >"$OUT/exits.tsv"
: >"$OUT/commands.txt"
: >"$OUT/hashes.txt"
overall=0

step() { # label command...
  label=$1
  shift
  printf '%s\n' "$*" >>"$OUT/commands.txt"
  if "$@" >"$OUT/$label.stdout" 2>"$OUT/$label.stderr"; then
    printf '%s\t0\n' "$label" >>"$OUT/exits.tsv"
  else
    code=$?
    printf '%s\t%s\n' "$label" "$code" >>"$OUT/exits.tsv"
    overall=1
  fi
}

exit_of() { # label
  awk -F '\t' -v want="$1" '$1 == want { print $2 }' "$OUT/exits.tsv"
}

hash_input() { # label path
  label=$1
  path=$2
  if [ -f "$path" ]; then
    digest=$(sha256 "$path" | awk '{print $1}')
    printf '%s\t%s\t%s\n' "$label" "$digest" "$path" >>"$OUT/hashes.txt"
  else
    printf '%s\tMISSING\t%s\n' "$label" "$path" >>"$OUT/hashes.txt"
  fi
}

hash_input candidate "$CANDIDATE"
hash_input candidate_host "$CANDIDATE_HOST"
hash_input parser "$PARSER"
hash_input base "$BASE"
hash_input runtime_c "$RUNTIME_C"
hash_input driver "$HERE/run_ownership_repro.sh"

emit() { # name src out
  name=$1
  src=$2
  out=$3
  step "emit-$name" "$NODE" --experimental-strip-types \
    --max-old-space-size=3072 "$CANDIDATE_HOST" --candidate="$CANDIDATE" \
    --parser="$PARSER" --source-tag=../bend2/selfhost/backend_ir.SourceFile \
    "$src" -o "$out" --base="$BASE" --runtime-c="$RUNTIME_C"
  hash_input "emit-$name" "$out"
}

for name in $CASES; do
  src="$HERE/$name.bend"
  hash_input "source-$name" "$src"
  if [ "$TARGET" = c ]; then
    c="$OUT/$name.c"
    bin="$OUT/$name.cbin"
    emit "$name" "$src" "$c"
    if [ "$(exit_of "emit-$name")" = 0 ] && [ -s "$c" ]; then
      step "clang-$name" "$CC" -std=c11 -O0 -ferror-limit=0 \
        -pthread -lm -o "$bin" "$c"
      hash_input "binary-$name" "$bin"
      if [ "$(exit_of "clang-$name")" = 0 ] && [ -x "$bin" ]; then
        step "run-$name" "$bin"
      fi
    fi
  elif [ "$TARGET" = js ]; then
    js="$OUT/$name.js"
    emit "$name" "$src" "$js"
    if [ "$(exit_of "emit-$name")" = 0 ] && [ -s "$js" ]; then
      step "run-$name" "$NODE" "$js"
    fi
  else
    printf 'unknown TARGET %s\n' "$TARGET" >&2
    exit 64
  fi
done

printf 'REPRO_OWNERSHIP target=%s status=%s out=%s\n' "$TARGET" \
  "$([ "$overall" = 0 ] && echo complete || echo failed)" "$OUT"
exit "$overall"
