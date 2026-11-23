# syntax=docker/dockerfile:1.7
# Kantin Cerdas Backend (Dart Shelf Modular Monolith)
# Multi-stage build pinned to validated local toolchain:
#   - Dart SDK 3.12.2 (Debian 13.6 trixie)
#   - Runtime Debian 13.6-slim with matching glibc, ca-certificates, and non-root user
#   - Default entrypoint: bin/server.dart (Health + Auth + Catalog + Owner + Customer + Admin + AI + Notifications)

FROM dart:3.12.2 AS build

WORKDIR /app

# Resolve locked dependencies only (no automatic package upgrades).
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --enforce-lockfile

# Copy application source only (never .env or secrets).
COPY bin/ ./bin/
COPY lib/ ./lib/

ARG ENTRYPOINT=bin/server.dart

RUN test -f "${ENTRYPOINT}" \
    && mkdir -p /app/build \
    && dart compile exe "${ENTRYPOINT}" -o /app/build/server

FROM debian:13.6-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 appgroup \
    && useradd --system --uid 10001 --gid appgroup --home-dir /app --shell /usr/sbin/nologin appuser

WORKDIR /app

COPY --from=build --chown=appuser:appgroup /app/build/server /app/bin/server
COPY --chown=appuser:appgroup docker-entrypoint.sh /app/docker-entrypoint.sh

RUN chmod 0555 /app/bin/server /app/docker-entrypoint.sh

ENV SERVER_HOST=0.0.0.0

USER 10001:10001

EXPOSE 8080

ENTRYPOINT ["/app/docker-entrypoint.sh"]
