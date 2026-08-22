#!/usr/bin/env python3
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = Path(__file__).with_name("verify-network-delay-headroom-decision-inputs.py")
SPEC = importlib.util.spec_from_file_location("headroom_inputs", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


def mutate(field: str, value: object) -> list[str]:
    with tempfile.TemporaryDirectory() as directory:
        clone = Path(directory) / "repo"
        target = clone / "p0-env/config/analysis/network-delay-headroom-decision-inputs-v1.json"
        shutil.copytree(ROOT / "p0-env/config", clone / "p0-env/config")
        source_base = ROOT / "p0-env/source/microservices-demo/kustomize/base/recommendationservice.yaml"
        target_base = clone / "p0-env/source/microservices-demo/kustomize/base/recommendationservice.yaml"
        target_base.parent.mkdir(parents=True)
        shutil.copy2(source_base, target_base)
        profile = json.loads(target.read_text(encoding="utf-8"))
        if field == "eligible_count":
            profile["current_eligibility_snapshot"]["eligible_500m_normal_run_count_15u"] = value
        elif field == "authorization":
            profile["execution_authorized"] = value
        elif field == "historical":
            profile["eligible_normal_run_contract"]["historical_750ms_fault_runs_eligible"] = value
        elif field == "choice":
            profile["resolved_academic_choices"]["normal_topology"]["recommended"] = value
        target.write_text(json.dumps(profile), encoding="utf-8")
        return MODULE.verify(clone)


def main() -> int:
    assert not MODULE.verify(ROOT)
    assert "blocked_snapshot" in mutate("eligible_count", 3)
    assert "not_authorized" in mutate("authorization", True)
    assert "historical_exclusions" in mutate("historical", True)
    assert "choices_resolved" in mutate("choice", "base_topology")
    print("network_delay_headroom_inputs_positive=passed")
    print("network_delay_headroom_eligible_count_negative=passed")
    print("network_delay_headroom_authorization_negative=passed")
    print("network_delay_headroom_historical_leakage_negative=passed")
    print("network_delay_headroom_choice_mutation_negative=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
