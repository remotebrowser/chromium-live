# Chromium Live

<img width="800" src="screenshot.png" alt="Screenshot" />

This containerized Chromium desktop runs on Linux and is accessible through any web browser.

Try using Docker:

```
docker run --name chromium-live -p 7000:80 ghcr.io/remotebrowser/chromium-live
```

or Podman:

```
podman run --name chromium-live -p 7000:80 ghcr.io/remotebrowser/chromium-live
```

Then open `localhost:7000` in your browser.

To enable remote control of Chromium via the [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/), map port 9222 as well:

```
podman run --name chromium-live -p 7000:80 -p 9222:9222 ghcr.io/remotebrowser/chromium-live
```

Configure Chromium's proxy connection using [Tinyproxy](https://tinyproxy.github.io) (refer to the sample `tinyproxy.conf`).

To test the CDP connection:

```
curl http://127.0.0.1:9222/json/list
```

To build and run locally:

```
docker build -t chromium-live .
docker run -p 7000:80 chromium-live
```

To deploy to fly

```
fly apps create test-chromium-live
fly deploy --ha=false -a test-chromium-live

# test CDP connection
FLY_IP=$(fly ips list -a test-chromium-live --json | jq -r '.[] | select(.Type=="v4") | .Address')
curl http://$FLY_IP:9222/json/list
```
