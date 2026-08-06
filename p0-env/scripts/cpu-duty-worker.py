#!/usr/bin/env python3
"""Bounded CPU duty-cycle worker executed inside the target container."""

from __future__ import annotations

import argparse
import json
import time
from datetime import datetime, timezone


def emit(event: str, **values: object) -> None:
    event_utc = datetime.now(timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    print(
        json.dumps(
            {
                "event": event,
                "event_utc": event_utc,
                "monotonic_seconds": time.monotonic(),
                **values,
            }
        ),
        flush=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target-millicores", type=int, required=True)
    parser.add_argument("--ramp-seconds", type=int, required=True)
    parser.add_argument("--steady-seconds", type=int, required=True)
    parser.add_argument("--cycle-milliseconds", type=int, required=True)
    parser.add_argument("--maximum-total-seconds", type=int, required=True)
    args = parser.parse_args()

    total_seconds = args.ramp_seconds + args.steady_seconds
    if not 1 <= args.target_millicores <= 1000:
        raise ValueError("target millicores must be within 1..1000")
    if args.ramp_seconds < 1 or args.steady_seconds < 1:
        raise ValueError("ramp and steady durations must be positive")
    if total_seconds > args.maximum_total_seconds or args.maximum_total_seconds > 900:
        raise ValueError("bounded-duration safety rule failed")
    if not 10 <= args.cycle_milliseconds <= 1000:
        raise ValueError("cycle milliseconds must be within 10..1000")

    cycle_seconds = args.cycle_milliseconds / 1000
    target_fraction = args.target_millicores / 1000
    started = time.monotonic()
    deadline = started + total_seconds
    next_heartbeat = started
    emit(
        "started",
        target_millicores=args.target_millicores,
        ramp_seconds=args.ramp_seconds,
        steady_seconds=args.steady_seconds,
        total_seconds=total_seconds,
    )

    cycles = 0
    while True:
        cycle_started = time.monotonic()
        elapsed = cycle_started - started
        if cycle_started >= deadline:
            break
        ramp_fraction = min(1.0, elapsed / args.ramp_seconds)
        busy_seconds = cycle_seconds * target_fraction * ramp_fraction
        busy_deadline = min(deadline, cycle_started + busy_seconds)
        accumulator = 0
        while time.monotonic() < busy_deadline:
            accumulator = (accumulator * 33 + 17) % 1_000_003
        cycles += 1
        now = time.monotonic()
        if now >= next_heartbeat:
            emit("heartbeat", elapsed_seconds=elapsed, demand_fraction=target_fraction * ramp_fraction, cycles=cycles)
            next_heartbeat = now + 5
        remaining = cycle_seconds - (time.monotonic() - cycle_started)
        if remaining > 0:
            time.sleep(min(remaining, max(0.0, deadline - time.monotonic())))

    emit("completed", elapsed_seconds=time.monotonic() - started, cycles=cycles)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
