#!/usr/bin/env python3
"""Generate D-148 Week-3 candidate tables and a figure from tracked CPU evidence."""

from __future__ import annotations

import argparse
import csv
import hashlib
import html
import json
import statistics
import subprocess
from pathlib import Path


SEVERITY_ORDER = {"low": 0, "medium": 1, "high": 2}
EXPECTED_COUNTS = {
    "attempts": 35,
    "valid": 21,
    "invalid": 14,
    "valid_normal": 6,
    "valid_fault": 15,
    "invalid_normal": 2,
    "invalid_fault": 12,
}
EXPECTED_AGGREGATES = {
    ("10u", "low"): (3, 50.349, 3.576),
    ("10u", "medium"): (3, 99.649, 4.947),
    ("10u", "high"): (3, 146.941, 2.254),
    ("15u", "low"): (2, 51.098, 5.384),
    ("15u", "medium"): (2, 93.987, 0.704),
    ("15u", "high"): (2, 140.435, 5.312),
}


def git(repo: Path, *arguments: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *arguments],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return result.stdout


def git_json(repo: Path, path: str) -> dict:
    return json.loads(git(repo, "show", f"HEAD:{path}"))


def parse_registry(repo: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    text = git(repo, "show", "HEAD:results_registry.md")
    for line in text.splitlines():
        if not line.startswith("| P1-CPU-001 / "):
            continue
        parts = line.split("|")
        rows.append(
            {
                "run_id": parts[1].strip().removeprefix("P1-CPU-001 / "),
                "status": parts[3].strip(),
                "report": parts[8].strip().strip("`"),
            }
        )
    return rows


def validate_registry(rows: list[dict[str, str]]) -> dict[str, int]:
    valid = [row for row in rows if row["status"] == "completed"]
    invalid = [row for row in rows if row["status"] == "invalid"]
    counts = {
        "attempts": len(rows),
        "valid": len(valid),
        "invalid": len(invalid),
        "valid_normal": sum("normal" in row["run_id"] for row in valid),
        "valid_fault": sum("normal" not in row["run_id"] for row in valid),
        "invalid_normal": sum("normal" in row["run_id"] for row in invalid),
        "invalid_fault": sum("normal" not in row["run_id"] for row in invalid),
    }
    if counts != EXPECTED_COUNTS:
        raise ValueError(f"registry_count_mismatch:{counts}:{EXPECTED_COUNTS}")
    if len({row["run_id"] for row in rows}) != EXPECTED_COUNTS["attempts"]:
        raise ValueError("registry_run_ids_not_unique")
    return counts


def collect_fault_runs(repo: Path, rows: list[dict[str, str]]) -> list[dict]:
    tree = set(git(repo, "ls-tree", "-r", "--name-only", "HEAD").splitlines())
    records: list[dict] = []
    for row in rows:
        run_id = row["run_id"]
        if row["status"] != "completed" or "normal" in run_id:
            continue
        base = f"p0-env/artifacts/P1-CPU-001/{run_id}"
        required = [
            "draft-metadata.json",
            "injector-evidence.json",
            "injector-execution.json",
            "manifestation-evidence.json",
            "run-assessment.json",
        ]
        missing = [name for name in required if f"{base}/{name}" not in tree]
        if missing:
            raise ValueError(f"tracked_fault_evidence_missing:{run_id}:{','.join(missing)}")

        draft = git_json(repo, f"{base}/draft-metadata.json")
        injector = git_json(repo, f"{base}/injector-evidence.json")
        manifestation = git_json(repo, f"{base}/manifestation-evidence.json")
        assessment = git_json(repo, f"{base}/run-assessment.json")
        identities = {
            draft["run_id"],
            injector["run_id"],
            manifestation["run_id"],
            assessment["run_id"],
        }
        if identities != {run_id}:
            raise ValueError(f"tracked_fault_identity_mismatch:{run_id}:{sorted(identities)}")
        if not (
            injector["physical_effect_verified"] is True
            and injector["physical_effect_verification_status"] == "passed"
            and assessment["valid_run"] is True
            and assessment["physical_effect_verified"] is True
            and assessment["pod_lifecycle_stable"] is True
            and assessment["host_health"]["whea_event_17_delta"] == 0
            and assessment["host_health"]["kernel_power_41_delta"] == 0
            and assessment["host_health"]["bugcheck_delta"] == 0
            and manifestation["slo_id"] == "p1-cpu-001-slo-v1"
            and manifestation["failure_manifestation"] is None
            and manifestation["manifestation_trigger"] is None
        ):
            raise ValueError(f"tracked_fault_contract_failed:{run_id}")

        severity = next(
            (candidate for candidate in SEVERITY_ORDER if f"-{candidate}-" in run_id),
            None,
        )
        if severity is None:
            raise ValueError(f"severity_unresolved:{run_id}")
        physical = injector["physical_effect"]
        records.append(
            {
                "run_id": run_id,
                "workload": "15u" if run_id.startswith("ob-cpu-15u-") else "10u",
                "severity": severity,
                "profile": injector["fault_profile_id"],
                "increase_m": float(physical["steady_minus_baseline_mean_millicores"]),
                "baseline_intervals": int(physical["baseline_cpu_interval_count"]),
                "steady_intervals": int(physical["steady_cpu_interval_count"]),
                "complete_windows": int(manifestation["complete_window_count"]),
                "failure_manifestation": None,
            }
        )
    if len(records) != EXPECTED_COUNTS["valid_fault"]:
        raise ValueError(f"valid_fault_record_count:{len(records)}")
    return sorted(
        records,
        key=lambda row: (row["workload"], SEVERITY_ORDER[row["severity"]], row["run_id"]),
    )


def aggregate_fault_runs(records: list[dict]) -> list[dict]:
    groups: dict[tuple[str, str], list[dict]] = {}
    for record in records:
        groups.setdefault((record["workload"], record["severity"]), []).append(record)
    aggregates: list[dict] = []
    for key in sorted(groups, key=lambda item: (item[0], SEVERITY_ORDER[item[1]])):
        group = groups[key]
        values = [record["increase_m"] for record in group]
        mean = statistics.mean(values)
        sample_sd = statistics.stdev(values)
        row = {
            "workload": key[0],
            "severity": key[1],
            "n": len(values),
            "mean_m": round(mean, 3),
            "sample_sd_m": round(sample_sd, 3),
            "cv_percent": round(100 * sample_sd / mean, 3),
            "min_m": round(min(values), 3),
            "max_m": round(max(values), 3),
            "positive_manifestations": 0,
        }
        expected = EXPECTED_AGGREGATES.get(key)
        actual = (row["n"], row["mean_m"], row["cv_percent"])
        if actual != expected:
            raise ValueError(f"aggregate_mismatch:{key}:{actual}:{expected}")
        aggregates.append(row)
    if len(aggregates) != 6:
        raise ValueError(f"aggregate_cell_count:{len(aggregates)}")
    return aggregates


def write_csv(path: Path, fieldnames: list[str], rows: list[dict]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def markdown_table(headers: list[str], rows: list[list[object]]) -> str:
    lines = [
        "| " + " | ".join(headers) + " |",
        "| " + " | ".join("---" for _ in headers) + " |",
    ]
    lines.extend("| " + " | ".join(str(value) for value in row) + " |" for row in rows)
    return "\n".join(lines) + "\n"


def physical_effect_svg(aggregates: list[dict]) -> str:
    width, height = 1000, 640
    left, right, top, bottom = 100, 50, 105, 145
    plot_width = width - left - right
    plot_height = height - top - bottom
    y_max = 175.0
    severity_x = {"low": left + plot_width * 0.17, "medium": left + plot_width * 0.5, "high": left + plot_width * 0.83}
    styles = {"10u": ("#2C7FB8", -18), "15u": ("#D95F0E", 18)}

    def y(value: float) -> float:
        return top + plot_height * (1 - value / y_max)

    lines = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        '<style>text{font-family:Arial,sans-serif;fill:#202124}.title{font-size:24px;font-weight:700}.sub{font-size:14px}.axis{font-size:13px}.note{font-size:12px;fill:#4b5563}</style>',
        '<text class="title" x="500" y="36" text-anchor="middle">Tracked CPU actuation (candidate figure)</text>',
        '<text class="sub" x="500" y="62" text-anchor="middle">Mean steady-minus-baseline recommendationservice CPU increase</text>',
    ]
    for tick in range(0, 176, 25):
        yy = y(float(tick))
        lines.append(f'<line x1="{left}" y1="{yy:.2f}" x2="{width-right}" y2="{yy:.2f}" stroke="#e5e7eb"/>')
        lines.append(f'<text class="axis" x="{left-12}" y="{yy+4:.2f}" text-anchor="end">{tick}</text>')
    lines.extend(
        [
            f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+plot_height}" stroke="#111827"/>',
            f'<line x1="{left}" y1="{top+plot_height}" x2="{width-right}" y2="{top+plot_height}" stroke="#111827"/>',
            f'<text class="axis" x="24" y="{top+plot_height/2}" text-anchor="middle" transform="rotate(-90 24 {top+plot_height/2})">CPU increase (millicores)</text>',
        ]
    )
    for severity, xx in severity_x.items():
        lines.append(f'<text class="axis" x="{xx:.2f}" y="{top+plot_height+27}" text-anchor="middle">{html.escape(severity)}</text>')

    for row in aggregates:
        color, offset = styles[row["workload"]]
        xx = severity_x[row["severity"]] + offset
        center = y(row["mean_m"])
        upper = y(row["mean_m"] + row["sample_sd_m"])
        lower = y(row["mean_m"] - row["sample_sd_m"])
        lines.extend(
            [
                f'<line x1="{xx:.2f}" y1="{upper:.2f}" x2="{xx:.2f}" y2="{lower:.2f}" stroke="{color}" stroke-width="3"/>',
                f'<line x1="{xx-7:.2f}" y1="{upper:.2f}" x2="{xx+7:.2f}" y2="{upper:.2f}" stroke="{color}" stroke-width="3"/>',
                f'<line x1="{xx-7:.2f}" y1="{lower:.2f}" x2="{xx+7:.2f}" y2="{lower:.2f}" stroke="{color}" stroke-width="3"/>',
                f'<circle cx="{xx:.2f}" cy="{center:.2f}" r="7" fill="{color}"/>',
                f'<text class="axis" x="{xx:.2f}" y="{upper-9:.2f}" text-anchor="middle">n={row["n"]}</text>',
            ]
        )
    legend_y = height - 78
    for index, workload in enumerate(("10u", "15u")):
        color, _ = styles[workload]
        xx = 360 + index * 170
        lines.append(f'<circle cx="{xx}" cy="{legend_y}" r="6" fill="{color}"/>')
        lines.append(f'<text class="axis" x="{xx+14}" y="{legend_y+4}">{workload} workload</text>')
    lines.extend(
        [
            f'<text class="note" x="500" y="{height-42}" text-anchor="middle">Error bars show sample SD, not confidence intervals; cells are descriptive same-host evidence.</text>',
            f'<text class="note" x="500" y="{height-22}" text-anchor="middle">Frozen-SLO manifestation: 0/15 valid fault runs. Final-receipt replay remains incomplete.</text>',
            "</svg>",
        ]
    )
    return "\n".join(lines) + "\n"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build(repo: Path, output_root: Path) -> None:
    if output_root.exists() and any(output_root.iterdir()):
        raise SystemExit(f"output_root_not_empty:{output_root}")
    output_root.mkdir(parents=True, exist_ok=True)

    rows = parse_registry(repo)
    counts = validate_registry(rows)
    records = collect_fault_runs(repo, rows)
    aggregates = aggregate_fault_runs(records)
    head = git(repo, "rev-parse", "HEAD").strip()

    accounting_rows = [
        {"category": "all_attempts", "count": counts["attempts"], "interpretation": "unique P1-CPU-001 attempts"},
        {"category": "registry_valid", "count": counts["valid"], "interpretation": "6 normal + 15 fault"},
        {"category": "invalid", "count": counts["invalid"], "interpretation": "preserved, excluded from effect denominators"},
        {"category": "valid_normal", "count": counts["valid_normal"], "interpretation": "registry-valid normal runs"},
        {"category": "valid_fault", "count": counts["valid_fault"], "interpretation": "tracked fault contracts audited"},
        {"category": "positive_manifestation", "count": 0, "interpretation": "among 15 valid fault runs"},
    ]
    write_csv(output_root / "table-01-run-accounting.csv", ["category", "count", "interpretation"], accounting_rows)
    (output_root / "table-01-run-accounting.md").write_text(
        "# Candidate Table 1 — P1-CPU-001 run accounting\n\n"
        "Tracked evidence only; receipt replay incomplete.\n\n"
        + markdown_table(
            ["Category", "Count", "Interpretation"],
            [[row["category"], row["count"], row["interpretation"]] for row in accounting_rows],
        ),
        encoding="utf-8",
    )

    aggregate_fields = ["workload", "severity", "n", "mean_m", "sample_sd_m", "cv_percent", "min_m", "max_m", "positive_manifestations"]
    write_csv(output_root / "table-02-physical-effect.csv", aggregate_fields, aggregates)
    (output_root / "table-02-physical-effect.md").write_text(
        "# Candidate Table 2 — Descriptive physical CPU effect\n\n"
        "Means, sample SD and CV are descriptive same-host summaries, not population estimates.\n\n"
        + markdown_table(
            ["Workload", "Severity", "n", "Mean mCPU", "Sample SD", "CV %", "Range mCPU", "Positive manifestations"],
            [[row["workload"], row["severity"], row["n"], f'{row["mean_m"]:.3f}', f'{row["sample_sd_m"]:.3f}', f'{row["cv_percent"]:.3f}', f'{row["min_m"]:.3f}–{row["max_m"]:.3f}', row["positive_manifestations"]] for row in aggregates],
        ),
        encoding="utf-8",
    )

    run_fields = ["run_id", "workload", "severity", "profile", "increase_m", "baseline_intervals", "steady_intervals", "complete_windows", "failure_manifestation"]
    csv_records = [{**record, "increase_m": f'{record["increase_m"]:.6f}', "failure_manifestation": "null"} for record in records]
    write_csv(output_root / "table-03-valid-fault-runs.csv", run_fields, csv_records)
    (output_root / "table-03-valid-fault-runs.md").write_text(
        "# Candidate Supplement Table — Valid CPU fault runs\n\n"
        "Membership follows the canonical registry; invalid attempts are not silently included.\n\n"
        + markdown_table(
            ["Run", "Workload", "Severity", "Profile", "CPU increase m", "Coverage", "Windows", "Manifestation"],
            [[record["run_id"], record["workload"], record["severity"], record["profile"], f'{record["increase_m"]:.3f}', f'{record["baseline_intervals"]}/{record["steady_intervals"]}', record["complete_windows"], "null"] for record in records],
        ),
        encoding="utf-8",
    )
    (output_root / "figure-01-physical-effect.svg").write_text(physical_effect_svg(aggregates), encoding="utf-8")

    metadata = {
        "schema_version": 1,
        "artifact_id": "D148-WEEK3-PUBLICATION-CANDIDATES-001",
        "classification": "candidate_tracked_evidence_only",
        "source_head": head,
        "source_inputs": [
            "results_registry.md",
            "p0-env/artifacts/P1-CPU-001/<valid-fault-run>/draft-metadata.json",
            "p0-env/artifacts/P1-CPU-001/<valid-fault-run>/injector-evidence.json",
            "p0-env/artifacts/P1-CPU-001/<valid-fault-run>/manifestation-evidence.json",
            "p0-env/artifacts/P1-CPU-001/<valid-fault-run>/run-assessment.json",
        ],
        "claim_status": {
            "C148-01_to_C148-04": "tracked_evidence_audit_passed",
            "C148-05": "held_receipt_replay_incomplete",
        },
        "receipt_replay_ready": False,
        "receipt_ready_count": 0,
        "receipt_required_count": 21,
        "runtime_used": False,
        "limitations": [
            "Same-host descriptive pilot evidence; no external-validity claim.",
            "Error bars are sample standard deviations, not confidence intervals.",
            "Zero manifestations in 15 valid fault runs is not a powered universal null result.",
            "CPU final receipt and SHA-manifest bundles are absent from this worktree.",
            "No feature-window missingness or model-performance claim is supported.",
        ],
    }
    (output_root / "candidate-metadata.json").write_text(
        json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    (output_root / "README.md").write_text(
        "# D-148 Week 3 candidate publication outputs\n\n"
        "These files are deterministic derivatives of tracked Git evidence, not a new source of truth.\n\n"
        "Regenerate into an empty directory with:\n\n"
        "```powershell\n"
        "python p0-env/scripts/generate-d148-week3-publication-candidates.py `\n"
        "  --output-root p0-env/artifacts/D148-COURSE-PUBLICATION-001/week-03\n"
        "```\n\n"
        "Do not hand-edit generated tables or figures. The candidate package supports C148-01 through "
        "C148-04 at the tracked-evidence layer. C148-05 remains held because CPU final receipt/SHA-manifest "
        "bundles are unavailable in this worktree. The package authorizes no runtime, relabeling, submission "
        "or publication.\n",
        encoding="utf-8",
    )

    manifest_files = sorted(path for path in output_root.iterdir() if path.is_file())
    manifest = {
        "schema_version": 1,
        "artifact_id": "D148-WEEK3-PUBLICATION-CANDIDATES-001",
        "algorithm": "SHA-256",
        "source_head": head,
        "files": [
            {"path": path.name, "bytes": path.stat().st_size, "sha256": sha256(path)}
            for path in manifest_files
        ],
    }
    (output_root / "sha256-manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument(
        "--output-root",
        type=Path,
        default=Path("p0-env/artifacts/D148-COURSE-PUBLICATION-001/week-03"),
    )
    args = parser.parse_args()
    repo = args.repo_root.resolve()
    output_root = args.output_root
    if not output_root.is_absolute():
        output_root = repo / output_root
    build(repo, output_root.resolve())
    print(f"d148_week3_publication_candidates=generated output={output_root.resolve()}")


if __name__ == "__main__":
    main()
