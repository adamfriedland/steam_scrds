# check=skip=SecretsUsedInArgOrEnv
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        lib32gcc-s1 \
        lib32stdc++6 \
        tar \
        wget && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home steam

USER steam
WORKDIR /home/steam

RUN mkdir steamcmd && \
    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        -O steamcmd.tar.gz && \
    tar -xzf steamcmd.tar.gz -C steamcmd && \
    rm steamcmd.tar.gz

RUN ./steamcmd/steamcmd.sh +login anonymous +quit

RUN ./steamcmd/steamcmd.sh \
      +force_install_dir /home/steam/hl2dm \
      +login anonymous \
      +app_update 232370 validate \
      +quit

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libcurl4 \
        lib32gcc-s1 \
        lib32stdc++6 && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --create-home steam

COPY --from=builder --chown=steam:steam /home/steam/hl2dm /home/steam/hl2dm

COPY --from=builder --chown=steam:steam \
    /home/steam/steamcmd/linux32/steamclient.so /home/steam/.steam/sdk32/steamclient.so
COPY --from=builder --chown=steam:steam \
    /home/steam/steamcmd/linux64/steamclient.so /home/steam/.steam/sdk64/steamclient.so

COPY cfg/server.cfg /home/steam/hl2dm/hl2mp/cfg/server.cfg

ARG RCON_PASSWORD
RUN test -n "$RCON_PASSWORD" && \
    case "$RCON_PASSWORD" in \
        *[!A-Za-z0-9_.!-]*) echo "RCON_PASSWORD contains unsupported characters" >&2; exit 1 ;; \
    esac && \
    sed -i "s/\${RCON_PASSWORD}/$RCON_PASSWORD/g" /home/steam/hl2dm/hl2mp/cfg/server.cfg

COPY cfg/banned_user.cfg /home/steam/hl2dm/hl2mp/cfg/banned_user.cfg

COPY cfg/mapcycle.txt /home/steam/hl2dm/hl2mp/mapcycle.txt

COPY maps/ /home/steam/hl2dm/hl2mp/maps/

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

USER steam
WORKDIR /home/steam

EXPOSE 27015/udp
EXPOSE 27015/tcp

ENTRYPOINT ["/entrypoint.sh"]