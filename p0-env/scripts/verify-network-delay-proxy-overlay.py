#!/usr/bin/env python3
"""Fail closed on network-delay proxy overlay drift without applying it."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

EXPECTED_IMAGE = "ghcr.io/shopify/toxiproxy:2.12.0@sha256:a3e244375123dad8849091bcc59775e188624d3f602db01901f9af855682fef8"
EXPECTED_PROXY = {
    "name": "recommendation-to-productcatalog",
    "listen": "127.0.0.1:3551",
    "upstream": "productcatalogservice:3550",
    "enabled": True,
}


def named(items: list[dict], name: str, kind: str) -> dict:
    matches = [item for item in items if item.get("name") == name]
    if len(matches) != 1:
        raise ValueError(f"expected_one_{kind}:{name}:found={len(matches)}")
    return matches[0]


def verify(root: Path) -> None:
    patch = json.loads((root / "recommendation-proxy-patch.json").read_text(encoding="utf-8-sig"))
    if patch.get("kind") != "Deployment" or patch.get("metadata", {}).get("name") != "recommendationservice":
        raise ValueError("wrong_target_deployment")
    pod_spec = patch["spec"]["template"]["spec"]
    containers = pod_spec.get("containers", [])
    server = named(containers, "server", "server_container")
    env = named(server.get("env", []), "PRODUCT_CATALOG_SERVICE_ADDR", "target_env")
    if env.get("value") != "127.0.0.1:3551":
        raise ValueError("target_env_not_proxy_localhost")

    proxy = named(containers, "network-delay-proxy", "proxy_container")
    if proxy.get("image") != EXPECTED_IMAGE:
        raise ValueError("proxy_image_not_digest_pinned")
    security = proxy.get("securityContext", {})
    if security.get("privileged") is not False or security.get("allowPrivilegeEscalation") is not False:
        raise ValueError("proxy_privilege_not_denied")
    if security.get("capabilities", {}).get("drop") != ["ALL"]:
        raise ValueError("proxy_capabilities_not_dropped")
    if security.get("capabilities", {}).get("add"):
        raise ValueError("proxy_capability_add_forbidden")
    if "NET_ADMIN" in json.dumps(patch):
        raise ValueError("net_admin_forbidden")

    proxy_config = json.loads((root / "toxiproxy.json").read_text(encoding="utf-8-sig"))
    if proxy_config != [EXPECTED_PROXY]:
        raise ValueError("proxy_config_drift")
    if "toxic" in json.dumps(proxy_config).lower():
        raise ValueError("design_overlay_must_not_contain_toxic")

    kustomization = (root / "kustomization.yaml").read_text(encoding="utf-8-sig")
    if "  - ../online-boutique" not in kustomization:
        raise ValueError("unexpected_base_resource")
    if "  - path: recommendation-proxy-patch.json" not in kustomization:
        raise ValueError("unexpected_patch_set")
    print("network_delay_proxy_overlay_verification=passed")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--overlay-root", type=Path, required=True)
    args = parser.parse_args()
    verify(args.overlay_root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
