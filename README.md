# ROS Semantic Release Action

Build and release ROS packages with semantic versioning. Builds ARM and x86 packages and publishes to Greenroom's PPA.

## Quick Start

Use the reusable workflow for the simplest setup. Create `.github/workflows/release.yml`:

```yaml
name: Tag & Release

on:
  workflow_dispatch:
    inputs:
      package:
        type: choice
        options: ["", "package1", "package2"]
      build_jazzy:
        type: boolean
        default: true
      build_kilted:
        type: boolean
        default: true

jobs:
  release:
    uses: Greenroom-Robotics/ros_semantic_release_action/.github/workflows/release.yml@main
    with:
      package: ${{ github.event.inputs.package }}
      build_jazzy: ${{ github.event.inputs.build_jazzy == 'true' }}
      build_kilted: ${{ github.event.inputs.build_kilted == 'true' }}
    secrets:
      token: ${{ secrets.API_TOKEN_GITHUB }}
```

This handles the full pipeline: setup, matrix builds across architectures/distros, and release creation.

### Workflow Inputs

| Input              | Type    | Default                   | Description                                |
| ------------------ | ------- | ------------------------- | ------------------------------------------ |
| `package`          | string  | `''`                      | Package to release (empty = all)           |
| `package_dir`      | string  | `'packages'`              | Directory containing packages              |
| `build_kilted`     | boolean | `true`                    | Build for Kilted                           |
| `build_jazzy`      | boolean | `false`                   | Build for Jazzy                            |
| `build_iron`       | boolean | `true`                    | Build for Iron                             |
| `build_amd64`      | boolean | `true`                    | Build for amd64                            |
| `build_arm64`      | boolean | `true`                    | Build for arm64                            |
| `public`           | boolean | `false`                   | Publish to public PPA                      |
| `changelog`        | boolean | `false`                   | Generate changelog                         |
| `skip_tag`         | boolean | `false`                   | Skip git tag + GitHub release (another workflow owns tagging) |
| `gpu`              | boolean | `false`                   | Enable GPU support                         |
| `runner_amd64`     | string  | `'4vcpu-ubuntu-2404'`     | Runner for amd64 builds                    |
| `runner_arm64`     | string  | `'4vcpu-ubuntu-2404-arm'` | Runner for arm64 builds                    |
| `runner_release`   | string  | `'2vcpu-ubuntu-2404'`     | Runner for release job                     |
| `release_branches` | string  | `'main,master,alpha'`     | Branches to release from (comma-separated) |
| `ignore_packages`  | string  | `''`                      | Packages to ignore (see format below)      |

#### `ignore_packages` format

Comma-separated list of packages to exclude from builds by creating `COLCON_IGNORE` marker files:
- `pkg_name` — ignore for all distros
- `distro:pkg_name` — ignore only for specific distro (e.g., `iron:my_pkg`)

Example: `ignore_packages: 'legacy_pkg, iron:iron_incompatible_pkg, jazzy:experimental_pkg'`

## Direct Action Usage

For custom workflows, use the composite action directly. This is useful when you need QEMU emulation or custom build orchestration.

```yaml
- uses: Greenroom-Robotics/ros_semantic_release_action@main
  with:
    token: ${{ secrets.API_TOKEN_GITHUB }}
    package: my-package
    arch: amd64
    ros_distro: jazzy
```

### Action Inputs

| Input              | Default               | Description                                       |
| ------------------ | --------------------- | ------------------------------------------------- |
| `token`            | *required*            | GitHub token with packages and release API access |
| `package`          | `''`                  | Package to release (empty = all in package_dir)   |
| `package_dir`      | `'./'`                | Directory containing packages                     |
| `arch`             | `'amd64'`             | Architecture: `amd64` or `arm64`                  |
| `ros_distro`       | `'iron'`              | ROS 2 distro: `humble`, `iron`, `jazzy`, `kilted` |
| `public`           | `'false'`             | Publish to public PPA                             |
| `changelog`        | `'true'`              | Generate and commit changelog                     |
| `github_release`   | `'true'`              | Create GitHub release                             |
| `skip_tag`         | `'false'`             | Skip creating git tag                             |
| `skip_build`       | `'false'`             | Skip build (download artifacts instead)           |
| `gpu`              | `'false'`             | Enable GPU support in build                       |
| `release_branches` | `'main,master,alpha'` | Branches to release from                          |
| `cli_branch`       | `'main'`              | Branch of platform_cli to use                     |
| `secrets`          | `'{}'`                | JSON secrets to pass to docker build              |
