#!/usr/bin/env bash
# Bumps the [package].version field of a pixi.toml in place.
# Usage: bump-pixi-version.sh <pixi-toml-path> <new-version>
set -euo pipefail
toml set "$1" 'package.version' "$2" > "$1.new"
mv "$1.new" "$1"
