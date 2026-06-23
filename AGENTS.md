# AGENTS.md

This repo packages GitLab CE into a Docker image. It is **not** the GitLab application code — there is no test suite, no app to lint/typecheck. The "source" is shell scripts that clone, build, and configure upstream GitLab components at image build time.

## What lives where

- `Dockerfile` — pins all upstream versions + sha256 checksums, installs apt deps, runs `assets/build/install.sh`, then layers `assets/runtime/` + `entrypoint.sh`.
- `assets/build/install.sh` — build-time: clones `gitlab-foss@v${GITLAB_VERSION}`, builds gitlab-shell, gitlab-pages, gitaly, gitlab-workhorse, runs `bundle install` (deployment mode, without `development test mysql aws`), compiles assets via `rake gitlab:assets:compile`, writes supervisord program configs.
- `assets/build/patches/gitlabhq/` — `.patch` files applied to gitlab-foss after clone. (Ruby patches were removed when Ruby switched to prebuilt binaries — do not re-add a `patches/ruby/` dir.)
- `assets/runtime/functions` (~85KB) + `assets/runtime/env-defaults` (~38KB) — sourced by `entrypoint.sh`; all runtime config is env-var driven and documented there and in `README.md`. Key functions: `initialize_system`, `configure_gitlab`, `configure_gitlab_shell`, `configure_gitlab_pages`, `configure_nginx`, `migrate_database`, `execute_raketask`, `sanitize_datadir`.
- `entrypoint.sh` — dispatches `app:start` (default), `app:init`, `app:sanitize`, `app:rake <task>`, `app:help`. Any other arg is `exec`'d.
- `VERSION` — single line, the GitLab CE version (`19.1.0`). Read by `Makefile` release target and CI.

## Commands

- `make build` — build `sameersbn/gitlab` (slow: compiles Go components + `bundle install` + asset compile; expect 10+ min).
- `make release` — build `sameersbn/gitlab:$(cat VERSION)`.
- `make quickstart` / `make stop` / `make purge` / `make logs` — three-container demo (gitlab + postgresql + redis).
- No `test` / `lint` / `typecheck` targets. Verification is:
  - `docker build --check .` — Dockerfile syntax/lint.
  - `shellcheck assets/build/install.sh assets/runtime/functions entrypoint.sh` — shell integrity.
  - A full functional check requires actually building the image and running it (e.g. `make quickstart` then hit `http://localhost:10080`).

## Upgrading versions (the easy way to break the build)

All upstream artifacts are pinned with sha256 checksums that are **verified at build time** via `sha256sum -c -`. When bumping a version you MUST update both the version ENV and its `*_SHA256SUM` in the `Dockerfile` ENV block, or the build fails the checksum check.

Versions in the Dockerfile ENV block:

- `GITLAB_VERSION` (also update `VERSION` file) — gitlab-foss tag.
- `GITLAB_SHELL_VERSION`, `GITLAB_PAGES_VERSION`, `GITALY_SERVER_VERSION` — usually bumped together with GitLab.
- `RUBY_VERSION` + `RUBY_PREBUILT_REVISION` + `RUBY_PREBUILT_SHA256SUM` — prebuilt binary from `jdx/ruby` GitHub releases.
- `GOLANG_VERSION` + `GOLANG_SOURCE_SHA256SUM` — from `go.dev/dl`.
- `RUBYGEMS_VERSION`.

Always add a `Changelog.md` entry under the version heading using the existing component-prefix style (`gitlab:`, `gitaly:`, `gitlab-pages:`, `ruby:`, `ubuntu:`, `packages:`, etc.).

## Toolchain quirks (don't undo these)

- Base image is `ubuntu:resolute` (26.04). All apt packages come from Ubuntu repos only — third-party apt repos (git-core PPA, postgresql.org, nodesource, yarnpkg, nginx.org) were deliberately removed for supply-chain hygiene. Don't re-add them.
- Yarn Classic 1.22.22 is installed via `npm install -g yarn@1.22.22` (the Ubuntu `yarnpkg` package ships Yarn 4/Berry, which GitLab does not use). Install command is `yarn install --production --pure-lockfile`.
- Ruby is a prebuilt binary extracted to `/usr/local`, not compiled. rdoc/ri are stripped.
- PostgreSQL client is `postgresql-client-18`; server minimum is 17 (GitLab 19.0+ requirement, `POSTGRESQL_SERVER_REQUIRED_VERSION_MINIMUM=170000`).
- `DEBUG=true` enables `set -x` in the entrypoint for runtime troubleshooting.

## OpenSpec spec-driven workflow

This repo uses OpenSpec (`openspec/`, `schema: spec-driven`). Repo-local skills are installed under `.opencode/skills/` (openspec-propose, openspec-apply-change, openspec-archive-change, openspec-sync-specs, openspec-explore) and require the `openspec` CLI.

- Propose a change → `openspec/changes/<YYYY-MM-DD-slug>/` with `proposal.md`, `tasks.md`, optional `design.md`, and delta `specs/`.
- Implemented specs live in `openspec/specs/<capability>/spec.md`.
- Completed changes are moved to `openspec/changes/archive/`.
- Use the openspec skills for this workflow rather than improvising.

## CI

`.gitlab-ci.yml` (DinD, `docker:18-git`) builds on: `master` → tag `latest`; branches → tag `${slug}`; tags → tag `${VERSION}`. See `CONTRIBUTING.md` for registry variable overrides.
