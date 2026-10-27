#!/usr/bin/env bash
# finalg — formal proof runner (moon prove + Why3 + Z3/cvc5)
#
# Imported from algo/moon-algebra; paths below are rebased to the golden
# repository root and the `finalg/` namespace.  This script is not part of
# the current compile-only gate: run it only in an environment with why3,
# z3 and cvc5 installed, and only when proof execution is requested.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.moon/bin:$PATH"
export MOON_PROVE_PRELUDE_OVERRIDE="$PWD/finalg/prelude"
# The imported Why3 config was generated with a literal /home/user prefix.
# Rebase that prefix to the invoking user's home in a temporary copy rather
# than editing the checked-in provenance asset in place.
why3_conf="$(mktemp)"
trap 'rm -f "$why3_conf"' EXIT
sed "s#/home/user#$HOME#g" "$PWD/finalg/why3-user.conf" > "$why3_conf"
exec moon prove finalg/verify --why3-config "$why3_conf" "$@"
