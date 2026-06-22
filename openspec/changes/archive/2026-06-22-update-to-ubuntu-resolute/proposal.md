## Why

Ubuntu 26.04 LTS (Resolute Raccoon) ships with sufficiently recent versions of all required packages: git 2.53.0, nginx 1.28.2, PostgreSQL 18, Node.js 22.x, redis-tools 8.0.5, supervisor 4.3.0. The current image adds five third-party apt repositories (git-core PPA, postgresql.org, nodesource, yarnpkg, nginx.org) to work around older package versions in noble (24.04). With 26.04, all five can be eliminated, reducing supply-chain surface and build complexity.

## What Changes

- Base image: `ubuntu:noble` → `ubuntu:resolute`
- Remove all third-party apt repository configuration (keys, sources, pin priorities)
- Remove `postgresql-client-17` from install list (Ubuntu 26.04 ships `postgresql-client-18`)
- Replace `yarn` apt package with `npm install -g yarn@1.22.22` (Ubuntu ships Yarn 4/Berry via `yarnpkg`; GitLab needs Yarn Classic)
- Add `npm` to apt install list (Ubuntu 26.04 ships it separately from `nodejs`)
- Replace `libncurses5-dev` with `libncurses-dev` (transitional package removed after 22.04)
- Update `Changelog.md` with the change

## Capabilities

### New Capabilities
- `base-image-resolute`: Ubuntu 26.04 Resolute Raccoon as base image with all packages from Ubuntu repositories only

### Modified Capabilities
<!-- No existing spec-level requirement changes -->

## Impact

- **Dockerfile**: FROM line, entire repo-addition RUN block, apt install list
- **assets/build/install.sh**: `libncurses5-dev` → `libncurses-dev`
- **Changelog.md**: new entry
- **Supply chain**: 5 external GPG keys + repos eliminated; all packages from Ubuntu main/universe
- **PostgreSQL**: pg-client-17 dropped; pg-client-18 (newer client) connects to pg-17 server (supported direction). Runtime prints WARNING for untested server versions — correct behavior preserved.
- **Yarn**: Yarn Classic 1.22.22 installed via npm instead of yarnpkg Debian repo. install.sh `yarn install --production --pure-lockfile` syntax unchanged.
