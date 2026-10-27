#!/bin/sh
# Deferred slow smoke gate: regenerate the semiring measurement report.
#
# In the compile-only federation stage this script only builds the
# native report executable.  Set GOLDEN_RUN_SMOKE=1 in the future
# runtime stage to execute it:
#   GOLDEN_RUN_SMOKE=1 sh tools/check_slow.sh > /tmp/REPORT.generated.md
# semiring/REPORT.md also has a short manual snapshot banner, so do
# not overwrite it blindly; compare the generated body and retain it.
set -eu

cd "$(dirname "$0")/.."
export PATH="$HOME/.moon/bin:$PATH"

if [ "${GOLDEN_RUN_SMOKE:-0}" != "1" ]; then
  moon build --deny-warn --target native cmd/semiringreport
  echo "check_slow.sh: built cmd/semiringreport only; report execution is deferred." >&2
  exit 0
fi

moon run cmd/semiringreport --target native
