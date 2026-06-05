#!/usr/bin/env bash
# Resolves the latest release tag for ${PACKAGE} (format <pkg>@X.Y.Z, ignoring
# per-arch tags like <pkg>@X.Y.Z-amd64) and fires the package-released
# repository_dispatch for it via dispatch-release.sh.
#
# For release workflows that tag via the composite action instead of the
# recipes-release reusable workflow (which dispatches from semantic-release's
# successCmd). Idempotent: re-dispatching an already-bumped version no-ops in
# the recipes repo (bump route leaves the recipe unchanged, open-pr stages
# nothing and exits).
#
# Required env: PACKAGE, PACKAGE_PATH, MANIFEST_TYPE, GITHUB_REPOSITORY,
#               RECIPES_REPO, GH_TOKEN.
set -euo pipefail

git fetch --tags --quiet

# `|| true`: under pipefail a no-match grep would kill the script here,
# skipping the explicit error below.
tag=$(git tag --list "${PACKAGE}@*" --sort=-v:refname \
  | grep -E "^${PACKAGE}@[0-9]+\.[0-9]+\.[0-9]+$" | head -n 1 || true)

if [ -z "${tag}" ]; then
  echo "::error::no release tag found matching ${PACKAGE}@X.Y.Z" >&2
  exit 1
fi

version="${tag#"${PACKAGE}"@}"
sha=$(git rev-list -n 1 "${tag}")

echo "::notice::dispatching ${PACKAGE}@${version} (${sha})"
exec "$(dirname "$0")/dispatch-release.sh" "${version}" "${sha}"
