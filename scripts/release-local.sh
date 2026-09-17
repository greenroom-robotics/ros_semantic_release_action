#!/usr/bin/env bash
# Local rehearsal of the deb build pipeline that the release action runs in CI.
#
# Runs `platform pkg build` directly on the host (no docker) so iteration is
# fast and resource throttling is straightforward. Mirrors what semantic-release's
# prepareCmd does in CI (release.py:179) minus tagging, changelog, github release,
# and apt publish. Auto-restores package.xml and removes bloom build artifacts.
#
# Usage:
#   release-local.sh <repo-path> --package <name> [options]
#
# Options:
#   --package <name>        (required) Package to build
#   --package-dir <dir>     Package dir relative to repo (default: ./)
#   --ros-distro <distro>   ROS distro to source (default: kilted)
#   --parallel <N>          debhelper parallelism cap (default: cpu count)
#   --make-jobs <N>         per-package MAKEFLAGS=-jN cap (default: unset)
#   --keep-artifacts        skip cleanup of debian/, obj-*/, package.xml restore
#
# Prereqs on host:
#   - python3-bloom, fakeroot, dh-make, debhelper (apt)
#   - ROS distro at /opt/ros/<distro> (apt or sourced workspace)
#   - platform_cli with throttle flags:
#       pip install git+https://github.com/Greenroom-Robotics/platform_cli.git@tenzinplatter/throttle-flags
#   - rosdeps installed for the package (run: platform pkg install-deps --package <name>)

set -euo pipefail

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

[[ $# -lt 1 ]] && usage 1
case "$1" in -h|--help) usage 0 ;; esac

repo_path="$(cd "$1" && pwd)"
shift

package=""
package_dir="./"
ros_distro="kilted"
parallel=""
make_jobs=""
keep_artifacts=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) package="$2"; shift 2 ;;
    --package-dir) package_dir="$2"; shift 2 ;;
    --ros-distro) ros_distro="$2"; shift 2 ;;
    --parallel) parallel="$2"; shift 2 ;;
    --make-jobs) make_jobs="$2"; shift 2 ;;
    --keep-artifacts) keep_artifacts=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown arg: $1" >&2; usage 1 ;;
  esac
done

[[ -z "$package" ]] && { echo "--package is required" >&2; exit 1; }

# Resolve package path. Search package_dir for a package.xml whose <name> matches.
pkg_path=""
while IFS= read -r -d '' candidate; do
  name="$(sed -n 's|.*<name>\s*\([^<]*\)\s*</name>.*|\1|p' "$candidate" | head -n1)"
  if [[ "$name" == "$package" ]]; then
    pkg_path="$(dirname "$candidate")"
    break
  fi
done < <(find "$repo_path/$package_dir" -name package.xml -not -path '*/install/*' -not -path '*/build/*' -print0)

if [[ -z "$pkg_path" ]]; then
  echo "Could not find package '$package' under $repo_path/$package_dir" >&2
  exit 1
fi

# Tool checks
missing=()
command -v platform >/dev/null || missing+=("platform_cli (pip install git+https://github.com/Greenroom-Robotics/platform_cli.git@tenzinplatter/throttle-flags)")
command -v bloom-generate >/dev/null || missing+=("bloom (sudo apt install python3-bloom)")
command -v fakeroot >/dev/null || missing+=("fakeroot (sudo apt install fakeroot)")
[[ -f "/opt/ros/$ros_distro/setup.bash" ]] || missing+=("ROS $ros_distro at /opt/ros/$ros_distro")
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing prerequisites:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

# Confirm patched CLI is in use
if ! platform pkg build --help 2>&1 | grep -q '\-\-parallel'; then
  echo "platform_cli is installed but lacks --parallel flag." >&2
  echo "Reinstall from the patched branch:" >&2
  echo "  pip install --force-reinstall git+https://github.com/Greenroom-Robotics/platform_cli.git@tenzinplatter/throttle-flags" >&2
  exit 1
fi

echo ">>> Local host-mode deb build"
echo "    repo:        $repo_path"
echo "    package:     $package"
echo "    pkg_path:    $pkg_path"
echo "    ros_distro:  $ros_distro"
echo "    parallel:    ${parallel:-<cpu count>}"
echo "    make_jobs:   ${make_jobs:-<unset>}"
echo

# Snapshot package.xml so we can restore the version mutation `pkg build` does.
pkg_xml="$pkg_path/package.xml"
pkg_xml_backup="$(mktemp)"
cp "$pkg_xml" "$pkg_xml_backup"

cleanup() {
  local rc=$?
  if [[ "$keep_artifacts" -eq 1 ]]; then
    echo ">>> --keep-artifacts: leaving build dir as-is" >&2
    rm -f "$pkg_xml_backup"
    exit $rc
  fi
  echo ">>> Cleaning up build artifacts in $pkg_path"
  # Restore the original package.xml (pkg build sed-replaces <version>)
  if [[ -f "$pkg_xml_backup" ]]; then
    cp "$pkg_xml_backup" "$pkg_xml"
    rm -f "$pkg_xml_backup"
  fi
  # Remove bloom + debhelper build leftovers from the package dir
  rm -rf "$pkg_path/debian" "$pkg_path/.obj-"* "$pkg_path"/obj-*-linux-gnu 2>/dev/null || true
  # Remove any stray .deb/.ddeb/.buildinfo/.changes that landed in the parent
  # before pkg build moved them; pkg build moves into <pkg>/debs/ so parent should be clean.
  find "$(dirname "$pkg_path")" -maxdepth 1 \
    \( -name '*.buildinfo' -o -name '*.changes' -o -name '*.dsc' -o -name '*.tar.gz' -o -name '*.tar.xz' \) \
    -delete 2>/dev/null || true
  exit $rc
}
trap cleanup EXIT INT TERM

# Source ROS, then drive the build via platform_cli.
build_args=(--version 0.0.0-local --output debs)
[[ -n "$parallel" ]] && build_args+=(--parallel "$parallel")
[[ -n "$make_jobs" ]] && build_args+=(--make-jobs "$make_jobs")

cd "$pkg_path"

# shellcheck disable=SC1090
source "/opt/ros/$ros_distro/setup.bash"

platform pkg build "${build_args[@]}"

echo
echo ">>> Built artifacts:"
find "$pkg_path/debs" -maxdepth 1 \( -name '*.deb' -o -name '*.ddeb' \) -print | sort
