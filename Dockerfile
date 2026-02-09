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

RUN curl -o /tmp/hblock 'https://raw.githubusercontent.com/hectorm/hblock/v3.5.1/hblock' \
  && echo 'd010cb9e0f3c644e9df3bfb387f42f7dbbffbbd481fb50c32683bbe71f994451  /tmp/hblock' | shasum -c \
  && sudo mv /tmp/hblock /usr/local/bin/hblock \
  && sudo chown 0:0 /usr/local/bin/hblock \
  && sudo chmod 755 /usr/local/bin/hblock \
  && /usr/local/bin/hblock --output /hosts --header none

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
