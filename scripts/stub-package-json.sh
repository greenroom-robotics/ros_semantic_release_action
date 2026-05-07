#!/usr/bin/env bash
# semantic-release-monorepo identifies the package by reading package.json from
# cwd. Source repos use pixi.toml (or package.xml) as their manifest — write a
# stub package.json inside the package dir at runtime so the wrapper resolves
# the right name. Never committed: each source repo's caller workflow owns this
# directory and the file is ephemeral on the runner.
#
# Required env: PACKAGE (bare package name), PACKAGE_PATH (path from repo root).
set -euo pipefail

dest="${PACKAGE_PATH}/package.json"
if [ ! -f "$dest" ]; then
  printf '{"name":"%s","private":true}\n' "$PACKAGE" > "$dest"
fi
