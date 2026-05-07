// semantic-release config for the reusable workflow.
//
// Runtime contract: semantic-release runs with cwd = the package directory.
// File paths in plugin configs are relative to cwd so semantic-release-monorepo's
// asset filter (which scopes paths to the package dir) leaves them intact.
// The dispatch-release helper lives in the action checkout, so reference it
// via an absolute path built from GITHUB_WORKSPACE.
const path = require('path');

const pkg = process.env.PACKAGE;
const pkgPath = process.env.PACKAGE_PATH;
const repoRoot = process.env.GITHUB_WORKSPACE;
const toolingRel = process.env.RELEASE_TOOLING_DIR || '_release_tooling';

if (!pkg || !pkgPath || !repoRoot) {
  throw new Error('PACKAGE, PACKAGE_PATH, and GITHUB_WORKSPACE env vars are required');
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
      prepareCmd: `python -c "import tomlkit; d=tomlkit.parse(open('pixi.toml').read()); d['package']['version']='\${nextRelease.version}'; open('pixi.toml','w').write(tomlkit.dumps(d))"`,
      successCmd: `${tooling}/scripts/dispatch-release.sh \${nextRelease.version} \${nextRelease.gitHead}`,
    }],
    ['@semantic-release/git', {
      assets: ['pixi.toml', 'CHANGELOG.md'],
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
