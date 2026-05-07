#!/usr/bin/env bats

setup() {
  TMP="$(mktemp -d)"
  cp "$BATS_TEST_DIRNAME/../fixtures/pixi.toml" "$TMP/pixi.toml"
  SCRIPT="$BATS_TEST_DIRNAME/../../scripts/bump-pixi-version.sh"
}

teardown() { rm -rf "$TMP"; }

@test "bumps package.version in place" {
  run "$SCRIPT" "$TMP/pixi.toml" '1.2.3'
  [ "$status" -eq 0 ]
  run grep -E '^version = "1\.2\.3"$' "$TMP/pixi.toml"
  [ "$status" -eq 0 ]
}

@test "preserves the schema directive comment" {
  "$SCRIPT" "$TMP/pixi.toml" '1.2.3'
  run grep -E '^#:schema https://example\.com/schema\.json$' "$TMP/pixi.toml"
  [ "$status" -eq 0 ]
}

@test "preserves trailing comments and other tables" {
  "$SCRIPT" "$TMP/pixi.toml" '1.2.3'
  run grep -E 'Important: trailing comment must survive the bump' "$TMP/pixi.toml"
  [ "$status" -eq 0 ]
  run grep -E '^\[package\.run-dependencies\]$' "$TMP/pixi.toml"
  [ "$status" -eq 0 ]
}

@test "fails on usage error" {
  run "$SCRIPT" only-one-arg
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage:"* ]]
}
