## Why

Ruby is compiled from source during the Docker image build (`assets/build/install.sh` lines 45-59), adding ~5-10 minutes of build time for `./configure && make && make install`. The compiled Ruby is functionally identical to a prebuilt binary from `jdx/ruby`, which publishes portable Linux x86_64 tarballs for exact versions like 3.3.11. Downloading a prebuilt binary reduces Ruby installation to a ~10-second tarball extraction with no loss of runtime behavior.

## What Changes

- Replace Ruby source compilation (configure/make/make install) with direct download of prebuilt binary tarball from `jdx/ruby` GitHub releases
- Add `RUBY_PREBUILT_REVISION=1` and `RUBY_PREBUILT_SHA256SUM="57ef3c917a1263816f33568f750b575b81830adaade6b1f262054038566881d0"` to Dockerfile ENV
- Remove `RUBY_SRC_URL` from `install.sh`; add `RUBY_PREBUILT_URL` pointing to the jdx/ruby release tarball
- Verify prebuilt binary checksum with `sha256sum -c -` (matches existing Go tarball pattern)
- Remove `patch` from `BUILD_DEPENDENCIES` (only used for Ruby source patches)
- Remove `assets/build/patches/ruby/` directory and the patch-application loop (lines 52-55)
- Strip rdoc/ri output (`rm -rf /usr/local/share/ri`) to reduce image size

## Capabilities

### New Capabilities

- `ruby-installation`: Prebuilt binary Ruby installation replacing source compilation

### Modified Capabilities

<!-- No existing specs are modified. Ruby installation behavior at runtime (gem, bundle exec) remains unchanged. -->
