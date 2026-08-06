#!/usr/bin/env python3
"""Short live-process check for canonical UTC worker lifecycle events."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


def main() -> int:
    worker = Path(__file__).with_name("cpu-duty-worker.py")
    result = subprocess.run(
        [
            sys.executable,
            str(worker),
            "--target-millicores", "10",
            "--ramp-seconds", "1",
            "--steady-seconds", "1",
            "--cycle-milliseconds", "10",
            "--maximum-total-seconds", "3",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    events = [json.loads(line) for line in result.stdout.splitlines()]
    started = [event for event in events if event["event"] == "started"]
    completed = [event for event in events if event["event"] == "completed"]
    canonical = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$")
    if len(started) != 1 or len(completed) != 1:
        raise AssertionError("worker lifecycle event count mismatch")
    if not canonical.fullmatch(started[0]["event_utc"]):
        raise AssertionError("started event UTC is not canonical")
    if not canonical.fullmatch(completed[0]["event_utc"]):
        raise AssertionError("completed event UTC is not canonical")
    if not 1.9 <= float(completed[0]["elapsed_seconds"]) <= 2.1:
        raise AssertionError("worker elapsed duration is outside the short fixture tolerance")
    print("cpu_duty_worker_canonical_utc_fixture=passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
