#!/usr/bin/env bash
# Sets the global git user.name/user.email to the GitHub App bot identity, so
# commits made by semantic-release (and any other git ops in this job) are
# attributed to the App that minted our token.
#
# Required env: GH_TOKEN (App-installation token), SLUG (App slug, e.g. from
# create-github-app-token's `app-slug` output).
set -euo pipefail

USER_ID=$(gh api "/users/${SLUG}[bot]" --jq .id)
git config --global user.name "${SLUG}[bot]"
git config --global user.email "${USER_ID}+${SLUG}[bot]@users.noreply.github.com"
