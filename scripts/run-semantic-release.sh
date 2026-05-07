#!/usr/bin/env bash
# Runs semantic-release for a package and emits step outputs:
#   released   — "true" or "false"
#   version    — semver string (only if released=true)
#   tag        — "<pkg>@<ver>" (only if released=true)
#   sha        — SHA of the tagged commit (only if released=true)
#
# Required env: PACKAGE, PACKAGE_PATH, RELEASE_TOOLING_DIR, GITHUB_OUTPUT.
# Required tools on PATH: node, npm, git, toml (toml-cli), jq.
set -euo pipefail

: "${PACKAGE:?required}"
: "${PACKAGE_PATH:?required}"
: "${RELEASE_TOOLING_DIR:?required}"
: "${GITHUB_OUTPUT:?required}"

if [ ! -f "${PACKAGE_PATH}/pixi.toml" ]; then
  echo "::error::pixi.toml not found at ${PACKAGE_PATH}"
  exit 1
fi

# semantic-release reads release.config.js from cwd by default; --extends
# lets us point at the checked-in copy in the tooling repo.
"${RELEASE_TOOLING_DIR}/node_modules/.bin/semantic-release" \
  --extends "./${RELEASE_TOOLING_DIR}/release.config.js" \
  | tee semantic-release.log

version="$(grep -oE 'Published release [0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?' \
             semantic-release.log | awk '{print $3}' | tail -n1 || true)"

if [ -z "$version" ]; then
  echo "no release published"
  echo "released=false" >> "$GITHUB_OUTPUT"
  exit 0
fi

tag="${PACKAGE}@${version}"
sha="$(git rev-list -n1 "$tag")"

{
  echo "released=true"
  echo "version=$version"
  echo "tag=$tag"
  echo "sha=$sha"
} >> "$GITHUB_OUTPUT"
