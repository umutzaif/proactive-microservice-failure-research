# When CPU Fault Actuation Does Not Manifest as an SLO Violation

## An Evidence Bounded Microservice Case Study

**Anonymous manuscript for academic review**

## Abstract

Fault injection is often treated as evidence of service failure once an injector reports success. This shortcut conflates the requested treatment, its measured physical effect, and the user-visible service outcome. We present an evidence-bounded case study of CPU stress against `recommendationservice` in a local Online Boutique deployment. Two workload levels and three versioned CPU-stress profiles were evaluated. Across 35 unique attempts, prospectively defined fail-closed gates retained 21 valid runs, including six normal controls and 15 fault runs, while preserving 14 invalid attempts outside scientific outcome denominators. The accepted fault runs showed ordered descriptive CPU actuation. Mean steady-minus-baseline increases were 50.349, 99.649, and 146.941 mCPU at 10 users and 51.098, 93.987, and 140.435 mCPU at 15 users. Nevertheless, none of the 15 valid fault runs manifested the frozen latency-or-error service-level objective, leaving no eligible positive lead-time event. The study contributes a measured separation between actuation and manifestation, an auditable validity-denominator design, and a layered reproducibility account that distinguishes tracked evidence from unavailable receipt-level replay. The result is a bounded negative observation for the tested host and profiles. It is not a universal claim about CPU faults, a causal effect estimate, or a predictive-model evaluation.

**Keywords:** microservices; fault injection; negative results; service-level objectives; reproducibility; evidence governance; chaos engineering

## 1 Introduction

Microservice reliability studies use fault injection to expose weaknesses, evaluate resilience, and create incidents for anomaly detection or root-cause analysis. Modern systems can inject faults at many locations and at request, service, network, or infrastructure level. This flexibility does not remove the need to demonstrate that a requested fault changed the intended physical quantity and then produced the outcome relevant to the research question. A successful command or injector event proves neither condition by itself.

The distinction matters when an experiment is intended to support early warning. If every injected interval is labeled as a positive failure, a later detector may learn the injection schedule or a resource movement rather than a service-level manifestation. It may then appear accurate without predicting a user-visible event. The same problem affects denominators. Infrastructure or lifecycle failures can be mistaken for negative treatments, silently removed, or retried under the same identity. Each choice changes the scientific population after outcomes are known.

Prior fault-injection systems emphasize precision, coverage, search efficiency, and the ability to expose subtle failures [1-4]. Recent microservice studies also combine metrics, logs, traces, graphs, and large language models for diagnosis and recovery [5-7]. These are valuable downstream capabilities. The present study addresses an earlier empirical gate: whether accepted CPU-stress treatments created eligible positive incidents under a frozen service-level objective.

We ask three research questions.

1. **RQ1 Physical actuation.** Did the tested low, medium, and high CPU-stress profiles produce descriptively repeatable actuation under the recorded 10-user and 15-user workloads?
2. **RQ2 Service manifestation.** Did any of the 15 valid fault runs manifest the frozen service-level objective or yield an eligible positive lead-time event?
3. **RQ3 Evidence governance.** Did fail-closed gates preserve an auditable separation between 21 valid runs and 14 invalid attempts, and which reproducibility layers remain incomplete?

The study makes three bounded contributions. First, it empirically separates physical actuation from frozen-SLO manifestation in the tested same-host setting. Second, it shows how fail-closed accounting can preserve every attempt while limiting scientific denominators to eligible runs. Third, it reports reproducibility as layers rather than as a binary label: tracked registry, report, configuration, and derived-output checks are available, whereas independent receipt-level replay is unavailable for all 21 valid runs.

These contributions are methodological and descriptive. The study does not propose a new root-cause algorithm, train a predictive model, estimate a causal treatment effect, or generalize beyond the recorded host, deployment, workloads, target service, profiles, and SLO.

## 2 Related Work and Research Gap

### 2.1 Fault injection and chaos experimentation

Fault injection has long been used to measure how systems behave under controlled failure. Loki demonstrated that distributed-system experiments can require state-aware injection, timeline reconstruction, and the rejection of executions with incorrect injections before dependability measures are estimated [1]. Legolas similarly separates the mechanics of injecting faults from the task of exposing partial-failure bugs, using inferred abstract states to guide exploration [2]. These studies show that injection is an experimental mechanism, not an outcome label.

MicroFI focuses on request-level injection for microservices and prioritizes high-impact injection solutions while controlling blast radius [3]. An exploratory study of chaos engineering under varying user loads reports that load level can affect observed cloud-native behavior and therefore belongs in the experimental design [4]. Together, these works motivate precise treatment definition and workload control. They do not remove the need to verify the physical effect and the outcome construct used by a particular study.

### 2.2 Root cause analysis and operational agents

MULAN combines metrics and logs with causal-graph learning and root-cause ranking [5]. GALR extends the design space with trace-derived topology, graph attention, language-model priors, and recovery planning [6]. A broader AIOps survey describes the growing role of language models across detection, diagnosis, and remediation [7]. Tool-augmented operational agents can still misread stale signals, select shallow fixes, or use tools unsafely [8]. Accordingly, the present project treats runtime mutation and scientific inference as separate authorities.

The current evidence cannot evaluate these diagnostic or agentic methods. It contains no positive frozen-SLO manifestations and no prospectively frozen feature-window dataset. Any model comparison would therefore be undefined or would substitute injection windows for positive incidents.

### 2.3 Proactive SLO evaluation

Proactive SLO research distinguishes violation prediction, tail-latency prediction, prefix early warning, and actionable diagnosis [9]. Evaluation requires more than a classifier score. It requires real event semantics, independent incidents, false-alarm controls, warning coverage, and lead time. In the present case, zero positive manifestations make these measures unavailable. Windows within a run cannot be counted as independent incidents to manufacture sample size.

### 2.4 Research gap

Existing work provides increasingly sophisticated injection, diagnosis, and recovery mechanisms. A smaller but consequential methodological gap remains between a successful fault request and a scientifically eligible service-level incident. This study examines that gap with explicit treatment, physical-effect, manifestation, validity, and replay contracts. Its novelty claim is therefore not the CPU injector or the negative count alone. The contribution is the evidence chain that shows where the experiment succeeded, where the intended service outcome did not occur, and which later claims must remain blocked.

## 3 Method

### 3.1 Study design and scope

The case study used a local Online Boutique deployment and targeted the server container of `recommendationservice`. All analyzed runs were recorded on the same host. Two versioned workloads were used: 10 concurrent virtual users and 15 concurrent virtual users, each with one load-generator replica. Three CPU-stress severities were evaluated at each workload.

The population is limited to the recorded host, deployment, target service, workload profiles, CPU profiles, and frozen SLO. The design does not support inference to production clusters, other services, different resource limits, or other fault classes.

### 3.2 Workload contract

Both workload profiles used Locust 2.43.0, one user spawned per second, a uniform 1-10 s wait, and random seed 1. The pinned task weights were index 1, set-currency 2, browse-product 10, add-to-cart 2, view-cart 3, and checkout 1. The only planned workload difference was 10 versus 15 concurrent users.

Each run used a 300 s warm-up and a 300 s normal baseline. A fault run then used a 120 s ramp, 300 s steady phase, and 300 s cooldown. The complete planned lifecycle was therefore 300/300/120/300/300 s.

### 3.3 Treatment and safety contract

The target container had a 200 mCPU server limit. Versioned low, medium, and high profiles requested approximately +50, +100, and +150 mCPU through an in-container Python duty-cycle worker with a 100 ms cycle. Each profile used a 120 s linear ramp and 300 s steady phase. Automatic termination was mandatory, total worker time was bounded by 450 s, and worker `started` and `completed` events supplied the canonical lifecycle timestamps with a plus-or-minus five-second duration tolerance.

The 15-user profiles changed only the workload binding and profile identity. Target, fault physics, durations, physical-effect gates, and SLO semantics remained equivalent to the 10-user profiles.

### 3.4 Physical-effect eligibility

Prometheus target-container CPU measurements independently tested actuation. Baseline and steady phases each required at least 48 adjacent real-scrape CPU-rate intervals out of 60 expected intervals at the observed five-second cadence. Low, medium, and high profiles additionally required mean steady-minus-baseline increases of at least 25, 50, and 75 mCPU, respectively. Both coverage and magnitude had to pass. Injector success alone was insufficient. Throttling was reported separately and did not count as SLO manifestation.

### 3.5 Frozen service manifestation

Five-second non-overlapping windows were anchored to `normal_baseline_start_utc` and continued without phase realignment through cooldown. Manifestation required either product-detail-family p95 latency greater than 345.992 ms for three consecutive populated windows or global user-route error rate greater than zero for three consecutive populated windows. Empty windows reset the streak. Event time was the end of the third violating window. The threshold and consecutive-window rule were frozen before fault outcomes were interpreted.

### 3.6 Run eligibility and denominator accounting

The registry contains 35 unique attempts. Twenty-one are valid: six normal controls and 15 fault runs. Fourteen attempts are invalid. For audit explanation, the invalid set contains two invalid normal baselines, five fault attempts stopped before actuation, and seven attempts with later lifecycle, physical-effect, or finalization failures. These groups explain workflow failure timing; they are not new scientific labels.

A run enters a scientific denominator only when its canonical registry status and tracked evidence satisfy the applicable identity, host, lifecycle, physical-effect, and manifestation contracts. Invalid attempts are preserved as operational provenance but are not relabeled, deleted, retried under the same identifier, or counted as successful or negative treatments. The ratio 21/35 is validity accounting, not a treatment success rate.

### 3.7 Analysis

For each workload-by-severity cell, we report the arithmetic mean, sample standard deviation, coefficient of variation, and observed range of the steady-minus-baseline CPU increase. The coefficient of variation is the sample standard deviation divided by the mean. Cell sizes are two or three runs. The analysis is descriptive; sample standard deviation and range are not confidence intervals, and no statistical-significance or equivalence claim is made.

Warning lead time is eligible only when a valid fault run manifests the frozen SLO. Because no valid fault run manifested, no lead-time distribution or predictive performance metric is computed.

### 3.8 Reproducibility layers

The study distinguishes four layers. Canonical governance documents define protocol, labels, results, and claim boundaries. Tracked reports and JSON contracts support attempt accounting and valid-fault outcomes. Deterministic scripts regenerate tables and check manuscript claims. Final receipt bundles would allow independent archive-provenance replay, but this layer is unavailable at zero of 21 expected receipt and SHA-manifest pairs.

The derived analysis is pinned to source revision `0ecb6011189c0a47b46019ec1d626ae7043e19e0`. Text comparisons use normalized LF bytes, while binary outputs use exact bytes. Repository-only replay requires Git, Python's standard library, and PowerShell. It does not require Kubernetes, Docker, Prometheus, Locust, a GPU, network access, or a language-model API.

## 4 Results

### 4.1 Attempt accounting

The 35 attempts comprise 21 valid runs and 14 invalid attempts. The valid set contains six normal controls and 15 fault runs. All invalid attempts remain visible in the registry, but none contributes to the physical-effect or manifestation denominators.

### 4.2 Physical actuation

| Workload | Severity | n | Mean mCPU | Sample SD | CV | Observed range mCPU |
|---|---|---:|---:|---:|---:|---:|
| 10 users | Low | 3 | 50.349 | 1.801 | 3.576% | 48.463-52.050 |
| 10 users | Medium | 3 | 99.649 | 4.930 | 4.947% | 93.994-103.042 |
| 10 users | High | 3 | 146.941 | 3.313 | 2.254% | 143.819-150.416 |
| 15 users | Low | 2 | 51.098 | 2.751 | 5.384% | 49.153-53.044 |
| 15 users | Medium | 2 | 93.987 | 0.661 | 0.704% | 93.519-94.454 |
| 15 users | High | 2 | 140.435 | 7.460 | 5.312% | 135.160-145.710 |

The means are ordered from low to high at both workload levels. Together with the coverage and magnitude gates, this supports a bounded descriptive conclusion: the versioned profiles produced distinguishable physical actuation in the accepted runs. The result does not establish a causal SLO effect or external generality.

### 4.3 Service manifestation and lead time

None of the 15 valid fault runs manifested the frozen SLO. The observed result is 0/15. Consequently, no run contains an eligible positive warning interval. This is zero positive lead-time evidence, not evidence that a proposed warning method succeeded or failed. An SLO event recorded in an invalid normal attempt remains excluded by the validity rule and cannot be reassigned to the valid fault denominator.

### 4.4 Answers to the research questions

**RQ1** is supported descriptively for the tested cells. Measured CPU actuation was ordered across low, medium, and high profiles under both workloads, with accepted-run coefficients of variation between 0.704% and 5.384%.

**RQ2** is answered negatively within scope. The 15 valid fault runs produced no frozen-SLO manifestation and no eligible positive lead-time event. This is an observed bounded outcome, not proof of no effect.

**RQ3** is supported at the tracked-evidence layer. Registry rows, reports, configurations, and deterministic checks preserve the 21-valid and 14-invalid separation. The stronger receipt layer remains incomplete because zero of 21 expected receipt and SHA-manifest pairs are available for independent replay.

## 5 Discussion

### 5.1 Actuation is a prerequisite and not the outcome

The results demonstrate why an injector exit code cannot define a service incident. CPU actuation was measurable, ordered, and accepted under explicit coverage and magnitude gates. The prospectively frozen user-facing outcome still did not occur. Labeling all injected windows as positive would therefore replace the intended outcome construct with an intervention marker.

This separation also sharpens fault-injection evaluation. Precision can refer to where and when a mechanism injects a fault [1-3], but a research claim about user-visible degradation additionally requires an outcome contract. The two properties should be reported separately.

### 5.2 The negative observation is informative but not powered evidence of absence

The 0/15 result constrains what can be claimed from this dataset. It shows that these accepted treatments, on this host and under these profiles, did not create the frozen SLO event. It does not show statistical equivalence, rule out smaller effects, or establish that CPU faults never cause degradation. Cell sizes of two or three make inferential null-effect language especially inappropriate.

The result remains useful because it prevents invalid downstream work. No event-level rule, logistic model, boosted tree, language model, or graph model can be evaluated for positive-incident warning coverage from this evidence. Future confirmatory work remains governed by a prospective target of 60 independent positive incidents and 60 independent normal controls. Multiple windows from one incident cannot substitute for independent runs.

### 5.3 Fail-closed denominators reduce selective reporting

Preserving 14 invalid attempts exposes operational failure modes and makes the denominator auditable. Invalid attempts can guide engineering improvements, but they cannot estimate treatment effects, manifestation rates, or robustness. This distinction prevents a common ambiguity in complex systems experiments: whether a missing outcome represents a valid negative treatment or a workflow that never produced an eligible observation.

### 5.4 Layered reproducibility is more precise than a binary label

The tracked evidence and derived outputs can be checked deterministically. That is a meaningful reproducibility layer. It does not reconstruct absent final receipts or prove exact replay of the original runtime archive. Reporting both facts is more useful than labeling the artifact simply reproducible or irreproducible. The missing 0/21 receipt layer is a material limitation and remains visible in the manuscript, metadata, and verifier.

### 5.5 Implications for experimental design

The case supports five practical recommendations. First, preregister treatment, physical-effect, and service-outcome contracts separately. Second, require an independent physical-effect gate before counting a fault treatment. Third, freeze denominator and invalidation rules before outcomes are interpreted. Fourth, stop model evaluation when positive event semantics are absent instead of relabeling injection windows. Fifth, report reproducibility by evidence layer and name unavailable layers explicitly.

## 6 Threats to Validity

### 6.1 Construct validity

CPU actuation and service degradation are different constructs. The frozen SLO reduces post-hoc flexibility but may not capture every user-relevant degradation. Conversely, an injection label is not a valid proxy for an SLO event. The selected p95 and error conditions define the studied outcome and should not be interpreted as a complete definition of service health.

### 6.2 Internal validity

The same-host design reduces some environmental variation but exposes results to host scheduling and shared-resource interference. Fail-closed gates reduce outcome-dependent inclusion, yet residual variation cannot be separated from treatment effects with the present small descriptive cells. The design contains no randomized treatment ordering claim or causal estimator.

### 6.3 Conclusion validity

The analysis reports observed means, sample standard deviations, coefficients of variation, ranges, and a manifestation count. These statistics describe accepted runs; they do not establish confidence intervals, equivalence, statistical significance, or population-level absence of effect. The 0/15 outcome must remain bounded to the tested conditions.

### 6.4 External validity

Evidence comes from one host, one local deployment, one target service, two workload levels, and three CPU profiles. No production, cross-host, cross-service, or cross-fault generalization is supported. The incomplete network-delay workflow is not evidence for or against network-delay feasibility and is not pooled with the CPU study.

### 6.5 Reproducibility validity

Tracked evidence and derived outputs are deterministically checkable, but receipt-level replay is unavailable at 0/21. A passing verifier establishes consistency with tracked sources. It cannot reconstruct missing artifacts or prove exact reconstruction of the original environment.

## 7 Ethics and Responsible Operation

The study uses a synthetic benchmark application and controlled local fault injection. It contains no human-subject data or personal user telemetry. The academic artifact does not authorize deployment changes, autonomous agent actions, or new fault execution. Invalid runs and negative outcomes are retained to reduce selective reporting. Scientific judgments, validity labels, and authority boundaries remain human-controlled and tied to canonical records.

## 8 Conclusion

In this bounded microservice case study, versioned CPU-stress profiles produced ordered physical actuation but no frozen-SLO manifestation across 15 valid fault runs. The result demonstrates why treatment request, measured physical effect, service manifestation, validity accounting, and artifact replay must be evaluated separately. The evidence supports a tracked-layer negative observation and a methodological account of experimental governance. It does not support a predictive-model, causal-effect, statistical-equivalence, or external-validity claim.

The immediate academic value is therefore a defensible boundary: the experiment can explain what was successfully actuated, why no positive incident was eligible, how invalid attempts were excluded without disappearing, and which future claims remain blocked. Future work requires prospectively governed positive incidents, normal controls, frozen feature windows, and paired model-versus-rule evaluation before early-warning performance can be reported.

## Data and Artifact Availability

The repository artifact contains versioned configurations, canonical governance records, tracked run reports, derived tables, manuscript sources, and deterministic verification scripts. The derived analysis is pinned to a recorded Git revision. Receipt-level replay remains unavailable at 0/21 expected pairs. The current package is an academic-review artifact, not a public release, DOI deposit, or externally submitted package.

## References

1. Chandra, R., Lefever, R. M., Cukier, M., and Sanders, W. H. 2004. A global-state-triggered fault injector for distributed system evaluation. IEEE Transactions on Parallel and Distributed Systems 15, 7, 593-605. https://doi.org/10.1109/TPDS.2004.14
2. Wu, H., Pan, J., and Huang, P. 2024. Efficient Exposure of Partial Failure Bugs in Distributed Systems with Inferred Abstract States. In 21st USENIX Symposium on Networked Systems Design and Implementation, 1267-1283.
3. Zhang, H. et al. 2024. MicroFI: Non-Intrusive and Prioritized Request-Level Fault Injection for Microservice Applications. IEEE Transactions on Dependable and Secure Computing 21, 5, 4921-4938. https://doi.org/10.1109/TDSC.2024.3363902
4. Al-Said Ahmad, A., Al-Qora'n, L. F., and Zayed, A. 2024. Exploring the impact of chaos engineering with various user loads on cloud native applications: an exploratory empirical study. Computing 106, 2389-2425. https://doi.org/10.1007/s00607-024-01292-z
5. Zheng, L., Chen, Z., He, J., and Chen, H. 2024. MULAN: Multi-modal Causal Structure Learning and Root Cause Analysis for Microservice Systems. In Proceedings of the ACM Web Conference 2024. https://doi.org/10.1145/3589334.3645442
6. Zhang, W., Yang, Z., Peng, F., Zhang, L., Chen, Y., and Chen, R. 2026. GALR: Graph-Based Root Cause Localization and LLM-Assisted Recovery for Microservice Systems. Electronics 15, 1, 243. https://doi.org/10.3390/electronics15010243
7. Zhang, L. et al. 2025. A Survey of AIOps in the Era of Large Language Models. ACM Computing Surveys 58, 2, 44:1-44:35. https://doi.org/10.1145/3746635
8. Cornacchia, A. et al. 2025. Between Promise and Pain: The Reality of Automating Failure Analysis in Microservices with LLMs. In Proceedings of the 16th ACM SIGOPS Asia-Pacific Workshop on Systems. https://doi.org/10.1145/3725783.3764388
9. Yu, M. et al. 2026. From Distributed Tracing to Proactive SLO Management: A Mini-Review of Trace-Driven Performance Prediction for Cloud-Native Microservices. Frontiers in Computer Science 8, 1783945. https://doi.org/10.3389/fcomp.2026.1783945
