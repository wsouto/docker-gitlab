## 1. Dockerfile changes

- [x] 1.1 Change base image from `ubuntu:noble` to `ubuntu:resolute`
- [x] 1.2 Remove all third-party apt repository configuration (git-core PPA key+repo, postgresql.org key+repo, nodesource key+repo, yarnpkg key+repo, nginx.org key+repo+pin)
- [x] 1.3 Update apt install list: remove `postgresql-client-17`, remove `yarn`, add `npm`, replace `libncurses5-dev` with `libncurses-dev`
- [x] 1.4 Add `npm install -g yarn@1.22.22` to install packages from Ubuntu repos only

## 2. install.sh changes

- [x] 2.1 Replace `libncurses5-dev` with `libncurses-dev` in BUILD_DEPENDENCIES

## 3. Verification

- [x] 3.1 Run `docker build --check` to validate Dockerfile
- [x] 3.2 Run shellcheck on install.sh
- [x] 3.3 Verify printf format sanity

## 4. Documentation

- [x] 4.1 Add Changelog.md entry
