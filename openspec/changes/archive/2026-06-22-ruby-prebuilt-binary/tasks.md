## 1. Dockerfile ENV updates

- [x] 1.1 Remove `RUBY_SOURCE_SHA256SUM` from Dockerfile ENV (line 9)
- [x] 1.2 Add `RUBY_PREBUILT_REVISION=1` and `RUBY_PREBUILT_SHA256SUM="57ef3c917a1263816f33568f750b575b81830adaade6b1f262054038566881d0"` to Dockerfile ENV

## 2. install.sh: Replace Ruby source compilation

- [x] 2.1 Remove `RUBY_SRC_URL` variable (line 13) and add `RUBY_PREBUILT_URL` pointing to `jdx/ruby` release tarball
- [x] 2.2 Remove `patch` from `BUILD_DEPENDENCIES` (line 24)
- [x] 2.3 Replace source compile block (lines 45-59) with prebuilt binary download: `curl -fsSL "${RUBY_PREBUILT_URL}" -o /tmp/ruby-prebuilt.tar.gz`, `printf '%s %s' "${RUBY_PREBUILT_SHA256SUM}" /tmp/ruby-prebuilt.tar.gz | sha256sum -c -`, `tar xzf /tmp/ruby-prebuilt.tar.gz -C /usr/local`, `rm -rf /usr/local/share/ri`
- [x] 2.4 Remove Ruby patch loop (lines 52-55) — already covered by replacing the block, but verify no separate patch references remain

## 3. Remove patch infrastructure

- [x] 3.1 Delete `assets/build/patches/ruby/` directory entirely

## 4. Verification

- [x] 4.1 Run `docker build --check` to validate Dockerfile syntax
- [x] 4.2 Run `shellcheck assets/build/install.sh` to verify script integrity
- [x] 4.3 Verify `ruby -v` outputs `3.3.11` and `gem` is functional inside the built image

## 5. Documentation

- [x] 5.1 Add Changelog.md entry under version 19.1.0
