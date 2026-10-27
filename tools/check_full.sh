#!/bin/sh
# Deferred runtime gate: compile-only checks plus actual unit tests and
# executable smoke runs.
#
# The five-system integration stage preserves every test source but is
# compile-only by explicit owner instruction.  Refuse to execute any
# test/smoke program unless the future runtime stage is deliberately
# enabled with GOLDEN_RUN_TESTS=1.
set -eu

cd "$(dirname "$0")/.."
export PATH="$HOME/.moon/bin:$PATH"

if [ "${GOLDEN_RUN_TESTS:-0}" != "1" ]; then
  echo "check_full.sh is deferred: tests are preserved but not executed in the compile-only stage." >&2
  echo "Run 'sh tools/check_compile.sh' now, or set GOLDEN_RUN_TESTS=1 when the runtime stage is authorized." >&2
  exit 2
fi

sh tools/check_compile.sh
moon test --target wasm-gc --no-parallelize
moon test --target native --no-parallelize
moon run cmd/main
moon run cmd/showcase
moon run cmd/symdemo
moon run cmd/symbench
moon run cmd/catmath
