#!/usr/bin/env python3
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("control_contract", Path(__file__).with_name("verify-network-delay-control-contract.py"))
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


def main() -> int:
    assert not MODULE.verify(ROOT)
    with tempfile.TemporaryDirectory() as directory:
        clone = Path(directory) / "repo"
        for relative in ("p0-env/config/controls", "p0-env/artifacts/P2-NETWORK-DELAY-REPEATABILITY-001/randomization-plan.json"):
            source = ROOT / relative
            destination = clone / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            if source.is_dir():
                shutil.copytree(source, destination)
            else:
                shutil.copy2(source, destination)
        profile_path = clone / "p0-env/config/controls/network-delay-no-toxic-control-15u-v1.json"
        profile = json.loads(profile_path.read_text(encoding="utf-8"))
        profile["treatment_contract"]["toxic_creation_allowed"] = True
        profile_path.write_text(json.dumps(profile), encoding="utf-8")
        assert "no_toxic" in MODULE.verify(clone)
        profile["treatment_contract"]["toxic_creation_allowed"] = False
        profile["profile_status"] = "preregistered_control_contract_runner_not_implemented"
        profile_path.write_text(json.dumps(profile), encoding="utf-8")
        assert "not_authorized" in MODULE.verify(clone)
    print("network_delay_control_contract_positive=passed")
    print("network_delay_control_toxic_allowed_negative=passed")
    print("network_delay_control_superseded_status_negative=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
