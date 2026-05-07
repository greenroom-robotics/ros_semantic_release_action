#!/usr/bin/env bash
# Fires a repository_dispatch(event_type=package-released) at the recipes repo.
#
# Required env: PACKAGE, VERSION, SHA, SOURCE_REPO, RECIPES_REPO, GH_TOKEN.
set -euo pipefail

: "${PACKAGE:?required}"
: "${VERSION:?required}"
: "${SHA:?required}"
: "${SOURCE_REPO:?required}"
: "${RECIPES_REPO:?required}"
: "${GH_TOKEN:?required}"

payload="$(jq -n \
  --arg pkg "$PACKAGE" \
  --arg ver "$VERSION" \
  --arg src "$SOURCE_REPO" \
  --arg sha "$SHA" \
  '{package:$pkg, version:$ver, source_repo:$src, sha:$sha}')"

echo "Dispatching to ${RECIPES_REPO}:"
echo "$payload"

gh api -X POST "/repos/${RECIPES_REPO}/dispatches" \
  -H 'Accept: application/vnd.github+json' \
  --input - <<EOF
{ "event_type": "package-released", "client_payload": $payload }
EOF
