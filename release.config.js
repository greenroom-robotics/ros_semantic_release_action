// semantic-release config for the reusable workflow.
// Reads runtime parameters from env vars set by the workflow.
const pkg = process.env.PACKAGE;
const pkgPath = process.env.PACKAGE_PATH;
const tooling = process.env.RELEASE_TOOLING_DIR || '_release_tooling';

if (!pkg || !pkgPath) {
  throw new Error('PACKAGE and PACKAGE_PATH env vars are required');
}

module.exports = {
  branches: ['main'],
  tagFormat: `${pkg}@\${version}`,
  plugins: [
    ['semantic-release-monorepo', { mainPackage: pkgPath }],
    ['@semantic-release/commit-analyzer', { preset: 'conventionalcommits' }],
    ['@semantic-release/release-notes-generator', { preset: 'conventionalcommits' }],
    ['@semantic-release/changelog', { changelogFile: `${pkgPath}/CHANGELOG.md` }],
    ['@semantic-release/exec', {
      prepareCmd: `${tooling}/scripts/bump-pixi-version.sh ${pkgPath}/pixi.toml \${nextRelease.version}`,
    }],
    ['@semantic-release/git', {
      assets: [`${pkgPath}/pixi.toml`, `${pkgPath}/CHANGELOG.md`],
      message: `chore(release): ${pkg}@\${nextRelease.version} [skip ci]\n\n\${nextRelease.notes}`,
    }],
    '@semantic-release/github',
  ],
};
