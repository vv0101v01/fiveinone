#!/bin/sh
# Current fast gate: compile-only.
#
# The owner has explicitly deferred executing the (fully imported)
# test and smoke suites until a later instruction.  Until that stage,
# check_fast.sh is an alias for the compile-only gate so local work and
# CI cannot accidentally present unrun tests as passing tests.
set -eu

cd "$(dirname "$0")/.."
exec sh tools/check_compile.sh
