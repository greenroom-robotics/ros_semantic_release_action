#!/usr/bin/env python3
"""Self-check for write_docker_secrets.py: `python3 scripts/test_write_docker_secrets.py`"""

import json
import os
import tempfile
from pathlib import Path

from write_docker_secrets import InvalidSecrets, main, materialise

APT_CONF = "machine raw.githubusercontent.com/Greenroom-Robotics\nlogin tok\npassword\n"

with tempfile.TemporaryDirectory() as tmp:
    dest = Path(tmp) / "docker-secrets"
    dest.mkdir()
    paths = materialise({"API_TOKEN_GITHUB": "tok", "apt_conf": APT_CONF}, dest)

    assert Path(paths["API_TOKEN_GITHUB"]).read_text() == "tok"
    assert Path(paths["apt_conf"]).read_text() == APT_CONF, "newlines must survive"

    for bad in ("../escape", "a/b", "tok en"):
        try:
            materialise({bad: "x"}, dest)
            raise AssertionError(f"{bad!r} should be rejected")
        except InvalidSecrets:
            pass

    try:
        materialise({"num": 1}, dest)
        raise AssertionError("non-string value should be rejected")
    except InvalidSecrets:
        pass

with tempfile.TemporaryDirectory() as tmp:
    os.environ.update(
        RUNNER_TEMP=tmp,
        GITHUB_OUTPUT=f"{tmp}/output",
        DOCKER_SECRETS=json.dumps({"API_TOKEN_GITHUB": "tok"}),
        SECRETS=json.dumps({"apt_conf": "/pre/existing/path"}),
    )
    main()

    written = Path(f"{tmp}/output").read_text()
    secrets = json.loads(written.removeprefix("secrets_json=").strip())
    assert secrets["apt_conf"] == "/pre/existing/path", "paths must pass through"
    assert secrets["API_TOKEN_GITHUB"] == f"{tmp}/docker-secrets/API_TOKEN_GITHUB"
    assert "tok" not in written, "values must never reach the step output"

print("ok")
