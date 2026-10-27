#!/bin/sh
# Compile-only gate for the five-system federation stage.
#
# Test and white-box test sources are part of the tree and are compiled
# with `moon test --build-only`; no test block, showcase, demo, report
# or other project executable is run by this script.  Executables are
# built, not launched.  Runtime test/smoke gates stay in check_full.sh
# and check_slow.sh behind their explicit opt-in environment switches.
set -eu

cd "$(dirname "$0")/.."
export PATH="$HOME/.moon/bin:$PATH"

moon fmt --check
moon info
if [ -d .git ]; then
  git diff --exit-code -- ':(glob)**/pkg.generated.mbti' pkg.generated.mbti
fi
python3 tools/doc_check.py
python3 tools/arch_check.py
python3 tools/audit_spec.py --check
for target in wasm wasm-gc js native; do
  moon check --deny-warn --target "$target"
done

# Compile the complete test surface without executing any test block.
moon test --build-only --deny-warn --target wasm-gc
moon test --build-only --deny-warn --target native

# Compile portable executables and the native-only measured report.
moon build --deny-warn --target wasm-gc \
  cmd/main \
  cmd/showcase \
  cmd/symdemo \
  cmd/symbench \
  cmd/catmath
moon build --deny-warn --target native cmd/semiringreport
