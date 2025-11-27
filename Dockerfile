FROM mirror.gcr.io/library/debian:13-slim


RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    xterm \
    tigervnc-standalone-server \
    xfonts-base \
    xfonts-75dpi \
    xfonts-100dpi \
    xfce4 \
    xfce4-goodies \
    xfconf \
    tar \
    gtk2-engines-murrine \
    dbus-x11 \
    novnc \
    websockify \
    x11-apps \
    sudo \
    socat \
    screen \
    chromium

WORKDIR /app

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -LO https://github.com/go-gost/gost/releases/download/v3.2.6/gost_3.2.6_linux_${ARCH}.tar.gz && \
    tar -xzf gost_3.2.6_linux_${ARCH}.tar.gz


RUN curl -L https://github.com/B00merang-Project/Windows-10/archive/refs/heads/master.tar.gz -o /app/Theme.tar.gz

COPY entrypoint.sh /app/entrypoint.sh

EXPOSE 5900

RUN cp /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html
RUN sed -i 's/rfb.scaleViewport = readQueryVariable.*$/rfb.scaleViewport = true;/' /usr/share/novnc/index.html
EXPOSE 3001
EXPOSE 9222

RUN useradd -m -s /bin/bash user && \
    chown -R user:user /app && \
    usermod -aG sudo user && \
    echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER user

ENTRYPOINT ["/app/entrypoint.sh"]
