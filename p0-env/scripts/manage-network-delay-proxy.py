#!/usr/bin/env python3
"""Verify or reset the selected Toxiproxy without creating a toxic."""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.request import Request, urlopen


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def request_json(base: str, method: str, path: str) -> Any:
    request = Request(base.rstrip("/") + path, method=method)
    if method == "POST":
        request.data = b""
        request.add_header("Content-Type", "application/json")
    with urlopen(request, timeout=10) as response:
        body = response.read()
    return json.loads(body) if body else None


def validate_proxy(proxy: dict[str, Any], profile: dict[str, Any], require_clean: bool) -> None:
    target = profile["target_edge"]
    if proxy.get("name") != target["proxy_name"]:
        raise ValueError("proxy_name_mismatch")
    if proxy.get("listen") != target["proxy_listen"]:
        raise ValueError("proxy_listen_mismatch")
    if proxy.get("upstream") != target["proxy_upstream"]:
        raise ValueError("proxy_upstream_mismatch")
    if proxy.get("enabled") is not True:
        raise ValueError("proxy_not_enabled")
    toxics = proxy.get("toxics")
    if not isinstance(toxics, list):
        raise ValueError("proxy_toxics_not_list")
    if require_clean and toxics:
        raise ValueError(f"residual_toxics:{len(toxics)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-base", required=True)
    parser.add_argument("--profile", type=Path, required=True)
    parser.add_argument("--action", choices=("verify-clean", "reset"), required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    profile = json.loads(args.profile.read_text(encoding="utf-8-sig"))
    if profile.get("profile_status") != "design_frozen_not_authorized_for_scientific_run":
        raise ValueError("unexpected_profile_status")
    name = profile["target_edge"]["proxy_name"]
    before = request_json(args.api_base, "GET", f"/proxies/{name}")
    validate_proxy(before, profile, require_clean=args.action == "verify-clean")
    reset_called = False
    if args.action == "reset":
        request_json(args.api_base, "POST", "/reset")
        reset_called = True
    after = request_json(args.api_base, "GET", f"/proxies/{name}")
    validate_proxy(after, profile, require_clean=True)
    evidence = {
        "schema_version": 1,
        "evidence_kind": "network-delay-proxy-clean-state",
        "action": args.action,
        "observed_utc": utc_now(),
        "proxy_name": name,
        "reset_called": reset_called,
        "before": before,
        "after": after,
        "cleanup_verified": True,
        "scientific_fault_started": False,
    }
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print("network_delay_proxy_clean_state=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
