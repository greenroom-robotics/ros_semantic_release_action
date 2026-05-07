#!/usr/bin/env bash
# Fires repository_dispatch(event_type=package-released) at the recipes repo.
# Invoked by semantic-release's successCmd hook.
#
# Args: <version> <sha>
# Required env: PACKAGE, GITHUB_REPOSITORY, RECIPES_REPO, GH_TOKEN.
set -euo pipefail

gh api -X POST "/repos/${RECIPES_REPO}/dispatches" \
  -f event_type=package-released \
  -f "client_payload[package]=${PACKAGE}" \
  -f "client_payload[version]=$1" \
  -f "client_payload[source_repo]=${GITHUB_REPOSITORY}" \
  -f "client_payload[sha]=$2"
