#!/usr/bin/env python3
"""Mock-API tests for clean-state verification and cleanup evidence."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANAGER = ROOT / "p0-env/scripts/manage-network-delay-proxy.py"
PROFILE = ROOT / "p0-env/config/faults/network-delay-recommendation-productcatalog-v1.json"


class Handler(BaseHTTPRequestHandler):
    toxics: list[dict] = []
    upstream = "productcatalogservice:3550"

    def log_message(self, *_: object) -> None:
        return

    def payload(self) -> dict:
        return {
            "name": "recommendation-to-productcatalog",
            "listen": "127.0.0.1:3551",
            "upstream": self.upstream,
            "enabled": True,
            "toxics": self.toxics,
        }

    def do_GET(self) -> None:  # noqa: N802
        body = json.dumps(self.payload()).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/reset":
            self.send_error(404)
            return
        Handler.toxics = []
        self.send_response(204)
        self.end_headers()


def invoke(base: str, action: str, evidence: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(MANAGER), "--api-base", base, "--profile", str(PROFILE), "--action", action, "--evidence", str(evidence)],
        text=True, capture_output=True,
    )


server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
thread = threading.Thread(target=server.serve_forever, daemon=True)
thread.start()
base = f"http://127.0.0.1:{server.server_port}"

try:
    with tempfile.TemporaryDirectory() as temporary:
        evidence = Path(temporary) / "clean.json"
        Handler.toxics = []
        positive = invoke(base, "verify-clean", evidence)
        assert positive.returncode == 0, positive.stderr
        assert json.loads(evidence.read_text())["cleanup_verified"] is True
        print("network_delay_proxy_clean_positive_fixture=passed")

    with tempfile.TemporaryDirectory() as temporary:
        Handler.toxics = [{"name": "residual", "type": "latency"}]
        negative = invoke(base, "verify-clean", Path(temporary) / "rejected.json")
        assert negative.returncode != 0
        assert "residual_toxics" in negative.stderr
        print("network_delay_proxy_residual_toxic_negative_fixture=passed")

    with tempfile.TemporaryDirectory() as temporary:
        Handler.toxics = [{"name": "latency", "type": "latency"}]
        evidence = Path(temporary) / "reset.json"
        reset = invoke(base, "reset", evidence)
        assert reset.returncode == 0, reset.stderr
        result = json.loads(evidence.read_text())
        assert result["reset_called"] is True and result["after"]["toxics"] == []
        print("network_delay_proxy_reset_cleanup_fixture=passed")

    with tempfile.TemporaryDirectory() as temporary:
        Handler.upstream = "wrong:3550"
        negative = invoke(base, "verify-clean", Path(temporary) / "wrong.json")
        assert negative.returncode != 0
        assert "proxy_upstream_mismatch" in negative.stderr
        print("network_delay_proxy_wrong_upstream_negative_fixture=passed")
finally:
    server.shutdown()
    server.server_close()
