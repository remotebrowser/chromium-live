FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates \
    tinyproxy \
    x11-apps \
    sudo \
    socat \
    sqlite3 \
    chromium

COPY entrypoint.sh /
COPY /root /

RUN chmod +x /entrypoint.sh

ENV TITLE="Chromium Live"
ENV RESTART_APP=True
ENV SELKIES_MANUAL_WIDTH=1920
ENV SELKIES_MANUAL_HEIGHT=1080
ENV SELKIES_USE_CPU=True
ENV SELKIES_AUDIO_ENABLED=False
ENV SELKIES_MICROPHONE_ENABLED=False
ENV SELKIES_FILE_TRANSFERS=none
ENV SELKIES_USE_BROWSER_CURSORS=True

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
