# syntax=docker/dockerfile:1
FROM ubuntu:resolute

ARG VERSION=19.1.0

# v19.x : minimum = 17.0, maximum = 17.x (currently 17.10, is 170010)
ENV GITLAB_VERSION=${VERSION} \
    RUBY_VERSION=3.3.11 \
    RUBY_SOURCE_SHA256SUM="59f0fafb1a59a05dc3765117af3fa68e153eb48254708549f321c1e9e078d7a0" \
    RUBYGEMS_VERSION=4.0.14 \
    GOLANG_VERSION=1.26.4 \
    GOLANG_SOURCE_SHA256SUM="1153d3d50e0ac764b447adfe05c2bcf08e889d42a02e0fe0259bd47f6733ad7f" \
    GITLAB_SHELL_VERSION=14.54.0 \
    GITLAB_PAGES_VERSION=19.1.0 \
    GITALY_SERVER_VERSION=19.1.0 \
    GITLAB_USER="git" \
    GITLAB_HOME="/home/git" \
    GITLAB_LOG_DIR="/var/log/gitlab" \
    GITLAB_CACHE_DIR="/etc/docker-gitlab" \
    RAILS_ENV=production \
    NODE_ENV=production \
    NO_SOURCEMAPS=true \
    POSTGRESQL_SERVER_REQUIRED_VERSION_MINIMUM=170000 \
    POSTGRESQL_SERVER_TESTED_VERSION_MAXIMUM=170010

ENV GITLAB_INSTALL_DIR="${GITLAB_HOME}/gitlab" \
    GITLAB_SHELL_INSTALL_DIR="${GITLAB_HOME}/gitlab-shell" \
    GITLAB_GITALY_INSTALL_DIR="${GITLAB_HOME}/gitaly" \
    GITLAB_DATA_DIR="${GITLAB_HOME}/data" \
    GITLAB_BUILD_DIR="${GITLAB_CACHE_DIR}/build" \
    GITLAB_RUNTIME_DIR="${GITLAB_CACHE_DIR}/runtime"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    wget ca-certificates curl \
 && apt-get upgrade -y \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
      sudo supervisor logrotate locales \
      meson \
      nginx openssh-server redis-tools \
      postgresql-client-18 \
      python3 python3-docutils nodejs npm gettext-base graphicsmagick \
      libpq5 zlib1g libyaml-dev libssl-dev libgdbm-dev libre2-dev \
      libreadline-dev libncurses-dev libffi-dev libxml2-dev libxslt-dev \
      libcurl4-openssl-dev libicu-dev libkrb5-dev rsync pkg-config cmake \
      tzdata unzip libimage-exiftool-perl libmagic1 \
 && npm install -g yarn@1.22.22 \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && locale-gen en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
 && rm -rf /var/lib/apt/lists/* /etc/nginx/conf.d/default.conf

COPY assets/build/ ${GITLAB_BUILD_DIR}/
RUN bash ${GITLAB_BUILD_DIR}/install.sh

COPY assets/runtime/ ${GITLAB_RUNTIME_DIR}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

ENV prometheus_multiproc_dir="/dev/shm"

ARG BUILD_DATE
ARG VCS_REF

LABEL \
    maintainer="sameer@damagehead.com" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name=gitlab \
    org.label-schema.vendor=damagehead \
    org.label-schema.url="https://github.com/sameersbn/docker-gitlab" \
    org.label-schema.vcs-url="https://github.com/sameersbn/docker-gitlab.git" \
    org.label-schema.vcs-ref=${VCS_REF} \
    com.damagehead.gitlab.license=MIT

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
  CMD /usr/local/sbin/healthcheck || exit 1

EXPOSE 22/tcp 80/tcp 443/tcp

VOLUME ["${GITLAB_DATA_DIR}", "${GITLAB_LOG_DIR}"]
WORKDIR ${GITLAB_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
