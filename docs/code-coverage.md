
## Code Coverage with Github Actions and Github Pages

An exciting new method to generate gcovr coverage reports without relying on Codecov.

![Screenshot of gcovr report](https://dl.cpp.al/misc/gcovr-example.png?)

## Instructions

Copy the file `.github/workflows/code-coverage.yml` from boost-ci into your Boost library repository.

Run the workflow at least once, which can be done [manually](https://docs.github.com/de/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).
This will create a branch called "code-coverage" to store reports.

Next, enable GitHub Pages. Go to https://github.com/ORGANIZATION/REPO/settings/pages and enable the new branch.  

The coverage will be hosted at https://ORGANIZATION.github.io/REPO

### Adding Coverage Badges to Your Project

To display coverage badges in your repository's README, use the following Markdown snippets. Replace `{organization}` with the github organization, `{branch}` with the branch name (e.g. `develop`, `master`) and `{repo}` with your repository name (e.g. `json`, `capy`).

**Available badges:**

| Badge | URL | Preview |
|-------|-----|---------|
| Lines | `https://{organization}.github.io/{repo}/{branch}/gcovr/badges/coverage-lines.svg` | [![Lines](https://boostorg.github.io/boost-ci/master/gcovr/badges/coverage-lines.svg)](https://boostorg.github.io/boost-ci/master/gcovr/index.html)
| Functions | `https://{organization}.github.io/{repo}/{branch}/gcovr/badges/coverage-functions.svg` | [![Functions](https://boostorg.github.io/boost-ci/master/gcovr/badges/coverage-functions.svg)](https://boostorg.github.io/boost-ci/master/gcovr/index.html)
| Branches | `https://{organization}.github.io/{repo}/{branch}/gcovr/badges/coverage-branches.svg` | [![Branches](https://boostorg.github.io/boost-ci/master/gcovr/badges/coverage-branches.svg)](https://boostorg.github.io/boost-ci/master/gcovr/index.html)


**Markdown to copy into your README:**

```markdown
[![Lines](https://{organization}.github.io/{repo}/{branch}/gcovr/badges/coverage-lines.svg)](https://{organization}.github.io/{repo}/{branch}/gcovr/index.html)
[![Functions](https://{organization}.github.io/{repo}/{branch}/gcovr/badges/coverage-functions.svg)](https://{organization}.github.io/{repo}/{branch}/gcovr/index.html)
[![Branches](https://{organization}.github.io/{repo}/{branch}/gcovr/badges/coverage-branches.svg)](https://{organization}.github.io/{repo}/{branch}/gcovr/index.html)
```

For example, boostorg/json on the `develop` branch:

```markdown
[![Lines](https://boostorg.github.io/json/develop/gcovr/badges/coverage-lines.svg)](https://boostorg.github.io/json/develop/gcovr/index.html)
[![Functions](https://boostorg.github.io/json/develop/gcovr/badges/coverage-functions.svg)](https://boostorg.github.io/json/develop/gcovr/index.html)
[![Branches](https://boostorg.github.io/json/develop/gcovr/badges/coverage-branches.svg)](https://boostorg.github.io/json/develop/gcovr/index.html)
```
