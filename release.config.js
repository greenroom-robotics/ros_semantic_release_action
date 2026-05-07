// semantic-release config for the reusable workflow.
//
// Runtime contract: semantic-release runs with cwd = the package directory.
// File paths in plugin configs are relative to cwd so semantic-release-monorepo's
// asset filter (which scopes paths to the package dir) leaves them intact.
// The bump and dispatch helpers live in the action checkout, so reference them
// via absolute paths built from GITHUB_WORKSPACE.
const path = require('path');

const pkg = process.env.PACKAGE;
const pkgPath = process.env.PACKAGE_PATH;
const repoRoot = process.env.GITHUB_WORKSPACE;
const toolingRel = process.env.RELEASE_TOOLING_DIR || '_release_tooling';
const manifestType = process.env.MANIFEST_TYPE || 'pixi.toml';

if (!pkg || !pkgPath || !repoRoot) {
  throw new Error('PACKAGE, PACKAGE_PATH, and GITHUB_WORKSPACE env vars are required');
}
if (!['pixi.toml', 'package.xml'].includes(manifestType)) {
  throw new Error(`MANIFEST_TYPE must be pixi.toml or package.xml, got: ${manifestType}`);
}

const tooling = path.join(repoRoot, toolingRel);

module.exports = {
  extends: 'semantic-release-monorepo',
  branches: ['main'],
  tagFormat: `${pkg}@\${version}`,
  plugins: [
    ['@semantic-release/commit-analyzer', { preset: 'conventionalcommits' }],
    ['@semantic-release/release-notes-generator', { preset: 'conventionalcommits' }],
    ['@semantic-release/changelog', { changelogFile: 'CHANGELOG.md' }],
    ['@semantic-release/exec', {
      prepareCmd: `${tooling}/scripts/bump-manifest.py ${manifestType} \${nextRelease.version}`,
      successCmd: `${tooling}/scripts/dispatch-release.sh \${nextRelease.version} \${nextRelease.gitHead}`,
    }],
    ['@semantic-release/git', {
      assets: [manifestType, 'CHANGELOG.md'],
      message: `chore(release): ${pkg}@\${nextRelease.version} [skip ci]\n\n\${nextRelease.notes}`,
    }],
    ['@semantic-release/github', {
      successComment: false,
      failComment: false,
      releasedLabels: false,
      addReleases: false,
    }],
  ],
};
