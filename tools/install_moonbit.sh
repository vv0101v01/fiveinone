#!/bin/sh
# Verified Linux x86_64 MoonBit installation for CI and local reproduction.
# Versions and archive SHA-256 digests live in ../.moon-toolchain.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$ROOT"

if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
  echo "install_moonbit.sh currently supports Linux x86_64 only" >&2
  exit 2
fi

value() {
  key=$1
  sed -n "s/^${key}=//p" .moon-toolchain
}

release=$(value release)
bin_sha=$(value linux_x86_64_archive_sha256)
core_sha=$(value linux_core_archive_sha256)
[ -n "$release" ] && [ -n "$bin_sha" ] && [ -n "$core_sha" ] || {
  echo "Missing release/checksum entries in .moon-toolchain" >&2
  exit 2
}

MOON_HOME=${MOON_HOME:-"$HOME/.moon"}
export MOON_HOME
encoded_release=$(printf '%s' "$release" | sed 's/+/%2B/g')
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

bin_archive="$tmp/moonbit-linux-x86_64.tar.gz"
core_archive="$tmp/core.tar.gz"
curl -fsSL "https://cli.moonbitlang.com/binaries/$encoded_release/moonbit-linux-x86_64.tar.gz" -o "$bin_archive"
curl -fsSL "https://cli.moonbitlang.com/cores/core-$encoded_release.tar.gz" -o "$core_archive"
printf '%s  %s\n' "$bin_sha" "$bin_archive" | sha256sum --check --status || {
  echo "MoonBit archive SHA-256 mismatch" >&2
  exit 1
}
printf '%s  %s\n' "$core_sha" "$core_archive" | sha256sum --check --status || {
  echo "MoonBit core archive SHA-256 mismatch" >&2
  exit 1
}

mkdir -p "$MOON_HOME"
rm -rf "$MOON_HOME/lib/core" "$MOON_HOME/include"
tar -xzf "$bin_archive" -C "$MOON_HOME"
mkdir -p "$MOON_HOME/lib"
tar -xzf "$core_archive" -C "$MOON_HOME/lib"
find "$MOON_HOME/bin" -type f -exec chmod +x {} +
[ ! -f "$MOON_HOME/bin/internal/tcc" ] || chmod +x "$MOON_HOME/bin/internal/tcc"

PATH="$MOON_HOME/bin:$PATH" "$MOON_HOME/bin/moon" -C "$MOON_HOME/lib/core" bundle --warn-list -a --all
PATH="$MOON_HOME/bin:$PATH" "$MOON_HOME/bin/moon" -C "$MOON_HOME/lib/core" bundle --warn-list -a --target wasm-gc --quiet

PATH="$MOON_HOME/bin:$PATH" "$MOON_HOME/bin/moon" version
PATH="$MOON_HOME/bin:$PATH" "$MOON_HOME/bin/moonc" -v
