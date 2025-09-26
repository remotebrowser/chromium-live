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
    firefox-esr

WORKDIR /app

RUN curl -L https://github.com/B00merang-Project/Windows-10/archive/refs/heads/master.tar.gz -o /app/Theme.tar.gz

COPY entrypoint.sh /app/entrypoint.sh

EXPOSE 5900

RUN cp /usr/share/novnc/vnc_lite.html /usr/share/novnc/index.html
RUN sed -i 's/rfb.scaleViewport = readQueryVariable.*$/rfb.scaleViewport = true;/' /usr/share/novnc/index.html
EXPOSE 3001

ENTRYPOINT ["/app/entrypoint.sh"]
