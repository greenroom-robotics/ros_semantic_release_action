#!/usr/bin/env bash
# Fires repository_dispatch(event_type=package-released) at the recipes repo.
# Invoked by semantic-release's successCmd hook.
#
# Args: <version> <sha>
# Required env: PACKAGE, PACKAGE_PATH, MANIFEST_TYPE, GITHUB_REPOSITORY,
#               RECIPES_REPO, GH_TOKEN.
set -euo pipefail

args=(
  -f event_type=package-released
  -f "client_payload[package]=${PACKAGE}"
  -f "client_payload[version]=$1"
  -f "client_payload[source_repo]=${GITHUB_REPOSITORY}"
  -f "client_payload[sha]=$2"
  -f "client_payload[manifest_type]=${MANIFEST_TYPE}"
)

# Only include subdir when the package isn't at the repo root — keeps single-
# package repo entries clean.
if [ "${PACKAGE_PATH}" != "." ] && [ -n "${PACKAGE_PATH}" ]; then
  args+=(-f "client_payload[subdir]=${PACKAGE_PATH}")
fi

gh api -X POST "/repos/${RECIPES_REPO}/dispatches" "${args[@]}"
