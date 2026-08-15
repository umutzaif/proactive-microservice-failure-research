#!/usr/bin/env python3
"""Positive and privilege/toxic drift tests for the proxy overlay verifier."""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "p0-env/config/network-delay-design"
VERIFIER = ROOT / "p0-env/scripts/verify-network-delay-proxy-overlay.py"


def invoke(path: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(VERIFIER), "--overlay-root", str(path)],
        text=True, capture_output=True,
    )


positive = invoke(SOURCE)
assert positive.returncode == 0, positive.stderr
print("network_delay_proxy_overlay_positive_fixture=passed")

with tempfile.TemporaryDirectory() as temporary:
    target = Path(temporary) / "overlay"
    shutil.copytree(SOURCE, target)
    patch = target / "recommendation-proxy-patch.json"
    patch.write_text(patch.read_text(encoding="utf-8").replace('"drop": ["ALL"]', '"add": ["NET_ADMIN"]'), encoding="utf-8")
    negative = invoke(target)
    assert negative.returncode != 0
    assert "proxy_capabilities_not_dropped" in negative.stderr or "net_admin_forbidden" in negative.stderr
    print("network_delay_proxy_privilege_negative_fixture=passed")

with tempfile.TemporaryDirectory() as temporary:
    target = Path(temporary) / "overlay"
    shutil.copytree(SOURCE, target)
    config = target / "toxiproxy.json"
    config.write_text(config.read_text(encoding="utf-8").replace('"enabled": true', '"enabled": true, "toxics": []'), encoding="utf-8")
    negative = invoke(target)
    assert negative.returncode != 0
    assert "proxy_config_drift" in negative.stderr or "design_overlay_must_not_contain_toxic" in negative.stderr
    print("network_delay_proxy_toxic_negative_fixture=passed")
