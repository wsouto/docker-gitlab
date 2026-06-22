## Context

The Docker image builds Ruby from source (`install.sh` lines 45-59): download tarball, verify sha256, extract, apply patches, `./configure --disable-install-rdoc --enable-shared`, `make -j$(nproc)`, `make install`. This takes ~5-10 minutes. The resulting Ruby is used at build time (gem install, bundle install, asset compilation) and at runtime (puma, sidekiq, mail_room via `bundle exec`).

`jdx/ruby` publishes portable prebuilt Ruby tarballs for Linux x86_64 on GitHub releases, tagged as `{version}-{revision}` (e.g., `3.3.11-1`). These install to `/usr/local`, matching the current `make install` prefix.

The existing Go toolchain installation (lines 112-115) already follows the same pattern: download tarball, verify checksum, extract to `/tmp`. This change aligns Ruby installation with that established pattern.

## Goals / Non-Goals

**Goals:**
- Replace Ruby source compilation with prebuilt binary download
- Reduce build time by ~5-10 minutes
- Reduce image size by stripping rdoc/ri
- Remove dead patch infrastructure (`patches/ruby/`, `patch` dependency)
- Maintain identical runtime behavior (gem, bundle, bundle exec)

**Non-Goals:**
- Adding mise or any version manager (one Ruby version baked — no manager needed)
- Checksum verification of the prebuilt binary is IN SCOPE (sha256 pinned in Dockerfile ENV)
- Changing runtime supervisor configurations (puma, sidekiq, mail_room, etc.)
- Changing gem/bundler installation workflow
- Supporting multiple Ruby versions

## Decisions

### Decision 1: Direct tarball download over mise

**Choice:** `curl | tar` directly from `jdx/ruby` GitHub releases.

**Alternatives considered:**
- **mise** (`ruby.compile=false`): Provides version management, `mise.lock` reproducibility, and automatic fallback to source compilation. Rejected because we bake exactly one Ruby version — a version manager is unnecessary complexity. mise adds ~15MB binary + shim layer + config files. Direct download matches the existing Go tarball pattern (lines 112-115).

### Decision 2: Pin build revision via ENV

**Choice:** `RUBY_PREBUILT_REVISION=1` and `RUBY_PREBUILT_SHA256SUM="57ef3c917a1263816f33568f750b575b81830adaade6b1f262054038566881d0"` in Dockerfile ENV. URL constructed as:
```
https://github.com/jdx/ruby/releases/download/${RUBY_VERSION}-${RUBY_PREBUILT_REVISION}/ruby-${RUBY_VERSION}.x86_64_linux.tar.gz
```

**Rationale:** jdx/ruby uses numeric revision tags (`3.3.11-1`, `3.3.11-2`). GitHub releases have no "latest" resolution for revision tags. Explicit ENV pin ensures reproducible builds and makes revision bumps visible in the Dockerfile. The sha256 checksum is computed from the downloaded tarball and pinned to guarantee download integrity, matching the project convention for all external binaries (same pattern as `GOLANG_SOURCE_SHA256SUM`).

**Replaces:** `RUBY_SOURCE_SHA256SUM` (was for source tarball verification; now replaced by prebuilt binary checksum).

### Decision 3: Remove `patch` from BUILD_DEPENDENCIES

**Choice:** Drop `patch` from the build dependencies list.

**Rationale:** `patch` command was only used in the Ruby source patch loop (lines 52-55). GitLab-foss patches (line 101) use `git apply`, not `patch`. No other usage of `patch` exists in `install.sh`.

### Decision 4: Strip rdoc/ri post-install

**Choice:** `rm -rf /usr/local/share/ri` after tarball extraction.

**Rationale:** Source build used `--disable-install-rdoc`. Prebuilt binary includes rdoc/ri. Stripping `ri` directory reduces image size. `gem update --no-document` and `--disable-install-rdoc` behavior is approximated by this cleanup.

### Decision 5: Remove patches/ruby/ directory entirely

**Choice:** Delete `assets/build/patches/ruby/` and the patch-application loop.

**Rationale:** The single patch (`0001-avoid-seeding_until-ruby3.3.0.bak`) was already disabled (`.bak` extension, glob `*.patch` skips it). The patch addresses OpenSSL `RAND_add` seeding, which is resolved upstream in Ruby 3.3.x. Binary Ruby cannot be patched post-download, but the patch is unnecessary.

## Risks / Trade-offs

- **glibc compatibility:** Prebuilt binary is compiled against an unknown glibc version. If built on a newer glibc than Resolute (26.04) provides, Ruby will fail at runtime. Risk is low — prebuilt binaries typically target older bases for forward compatibility. No mitigation planned; if it fails, fall back to source compilation.
- **`--enable-shared` availability:** Source build used `--enable-shared`. If the prebuilt binary lacks it, gems with C extensions that link against `libruby` may fail. jdx/ruby builds are designed for general use and typically include `--enable-shared`. No mitigation planned; if it fails, fall back to source compilation.
- **Build revision drift:** Pinning `RUBY_PREBUILT_REVISION=1` means we won't automatically get bug-fix rebuilds (e.g., `-2`). Manual bump required. Trade-off: reproducibility over convenience.
