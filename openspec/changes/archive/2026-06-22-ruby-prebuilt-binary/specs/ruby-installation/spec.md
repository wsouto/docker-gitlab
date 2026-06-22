## ADDED Requirements

### Requirement: Prebuilt Ruby installation

The build process shall install Ruby from a prebuilt binary tarball hosted on `jdx/ruby` GitHub releases, replacing source compilation. The tarball shall be extracted to `/usr/local`, matching the installation prefix of the previous `make install` flow.

#### Scenario: Ruby binary installed from prebuilt tarball
- **WHEN** the Docker image is built
- **THEN** Ruby is installed by downloading `https://github.com/jdx/ruby/releases/download/${RUBY_VERSION}-${RUBY_PREBUILT_REVISION}/ruby-${RUBY_VERSION}.x86_64_linux.tar.gz`, verifying its sha256 checksum, and extracting it to `/usr/local`
- **AND** the `ruby`, `gem`, and `bundle` commands are available in `/usr/local/bin`

#### Scenario: Ruby version and revision are pinned in Dockerfile
- **WHEN** the Dockerfile is inspected
- **THEN** `RUBY_VERSION`, `RUBY_PREBUILT_REVISION`, and `RUBY_PREBUILT_SHA256SUM` are defined as ENV variables
- **AND** `RUBY_SOURCE_SHA256SUM` is absent

#### Scenario: rdoc/ri stripped after installation
- **WHEN** Ruby prebuilt binary is extracted
- **THEN** `/usr/local/share/ri` is removed to reduce image size


#### Scenario: Prebuilt binary checksum verified
- **WHEN** the prebuilt Ruby tarball is downloaded
- **THEN** `sha256sum -c -` is run against `RUBY_PREBUILT_SHA256SUM`
- **AND** the build fails if the checksum does not match

### Requirement: Ruby patch infrastructure removed

The Ruby source patch directory and patch-application logic shall be removed, as prebuilt binaries cannot be patched and the existing patch targets an issue resolved upstream in Ruby 3.3.x.

#### Scenario: patches/ruby directory deleted
- **WHEN** the repository is inspected after the change
- **THEN** `assets/build/patches/ruby/` directory does not exist

#### Scenario: patch loop removed from install.sh
- **WHEN** `install.sh` is inspected
- **THEN** no `find ... patches/ruby` loop or `patch -p1` command exists

#### Scenario: patch dropped from build dependencies
- **WHEN** `BUILD_DEPENDENCIES` is inspected in `install.sh`
- **THEN** `patch` is not listed

### Requirement: RubyGems and Bundler workflow unchanged

The gem and bundler installation workflow shall remain unchanged after switching to prebuilt Ruby. RubyGems version pinning and bundler installation from `Gemfile.lock` continue to work as before.

#### Scenario: RubyGems version pinned
- **WHEN** Ruby is installed from prebuilt binary
- **THEN** `gem update --no-document --system ${RUBYGEMS_VERSION}` runs successfully

#### Scenario: Bundler installed from Gemfile.lock
- **WHEN** the GitLab source is cloned and `Gemfile.lock` is available
- **THEN** `gem install bundler:${BUNDLER_VERSION}` runs successfully
- **AND** `bundle install` completes without errors
