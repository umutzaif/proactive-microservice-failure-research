#!/usr/bin/env python3
"""Apply the preregistered Toxiproxy latency ramp or verify cleanup."""

from __future__ import annotations

import argparse
import json
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable
from urllib.request import Request, urlopen


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def request_json(base: str, method: str, path: str, payload: dict[str, Any] | None = None) -> Any:
    body = json.dumps(payload).encode("utf-8") if payload is not None else (b"" if method == "POST" else None)
    request = Request(base.rstrip("/") + path, method=method, data=body)
    if body is not None:
        request.add_header("Content-Type", "application/json")
    with urlopen(request, timeout=10) as response:
        raw = response.read()
    return json.loads(raw) if raw else None


def validate_profile(profile: dict[str, Any]) -> None:
    if profile.get("profile_status") != "scientific_run_preregistered_execution_requires_runtime_approval":
        raise ValueError("profile_not_scientifically_preregistered")
    if profile.get("scientific_run_id") != "ob-netdelay-15u-002":
        raise ValueError("unexpected_scientific_run_id")
    injector = profile["injector"]
    if injector["ramp_update_interval_seconds"] != 10 or injector["ramp_latency_ms"] != [63, 125, 188, 250, 313, 375, 438, 500, 563, 625, 688, 750]:
        raise ValueError("ramp_schedule_mismatch")
    if injector["steady_latency_ms"] != 750 or injector["jitter_ms"] != 0 or injector["toxicity"] != 1.0 or injector["stream"] != "downstream":
        raise ValueError("injector_contract_mismatch")


def validate_proxy(proxy: dict[str, Any], profile: dict[str, Any], require_clean: bool = False) -> None:
    target = profile["target_edge"]
    if proxy.get("name") != target["proxy_name"] or proxy.get("listen") != target["proxy_listen"] or proxy.get("upstream") != target["proxy_upstream"] or proxy.get("enabled") is not True:
        raise ValueError("proxy_identity_mismatch")
    toxics = proxy.get("toxics")
    if not isinstance(toxics, list):
        raise ValueError("proxy_toxics_not_list")
    if require_clean and toxics:
        raise ValueError(f"residual_toxics:{len(toxics)}")


def toxic_from(proxy: dict[str, Any], name: str) -> dict[str, Any]:
    values = [item for item in proxy.get("toxics", []) if item.get("name") == name]
    if len(values) != 1:
        raise ValueError(f"expected_one_toxic:{name}:actual={len(values)}")
    return values[0]


def validate_toxic(toxic: dict[str, Any], profile: dict[str, Any], latency_ms: int) -> None:
    injector = profile["injector"]
    expected = {"name": injector["toxic_name"], "type": "latency", "stream": "downstream", "toxicity": 1.0}
    for key, value in expected.items():
        if toxic.get(key) != value:
            raise ValueError(f"toxic_{key}_mismatch")
    attributes = toxic.get("attributes", {})
    if int(attributes.get("latency", -1)) != latency_ms or int(attributes.get("jitter", -1)) != 0:
        raise ValueError("toxic_latency_or_jitter_mismatch")


def ramp(profile: dict[str, Any], api_base: str, requester: Callable[..., Any] = request_json, monotonic: Callable[[], float] = time.monotonic, sleeper: Callable[[float], None] = time.sleep) -> dict[str, Any]:
    validate_profile(profile)
    target, injector = profile["target_edge"], profile["injector"]
    proxy_path = f"/proxies/{target['proxy_name']}"
    before = requester(api_base, "GET", proxy_path)
    validate_proxy(before, profile, require_clean=True)
    start_mono, start_utc = monotonic(), utc_now()
    create_payload = {"name": injector["toxic_name"], "type": "latency", "stream": "downstream", "toxicity": 1.0, "attributes": {"latency": 0, "jitter": 0}}
    requester(api_base, "POST", proxy_path + "/toxics", create_payload)
    created = requester(api_base, "GET", proxy_path)
    validate_toxic(toxic_from(created, injector["toxic_name"]), profile, 0)
    events = [{"step": 0, "target_latency_ms": 0, "applied_utc": utc_now(), "elapsed_monotonic_seconds": monotonic() - start_mono}]
    toxic_path = proxy_path + "/toxics/" + injector["toxic_name"]
    for index, latency in enumerate(injector["ramp_latency_ms"], 1):
        deadline = start_mono + index * injector["ramp_update_interval_seconds"]
        while monotonic() < deadline:
            sleeper(min(1.0, deadline - monotonic()))
        payload = {"name": injector["toxic_name"], "type": "latency", "stream": "downstream", "toxicity": 1.0, "attributes": {"latency": latency, "jitter": 0}}
        requester(api_base, "POST", toxic_path, payload)
        observed = requester(api_base, "GET", proxy_path)
        validate_toxic(toxic_from(observed, injector["toxic_name"]), profile, latency)
        events.append({"step": index, "target_latency_ms": latency, "applied_utc": utc_now(), "elapsed_monotonic_seconds": monotonic() - start_mono})
    elapsed = monotonic() - start_mono
    if elapsed < profile["lifecycle_seconds"]["fault_ramp"]:
        raise ValueError(f"ramp_too_short:{elapsed}")
    return {"schema_version": 1, "evidence_kind": "network-delay-toxic-ramp", "run_id": profile["scientific_run_id"], "ramp_start_utc": start_utc, "ramp_end_utc": utc_now(), "ramp_elapsed_monotonic_seconds": elapsed, "events": events, "final_proxy": requester(api_base, "GET", proxy_path), "cleanup_verified": False}


def cleanup(profile: dict[str, Any], api_base: str, requester: Callable[..., Any] = request_json) -> dict[str, Any]:
    validate_profile(profile)
    name = profile["target_edge"]["proxy_name"]
    path = f"/proxies/{name}"
    before = requester(api_base, "GET", path)
    validate_proxy(before, profile)
    requester(api_base, "POST", "/reset")
    after = requester(api_base, "GET", path)
    validate_proxy(after, profile, require_clean=True)
    return {"schema_version": 1, "evidence_kind": "network-delay-toxic-cleanup", "run_id": profile["scientific_run_id"], "cleanup_utc": utc_now(), "reset_called": True, "before": before, "after": after, "cleanup_verified": True}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-base", required=True)
    parser.add_argument("--profile", type=Path, required=True)
    parser.add_argument("--action", choices=("ramp", "cleanup"), required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    profile = json.loads(args.profile.read_text(encoding="utf-8-sig"))
    if args.evidence.exists():
        raise ValueError("immutable_evidence_already_exists")
    result = ramp(profile, args.api_base) if args.action == "ramp" else cleanup(profile, args.api_base)
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"network_delay_toxic_{args.action}=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
