# Week 9 Technical Method Addendum

This addendum supplies audience-critical method detail from existing versioned
contracts. It does not change an experiment, threshold, label or conclusion.

## Treatment and target contract

The target was the `recommendationservice` server container with a 200 mCPU
limit. Versioned low, medium and high profiles requested approximately +50,
+100 and +150 mCPU through an in-container Python duty-cycle worker operating on
a 100 ms cycle. Each profile used a 120 s linear ramp and 300 s steady phase.
Automatic termination was mandatory, total worker time was bounded by 450 s,
and worker `started`/`completed` events supplied the canonical lifecycle UTC
boundary with a +/-5 s duration tolerance.

The 15-user profiles changed only the workload binding and profile identity;
fault physics, target, durations, effect gates and SLO remained equivalent to
their 10-user counterparts.

## Workload contract

Both workload profiles used one loadgenerator replica, one user spawned per
second, a uniform 1-10 s wait, random seed 1, Locust 2.43.0 and the same pinned
task mix: index 1, setCurrency 2, browseProduct 10, addToCart 2, viewCart 3 and
checkout 1. The only planned workload difference was 10 versus 15 concurrent
users. Each run used a 300 s warm-up and 300 s normal baseline. The full fault
lifecycle was 300/300/120/300/300 s for warm-up, baseline, ramp, steady and
cooldown.

## Physical-effect eligibility

Prometheus target-container CPU measurements independently tested actuation.
Baseline and steady phases each required at least 48 adjacent real-scrape CPU
rate intervals out of 60 expected intervals at the observed five-second
cadence. Low, medium and high profiles additionally required mean
steady-minus-baseline increases of at least 25, 50 and 75 mCPU, respectively.
Both coverage and magnitude had to pass. Injector command success alone was
insufficient. Throttling was reported but did not count as SLO manifestation.

## Frozen service manifestation

Five-second non-overlapping windows were anchored to
`normal_baseline_start_utc` and continued without phase realignment through
cooldown. Manifestation required product-detail-family p95 latency greater than
345.992 ms or global user-route error rate greater than zero for three
consecutive populated windows. Empty windows reset the streak, and the event
time was the end of the third violating window.

## Denominator and invalid-attempt audit

The 35 unique attempts contain 21 valid runs: six normal controls and 15 fault
runs. Fourteen attempts remain invalid and visible. For audit explanation only,
they group into two invalid normal baselines, five fault attempts that stopped
before actuation and seven attempts with later lifecycle, physical-effect or
finalization failures. These groups are operational explanations rather than
new scientific labels. None of the 14 attempts enters an effect or
manifestation denominator.

## Descriptive result detail

Observed steady-minus-baseline CPU-increase ranges were:

- 10 users: low 48.463-52.050, medium 93.994-103.042, high
  143.819-150.416 mCPU;
- 15 users: low 49.153-53.044, medium 93.519-94.454, high
  135.160-145.710 mCPU.

The reported SD values are sample standard deviations. Ranges, SD and CV
describe accepted runs only; none is a confidence interval or causal estimate.
