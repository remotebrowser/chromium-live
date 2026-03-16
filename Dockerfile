FROM mirror.gcr.io/library/debian:13-slim

ARG TARGETARCH
ARG S6_OVERLAY_VERSION=v3.2.2.0

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    util-linux \
    curl \
    gnupg \
    ca-certificates \
    tinyproxy \
    xterm \
    tigervnc-standalone-server \
    xfonts-base \
    xfonts-75dpi \
    xfonts-100dpi \
    xfce4 \
    xfce4-goodies \
    xfconf \
    tar \
    xz-utils \
    gtk2-engines-murrine \
    dbus-x11 \
    novnc \
    websockify \
    x11-apps \
    sudo \
    socat \
    screen \
    sqlite3 \
    chromium \
    cabextract \
    fontconfig \
    procps && \
    sed -i 's/^Components: main$/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources && \
    apt-get update -y && \
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
    apt-get install -y --no-install-recommends \
    ttf-mscorefonts-installer \
    fonts-freefont-otf \
    fonts-gfs-neohellenic \
    fonts-indic \
    fonts-ipafont-gothic \
    fonts-kacst-one \
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    fonts-roboto \
    fonts-thai-tlwg \
    fonts-ubuntu \
    fonts-wqy-zenhei \
    fonts-open-sans && \
    fc-cache -f && \
    rm -rf /var/lib/apt/lists/*

RUN case "${TARGETARCH}" in \
      amd64) S6_ARCH="x86_64" ;; \
      arm64) S6_ARCH="aarch64" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" -o /tmp/s6-overlay-noarch.tar.xz && \
    curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz" -o /tmp/s6-overlay-arch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    rm -f /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-arch.tar.xz

WORKDIR /app

COPY entrypoint.sh /etc/cont-init.d/00-entrypoint.sh
COPY start-init.sh /usr/local/bin/start-init.sh
COPY tinyproxy.conf /app/tinyproxy.conf
COPY allowlist.txt /app/allowlist.txt
COPY root/ /

RUN chmod +x /etc/cont-init.d/00-entrypoint.sh /usr/local/bin/start-init.sh && \
    cp /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html && \
    sed -i 's/rfb.scaleViewport = readQueryVariable.*$/rfb.scaleViewport = true;/' /usr/share/novnc/index.html && \
    sed -i 's/<div id="top_bar">/<div id="top_bar" style="display:none;">/' /usr/share/novnc/index.html

RUN curl -o /tmp/hblock 'https://raw.githubusercontent.com/hectorm/hblock/v3.5.1/hblock' \
  && echo 'd010cb9e0f3c644e9df3bfb387f42f7dbbffbbd481fb50c32683bbe71f994451  /tmp/hblock' | shasum -c \
  && mv /tmp/hblock /usr/local/bin/hblock \
  && chown 0:0 /usr/local/bin/hblock \
  && chmod 755 /usr/local/bin/hblock \
  && /usr/local/bin/hblock --output /app/hosts --header none --allowlist /app/allowlist.txt

RUN useradd -m -s /bin/bash user && \
    mkdir -p /home/user/chrome-profile && \
    chown -R user:user /app /home/user

RUN chmod +x /etc/s6-overlay/s6-rc.d/*/run

EXPOSE 80
EXPOSE 5900
EXPOSE 9222

ENTRYPOINT ["/usr/local/bin/start-init.sh"]
