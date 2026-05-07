// semantic-release config for the reusable workflow.
//
// Runtime contract: semantic-release runs with cwd = the package directory
// (so semantic-release-monorepo can find the stub package.json there and
// scope commits to that path). Paths must be absolute so they don't
// depend on cwd. GITHUB_WORKSPACE is the source repo root on the runner.
const path = require('path');

const pkg = process.env.PACKAGE;
const pkgPath = process.env.PACKAGE_PATH;
const repoRoot = process.env.GITHUB_WORKSPACE;
const toolingRel = process.env.RELEASE_TOOLING_DIR || '_release_tooling';

if (!pkg || !pkgPath || !repoRoot) {
  throw new Error('PACKAGE, PACKAGE_PATH, and GITHUB_WORKSPACE env vars are required');
}

const pkgRoot = path.join(repoRoot, pkgPath);
const tooling = path.join(repoRoot, toolingRel);

module.exports = {
  extends: 'semantic-release-monorepo',
  branches: ['main'],
  tagFormat: `${pkg}@\${version}`,
  plugins: [
    ['@semantic-release/commit-analyzer', { preset: 'conventionalcommits' }],
    ['@semantic-release/release-notes-generator', { preset: 'conventionalcommits' }],
    ['@semantic-release/changelog', { changelogFile: `${pkgRoot}/CHANGELOG.md` }],
    ['@semantic-release/exec', {
      prepareCmd: `python -c "import tomlkit; p='${pkgRoot}/pixi.toml'; d=tomlkit.parse(open(p).read()); d['package']['version']='\${nextRelease.version}'; open(p,'w').write(tomlkit.dumps(d))"`,
      successCmd: `${tooling}/scripts/dispatch-release.sh \${nextRelease.version} \${nextRelease.gitHead}`,
    }],
    ['@semantic-release/git', {
      assets: [`${pkgRoot}/pixi.toml`, `${pkgRoot}/CHANGELOG.md`],
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
