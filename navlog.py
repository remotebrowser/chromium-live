#!/usr/bin/env python3
import json
import os
import time
from pathlib import Path

import logfire
import requests
import websocket
from websocket import WebSocketTimeoutException

DEBUG_URL = os.getenv("DEBUG_URL", "http://127.0.0.1:9221/json")
LOGFIRE_TOKEN = os.getenv("LOGFIRE_TOKEN")
LOGFIRE_TRACEPARENT = os.getenv("LOGFIRE_TRACEPARENT")
CONTAINER_NAME = os.getenv("CONTAINER_NAME", "chromium-live")
OUT = Path(os.getenv("OUT", "/home/user/logs/nav.log"))


def wait_for_cdp(timeout_s: float = 60.0, poll_s: float = 1.0) -> dict:
    t0 = time.time()
    while time.time() - t0 < timeout_s:
        try:
            r = requests.get(f"{DEBUG_URL}/version", timeout=1.0)
            if r.ok:
                return r.json()
        except Exception:
            pass
        time.sleep(poll_s)
    raise TimeoutError(f"CDP not reachable at {DEBUG_URL} within {timeout_s}s")


def append_log(url: str):
    ts = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("a", encoding="utf-8") as f:
        f.write(f"{ts}\t{url}\n")
        f.flush()

    if LOGFIRE_TOKEN:
        with logfire.attach_context({"traceparent": LOGFIRE_TRACEPARENT}):
            logfire.info(url)


def main():
    print(f"Starting navlog for chromium-live at {OUT}...")

    if LOGFIRE_TOKEN:
        print("Configuring Logfire")
        logfire.configure(
            service_name="chromium-live",
            environment=CONTAINER_NAME,
            token=LOGFIRE_TOKEN,
            distributed_tracing=True,
            console=False,
            scrubbing=False,
        )

    ver = wait_for_cdp()

    # Connect to the Browser-level websocket so we can discover/auto-attach to all tabs.
    ws_url = ver["webSocketDebuggerUrl"]
    ws = websocket.create_connection(ws_url, timeout=10)

    next_id = 1

    def rpc(method, params=None, session_id=None):
        nonlocal next_id
        msg = {"id": next_id, "method": method}
        if params is not None:
            msg["params"] = params
        if session_id is not None:
            msg["sessionId"] = session_id
        ws.send(json.dumps(msg))
        next_id += 1

    # Discover existing + future targets, and auto-attach to them.
    rpc("Target.setDiscoverTargets", {"discover": True})
    rpc(
        "Target.setAutoAttach",
        {"autoAttach": True, "waitForDebuggerOnStart": False, "flatten": True},
    )

    # Track main frame per session so we can strictly filter "top-level"
    main_frame_by_session = {}

    while True:
        try:
            raw = ws.recv()
        except WebSocketTimeoutException:
            continue
        msg = json.loads(raw)
        method = msg.get("method")

        # Fired when we auto-attach to a target (tab)
        if method == "Target.attachedToTarget":
            params = msg["params"]
            session_id = params["sessionId"]
            target_info = params["targetInfo"]

            # Only pages/tabs (skip service workers, extensions, etc.)
            if target_info.get("type") == "page":
                # Enable Page events inside this session
                rpc("Page.enable", session_id=session_id)

        # Page events for a given attached session arrive with sessionId at top-level
        session_id = msg.get("sessionId")
        if session_id and method == "Page.frameNavigated":
            frame = msg["params"]["frame"]

            # Record main frame id once, then only log that frame
            if frame.get("parentId") is None:
                main_frame_by_session[session_id] = frame.get("id")

            if frame.get("id") == main_frame_by_session.get(session_id):
                url = frame.get("url", "")
                append_log(url)


if __name__ == "__main__":
    main()
