# P2 Network-Delay Headroom Decision-Support Gate

## Purpose

This artifact turns D-061 through D-063 into a falsifiable input contract before any
new normal or fault run. It does not estimate headroom from ineligible historical data,
select a delay level, authorize collection, or change the frozen SLO.

## Current evidence boundary

The repository contains valid historical normal runs collected with a 200m
recommendationservice CPU limit, and valid exploratory 750ms fault runs under the 500m
profile. D-063 excludes both categories from the new 500m normal distribution. The
current eligible count is therefore 0/3 for 10 users and 0/3 for 15 users. A numeric
feasibility conclusion would currently be fabricated.

## Required future inputs

For each of `ob-default-10u-1r-v1` and `ob-second-15u-1r-v1`, the calculation requires
at least three independent valid no-fault runs under the exact 500m/100m resource
contract. Each run must preserve its product-detail window-p95 distribution, null frozen
SLO manifestation, pod lifecycle, host 0/0/0, schema-v3 telemetry, and final receipt.
Five-second windows describe a run; they do not increase the independent sample size.

The prospective calculation for each workload and delay candidate is:

`SLO headroom = 594.664ms - selected normal upper bound`

`expected margin = candidate delay - SLO headroom - uncertainty margin`

This is decision support, not a manifestation claim. Queueing, request fan-out, trace
coverage, and nonlinear behavior can make observed frontend latency differ from the
injected edge delay.

## Academic choices that remain open

1. Baseline topology. The recommended option is the same no-toxic proxy overlay used by
   ladder treatment runs; the base topology is an alternative. Overlay matching reduces
   configuration confounding but adds an operational component to every normal run.
2. Upper bound and uncertainty method. The recommended small-sample option is the
   maximum of the independent run-level upper-tail summaries plus a separately
   preregistered measurement margin. Bootstrap or parametric upper bounds are
   alternatives, but three runs provide weak tail estimation and stronger assumptions.

These choices must be accepted in a new research decision before normal-run IDs and an
executable analyzer are frozen. No result from `008` or `repeat-001` may be used to tune
the choice.

## Independent verification and falsification

Run `verify-network-delay-headroom-decision-inputs.py` against the repository. It must
pass the static contract while reporting the calculation as blocked. Mutating either
eligible count, authorizing execution, admitting 200m/750ms evidence, resolving a pending
choice without a decision, or changing the ladder/SLO must fail the fixture suite.

## File role

The JSON profile is the machine-readable decision-input source. This document explains
why it exists and how to challenge it. The eventual analyzer will consume a later,
academically approved version rather than embedding choices in code.
