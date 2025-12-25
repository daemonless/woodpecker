# Woodpecker CI (Server & Agent) for FreeBSD
# Build with: podman build -t localhost/woodpecker:latest .

# Stage 1: Build the frontend (Web UI)
FROM ghcr.io/daemonless/base:15 AS frontend-builder
RUN pkg update && pkg install -y node22 npm-node22 git ca_root_nss
RUN npm install -g pnpm
ARG VERSION=v3.12.0
RUN git clone --depth 1 --branch ${VERSION} https://github.com/woodpecker-ci/woodpecker.git /src
WORKDIR /src/web
RUN pnpm install --frozen-lockfile && pnpm build

# Stage 2: Build the backend (Server, Agent, CLI)
FROM ghcr.io/daemonless/base:15 AS backend-builder
RUN pkg update && pkg install -y go125 git ca_root_nss sqlite3 \
    FreeBSD-clang FreeBSD-clang-dev FreeBSD-clibs-dev FreeBSD-runtime-dev \
    FreeBSD-audit-dev
RUN ln -sf /usr/bin/clang /usr/bin/cc
COPY --from=frontend-builder /src /src
WORKDIR /src
# Enable CGO for sqlite3 support
ENV CGO_ENABLED=1
# Use direct download to avoid slow proxy issues
ENV GOPROXY=direct
ARG VERSION=v3.12.0
RUN /usr/local/bin/go125 build -tags 'sqlite_unlock_notify' -ldflags="-X go.woodpecker-ci.org/woodpecker/v3/version.Version=${VERSION}" -o /bin/woodpecker-server ./cmd/server
RUN /usr/local/bin/go125 build -ldflags="-X go.woodpecker-ci.org/woodpecker/v3/version.Version=${VERSION}" -o /bin/woodpecker-agent ./cmd/agent
RUN /usr/local/bin/go125 build -ldflags="-X go.woodpecker-ci.org/woodpecker/v3/version.Version=${VERSION}" -o /bin/woodpecker-cli ./cmd/cli

# Stage 3: Final Runtime
FROM ghcr.io/daemonless/base:15

ARG VERSION=v3.12.0

ARG FREEBSD_ARCH=amd64
ARG PACKAGES="ca_root_nss git-tiny sqlite3 podman gsed gawk gnugrep"
LABEL org.opencontainers.image.title="Woodpecker" \
    org.opencontainers.image.description="Woodpecker CI server and agent" \
    org.opencontainers.image.vendor="daemonless" \
    io.daemonless.category="Infrastructure" \
    io.daemonless.upstream-mode="github" \
    io.daemonless.upstream-repo="woodpecker-ci/woodpecker" \
    io.daemonless.packages="${PACKAGES}"

# Runtime and Build dependencies
RUN pkg update && pkg install -y ${PACKAGES}

# Woodpecker needs a writable HOME for some operations
RUN pw usermod bsd -d /var/lib/woodpecker
ENV HOME=/var/lib/woodpecker

COPY --from=backend-builder /bin/woodpecker-server /usr/local/bin/
COPY --from=backend-builder /bin/woodpecker-agent /usr/local/bin/
COPY --from=backend-builder /bin/woodpecker-cli /usr/local/bin/

RUN chmod 755 /usr/local/bin/woodpecker-server /usr/local/bin/woodpecker-agent /usr/local/bin/woodpecker-cli && \
    mkdir -p /app && echo "${VERSION}" > /app/version

COPY root/ /

# Make scripts executable
RUN chmod +x /etc/services.d/woodpecker-server/run /etc/services.d/woodpecker-agent/run /etc/cont-init.d/* 2>/dev/null || true

# Set up s6 service links

EXPOSE 8000 9000
VOLUME /var/lib/woodpecker


# Trigger build 1766581496
