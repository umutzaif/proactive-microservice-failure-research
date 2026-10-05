#!/usr/bin/env python3
import importlib.util
import json
import shutil
import tempfile
import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = Path(__file__).with_name("verify-network-delay-headroom-decision-inputs.py")
SPEC = importlib.util.spec_from_file_location("headroom_inputs", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
SPEC.loader.exec_module(MODULE)


def mutate(field: str, value: object, source_root: Path) -> list[str]:
    with tempfile.TemporaryDirectory() as directory:
        clone = Path(directory) / "repo"
        target = clone / "p0-env/config/analysis/network-delay-headroom-decision-inputs-v1.json"
        shutil.copytree(ROOT / "p0-env/config", clone / "p0-env/config")
        source_base = source_root / "kustomize/base/recommendationservice.yaml"
        target_base = clone / "p0-env/source/microservices-demo/kustomize/base/recommendationservice.yaml"
        target_base.parent.mkdir(parents=True)
        shutil.copy2(source_base, target_base)
        profile = json.loads(target.read_text(encoding="utf-8"))
        if field == "eligible_count":
            profile["current_eligibility_snapshot"]["eligible_500m_normal_run_count_15u"] = value
        elif field == "profile_status":
            profile["profile_status"] = value
        elif field == "authorization":
            profile["execution_authorized"] = value
        elif field == "historical":
            profile["eligible_normal_run_contract"]["historical_750ms_fault_runs_eligible"] = value
        elif field == "choice":
            profile["resolved_academic_choices"]["normal_topology"]["recommended"] = value
        elif field == "replacement":
            profile["collection_sequence"]["effective_collection_run_ids"][3] = value
        elif field == "invalid":
            profile["collection_sequence"]["invalid_run_ids"].remove(value)
        target.write_text(json.dumps(profile), encoding="utf-8")
        return MODULE.verify(clone, clone / "p0-env/source/microservices-demo")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--online-boutique-source-root", type=Path, required=True)
    args = parser.parse_args()
    source_root = args.online_boutique_source_root.resolve()
    assert (source_root / "kustomize/base/recommendationservice.yaml").is_file()
    assert not MODULE.verify(ROOT, source_root)
    assert "identity" in mutate("profile_status", "academic_choices_resolved_collection_tooling_pending", source_root)
    assert "blocked_snapshot" in mutate("eligible_count", 3, source_root)
    assert "not_authorized" in mutate("authorization", True, source_root)
    assert "historical_exclusions" in mutate("historical", True, source_root)
    assert "choices_resolved" in mutate("choice", "base_topology", source_root)
    assert "formula_and_sequence" in mutate("replacement", "ob-netdelay-500m-normal-10u-004", source_root)
    assert "formula_and_sequence" in mutate("replacement", "ob-netdelay-500m-normal-10u-005", source_root)
    assert "formula_and_sequence" in mutate("replacement", "ob-netdelay-500m-normal-10u-003", source_root)
    assert "formula_and_sequence" in mutate("invalid", "ob-netdelay-500m-normal-10u-004", source_root)
    assert "formula_and_sequence" in mutate("invalid", "ob-netdelay-500m-normal-10u-005", source_root)
    print("network_delay_headroom_inputs_positive=passed")
    print("network_delay_headroom_eligible_count_negative=passed")
    assert "formula_and_sequence" in mutate("replacement", "ob-netdelay-500m-normal-10u-006", source_root)
    assert "formula_and_sequence" in mutate("invalid", "ob-netdelay-500m-normal-10u-006", source_root)
    print("network_delay_headroom_authorization_negative=passed")
    print("network_delay_headroom_historical_leakage_negative=passed")
    print("network_delay_headroom_choice_mutation_negative=passed")
    assert "formula_and_sequence" in mutate("replacement", "ob-netdelay-500m-normal-10u-007", source_root)
    assert "formula_and_sequence" in mutate("invalid", "ob-netdelay-500m-normal-10u-007", source_root)
    assert "formula_and_sequence" in mutate("replacement", "ob-netdelay-500m-normal-10u-008", source_root)
    assert "formula_and_sequence" in mutate("invalid", "ob-netdelay-500m-normal-10u-008", source_root)
    assert "formula_and_sequence" in mutate("replacement", "ob-netdelay-500m-normal-10u-009", source_root)
    assert "formula_and_sequence" in mutate("invalid", "ob-netdelay-500m-normal-10u-009", source_root)
    assert "formula_and_sequence" in mutate("replacement", "ob-netdelay-500m-normal-10u-010", source_root)
    assert "formula_and_sequence" in mutate("invalid", "ob-netdelay-500m-normal-10u-010", source_root)
    assert "formula_and_sequence" in mutate("replacement", "ob-netdelay-500m-normal-10u-011", source_root)
    assert "formula_and_sequence" in mutate("invalid", "ob-netdelay-500m-normal-10u-011", source_root)
    assert "formula_and_sequence" in mutate("replacement", None, source_root)
    print("d127_consumed_id_and_preregistered_slot_negative=passed cases=18")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
