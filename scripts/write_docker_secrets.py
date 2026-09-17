#!/usr/bin/env python3
"""Materialise BuildKit secrets for the docker build.

DOCKER_SECRETS is a JSON object of secret id -> file contents. Each value is
written to its own file, and `secrets_json` maps the ids to those paths — the
form `platform release` turns into `docker buildx --secret id=...,src=...`.
Ids in SECRETS are already paths and pass through unchanged.
"""

import json
import os
import re
from pathlib import Path

VALID_ID = re.compile(r"^[A-Za-z0-9_.-]+$")


class InvalidSecrets(Exception):
    pass


def materialise(contents: dict[str, str], dest: Path) -> dict[str, str]:
    """Writes each secret to <dest>/<id>, returning the id -> path mapping."""
    paths = {}
    for secret_id, value in contents.items():
        # The id becomes a filename, so anything path-like has to be rejected.
        if not VALID_ID.fullmatch(secret_id):
            raise InvalidSecrets(f"invalid docker secret id: {secret_id!r}")
        if not isinstance(value, str):
            raise InvalidSecrets(f"docker secret {secret_id} must be a string")
        path = dest / secret_id
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as f:
            f.write(value)
        paths[secret_id] = str(path)
    return paths


def main() -> None:
    contents = json.loads(os.environ.get("DOCKER_SECRETS") or "{}")
    passthrough = json.loads(os.environ.get("SECRETS") or "{}")

    dest = Path(os.environ["RUNNER_TEMP"]) / "docker-secrets"
    dest.mkdir(parents=True, exist_ok=True)

    secrets = {**passthrough, **materialise(contents, dest)}

    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write(f"secrets_json={json.dumps(secrets)}\n")


if __name__ == "__main__":
    try:
        main()
    except InvalidSecrets as e:
        raise SystemExit(f"::error::{e}")
