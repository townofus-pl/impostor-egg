# Impostor + Reactor.Impostor for the Drama Afera League Server, as a Pterodactyl yolk.
# Wings pulls this image on every server start, so a new :league tag deploys on the next restart.

ARG IMPOSTOR_VERSION=v1.10.9
ARG REACTOR_IMPOSTOR_VERSION=2.2.0

FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS download
ARG IMPOSTOR_VERSION
ARG REACTOR_IMPOSTOR_VERSION
ARG TARGETARCH
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/impostor
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) RID=linux-x64 ;; \
      arm64) RID=linux-arm64 ;; \
      *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    V="${IMPOSTOR_VERSION#v}"; \
    curl -fsSL "https://github.com/Impostor/Impostor/releases/download/${IMPOSTOR_VERSION}/Impostor-Server_${V}_${RID}.tar.gz" | tar xz; \
    rm -f config.json *.pdb *.xml; \
    mkdir plugins libraries; \
    curl -fsSL -o plugins/Reactor.Impostor.dll \
      "https://github.com/NuclearPowered/Reactor.Impostor/releases/download/${REACTOR_IMPOSTOR_VERSION}/Reactor.Impostor.dll"; \
    # The release tarball ships its files as mode 700, so the non-root runtime user cannot run them.
    chmod -R a+rX /opt/impostor; \
    chmod 755 Impostor.Server

FROM mcr.microsoft.com/dotnet/aspnet:8.0-bookworm-slim
ARG IMPOSTOR_VERSION
ARG REACTOR_IMPOSTOR_VERSION
LABEL org.opencontainers.image.source="https://github.com/townofus-pl/impostor-egg" \
      org.opencontainers.image.description="Impostor ${IMPOSTOR_VERSION} with Reactor.Impostor ${REACTOR_IMPOSTOR_VERSION}, Pterodactyl yolk"

COPY --from=download /opt/impostor /opt/impostor

# The base plugins live in the image, so an image update also updates them. Impostor also loads
# extra plugins from plugins/ and libraries/ on the server volume (README, "Add a plugin").
# AntiCheat: ADR 0001. Changing it is a decision, so it lives here and not in a panel variable.
ENV IMPOSTOR_ENV=Production \
    IMPOSTOR_PluginLoader__Paths__0=/opt/impostor/plugins \
    IMPOSTOR_PluginLoader__LibraryPaths__0=/opt/impostor/libraries \
    IMPOSTOR_Server__ListenIp=0.0.0.0 \
    IMPOSTOR_HttpServer__Enabled=true \
    IMPOSTOR_HttpServer__ListenIp=0.0.0.0 \
    IMPOSTOR_AntiCheat__Enabled=true \
    IMPOSTOR_AntiCheat__EnableRoleChecks=false \
    IMPOSTOR_AntiCheat__ForbidProtocolExtensions=false \
    IMPOSTOR_AntiCheat__BanIpFromGame=false

RUN useradd -m -d /home/container -s /bin/bash container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY --chmod=755 entrypoint.sh /entrypoint.sh
STOPSIGNAL SIGINT
CMD ["/bin/bash", "/entrypoint.sh"]
