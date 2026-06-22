# Base Image Resolute Specification

## Purpose

Defines the requirements for the Docker base image upgrade to Ubuntu 26.04 Resolute (LTS), including repository sourcing, package installation, and tooling compatibility.

## Requirements

### Requirement: Base image shall be Ubuntu 26.04 Resolute
The Dockerfile SHALL use `ubuntu:resolute` as the base image.

#### Scenario: Base image tag
- **WHEN** the Dockerfile is built
- **THEN** the base image SHALL be `ubuntu:resolute` (Ubuntu 26.04 LTS)

### Requirement: All packages shall come from Ubuntu repositories only
No third-party apt repositories, GPG keys, or pin priorities SHALL be configured. All packages SHALL be installed from Ubuntu main and universe repositories.

#### Scenario: No external repositories
- **WHEN** the image is built
- **THEN** no files SHALL exist under `/etc/apt/sources.list.d/` from git-core, postgresql.org, nodesource, yarnpkg, or nginx.org
- **AND** no files SHALL exist under `/etc/apt/keyrings/` from those sources
- **AND** no pin priorities SHALL exist under `/etc/apt/preferences.d/` for nginx

### Requirement: Yarn Classic SHALL be installed via npm
Yarn Classic (v1.x) SHALL be installed globally via `npm install -g yarn` to maintain compatibility with GitLab's `yarn install --production --pure-lockfile` syntax.

#### Scenario: Yarn Classic available
- **WHEN** the build completes
- **THEN** `yarn --version` SHALL report a 1.x version

### Requirement: PostgreSQL client 18 SHALL be the only installed client
Only `postgresql-client-18` SHALL be installed. The runtime fallback logic in `gitlab_generate_postgresqlrc()` SHALL handle selecting the appropriate client version.

#### Scenario: Single PostgreSQL client
- **WHEN** the image is built
- **THEN** only `postgresql-client-18` SHALL be installed
- **AND** connecting to a PostgreSQL 17 server SHALL work (newer client to older server)

### Requirement: libncurses-dev replaces libncurses5-dev
The `libncurses5-dev` package (removed after Ubuntu 22.04) SHALL be replaced with `libncurses-dev` in both the Dockerfile and `install.sh`.

#### Scenario: ncurses development headers
- **WHEN** the image is built
- **THEN** `libncurses-dev` SHALL be installed instead of `libncurses5-dev`
- **AND** Ruby SHALL build successfully against ncurses 6.x
