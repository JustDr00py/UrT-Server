FROM ubuntu:22.04

LABEL maintainer="UrT Server Admin"
LABEL description="Urban Terror 4.3 Dedicated Server - Optimized for 16 Players"

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
# UrT server binary may be 32-bit or 64-bit depending on the version downloaded
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        lib32gcc-s1 \
        libc6-i386 \
        libstdc++6 \
        libstdc++6:i386 \
        ca-certificates \
        wget \
        curl \
        unzip \
        tini \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user to run the server
RUN useradd -m -u 1000 -s /bin/bash urtserver

# Server directories:
#   /opt/urtserver/game  -> bind-mounted volume containing UrT game files (q3ut4/ etc.)
#   /opt/urtserver/data  -> writable homepath (configs, downloads, logs)
RUN mkdir -p /opt/urtserver/game /opt/urtserver/data/q3ut4 && \
    chown -R urtserver:urtserver /opt/urtserver

COPY --chown=urtserver:urtserver entrypoint.sh /entrypoint.sh
COPY --chown=urtserver:urtserver config/maprotation.cfg /opt/urtserver/data/q3ut4/maprotation.cfg
RUN chmod +x /entrypoint.sh

# Default UDP port for UrT
EXPOSE 27960/udp

USER urtserver
WORKDIR /opt/urtserver

# tini as PID 1 for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
