#!/usr/bin/env bash
# Bumps the [package].version field of a pixi.toml in place.
#
# Usage: bump-pixi-version.sh <pixi-toml-path> <new-version>
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $(basename "$0") <pixi-toml-path> <new-version>" >&2
  exit 64
fi

target="$1"
version="$2"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

toml set "$target" 'package.version' "$version" > "$tmp"
mv "$tmp" "$target"
