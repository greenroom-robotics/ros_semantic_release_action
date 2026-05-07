#!/usr/bin/env python3
"""Bump the version field of a package manifest.

Run from cwd = the package directory (so semantic-release-monorepo's
relative-path filter is happy).

Usage:
    bump-manifest.py <pixi.toml|package.xml> <new-version>

The pixi.toml branch uses tomlkit (preserves comments + style).
The package.xml branch uses lxml only to validate structure, then a targeted
regex substitution to rewrite just the <version> element's text. This avoids
the formatting churn ElementTree/lxml's serializer would otherwise introduce
(processing instructions, declaration quoting, top-level whitespace).
"""
from __future__ import annotations

import sys
from pathlib import Path


def bump_pixi(new_version: str) -> None:
    import tomlkit

    path = Path("pixi.toml")
    doc = tomlkit.parse(path.read_text())
    doc["package"]["version"] = new_version
    path.write_text(tomlkit.dumps(doc))


def bump_package_xml(new_version: str) -> None:
    import re
    from lxml import etree

    path = Path("package.xml")
    tree = etree.parse(str(path))
    versions = tree.getroot().findall("version")
    if len(versions) != 1:
        raise SystemExit(
            f"package.xml must have exactly one <version> element, found {len(versions)}"
        )

    text = path.read_text()
    new_text, n = re.subn(
        r"(<version>)[^<]+(</version>)",
        rf"\g<1>{new_version}\g<2>",
        text,
        count=1,
    )
    if n != 1:
        raise SystemExit("failed to locate <version>...</version> in package.xml")
    path.write_text(new_text)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(
            f"usage: {Path(argv[0]).name} <pixi.toml|package.xml> <new-version>",
            file=sys.stderr,
        )
        return 64

    manifest_type, new_version = argv[1], argv[2]
    handlers = {"pixi.toml": bump_pixi, "package.xml": bump_package_xml}
    handler = handlers.get(manifest_type)
    if handler is None:
        print(
            f"unknown manifest_type: {manifest_type} (expected pixi.toml or package.xml)",
            file=sys.stderr,
        )
        return 64

    handler(new_version)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
