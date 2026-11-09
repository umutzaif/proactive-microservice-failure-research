# Candidate Related Work

> **Status.** This is a bounded candidate section, not a systematic review. It
> positions the D-148 repository evidence without claiming a trained model,
> validated early warning, causal treatment effect, external generalization, or
> complete receipt-level replay.

## 2. Related Work

### 2.1 Multimodal microservice root-cause analysis

MULAN combines metric and log representations, learns modality-specific and
modality-invariant structure, fuses causal graphs with KPI-aware attention, and
ranks candidate root causes using random walk with restart [1]. Its reported
task is root-cause localization rather than prospective SLO warning. The three
evaluation datasets contain only 4, 5, and 5 recorded system faults,
respectively, which makes its strong ranking scores important but statistically
fragile. D-148 is not a competing RCA model: it neither learns a causal graph
nor produces root-cause rankings. The relevant contrast is methodological.
MULAN shows that multimodal causal-graph RCA already exists, so this project
cannot claim novelty merely from combining metrics, logs, or graph structure.

GALR further combines window-aligned metrics, structured logs, trace-derived
topology, a graph-attention localization model, LLM-derived node priors, and
retrieval-augmented recovery planning [2]. It therefore directly rules out an
originality claim based only on “LLM plus GAT” or LLM-assisted remediation.
GALR evaluates post-event localization and offline recovery plans; its authors
also report injection-time-anchored window labels, results averaged over two
runs, no statistical-significance test, and no live execution of generated
recovery commands. D-148 does not outperform or reproduce GALR. Instead, its
bounded contribution is to make a different prerequisite visible: before a
prospective model can be evaluated, fault actuation, SLO manifestation,
incident independence, and evidence eligibility must be separated.

### 2.2 LLM agents and operational safety

Tool-augmented LLM agents can help with microservice diagnosis, but their
autonomy introduces failure modes that are not captured by answer accuracy
alone. Cornacchia et al. observed shallow fixes, malformed or hallucinated tool
calls, stale-log misinterpretation, unnecessary actions, and potentially
harmful troubleshooting behavior [3]. Domain-specific telemetry tools often
improved accuracy and efficiency, but not uniformly. These observations support
a gated, evidence-linked role for an LLM rather than unsupervised authority to
change a running system.

D-148 contains no LLM evaluation and therefore cannot claim that such a gate
reduces false positives. Its present relevance is governance: the repository
keeps runtime authorization separate from analysis, preserves invalid attempts,
and requires claim-specific evidence and falsification conditions. Testing an
LLM verifier remains future work governed by D-064 and requires independent
positive incidents, normal controls, frozen evidence windows, and a paired
baseline comparison.

### 2.3 Proactive SLO prediction and early-warning evaluation

Proactive SLO management is distinct from post-event RCA. Yu et al. distinguish
SLO-violation prediction, tail-latency prediction, prefix early warning, and
actionable outputs such as bottleneck ranking [4]. For early warning, they
recommend selecting a threshold under a precision constraint and evaluating
earliness together with coverage and false-alarm rate. They also emphasize the
gap between proxy latency labels and operational SLO semantics, along with
sampling-induced missing spans and topology drift.

These requirements explain why D-148 does not report an early-warning score.
The 15 valid CPU-fault runs produced zero frozen-SLO manifestations, hence zero
eligible positive lead-time examples. Without positive events, neither
earliness/coverage nor a paired proposed-model-versus-rule comparison is
scientifically defined. Windows within the same run cannot be counted as
independent incidents. The future D-064 target remains 60 independent positive
incidents plus 60 independent normal controls.

### 2.4 LLM4AIOps context

The broader LLM4AIOps literature spans failure data processing, detection,
diagnosis, RCA, and remediation. Zhang et al. classify this landscape using 183
articles published from 2020 through 2024 [5]. That survey motivates careful
task and evaluation definitions, but it is not a direct experimental baseline
for D-148. Accordingly, this section uses it for taxonomy only; the closest
method comparisons remain MULAN, GALR, the LLM-agent failure-mode study, and
the proactive-SLO evaluation review.

### 2.5 Position of the present study

The present study is best described as a bounded negative-result and evidence-
governance case study for CPU-fault experimentation in one local Online Boutique
deployment. It contributes three defensible observations: physical CPU
actuation was descriptively ordered across the tested profiles and workloads;
none of 15 valid fault runs manifested the frozen SLO; and preserving all 35
attempts exposed the difference between operational attempts, registry-valid
evidence, and receipt-level replay readiness. The receipt layer remains
incomplete at zero of 21 expected pairs.

This position is narrower than multimodal RCA, graph localization, LLM-agent
diagnosis, or proactive prediction. It does not compete on model accuracy.
Instead, it documents why those evaluations require valid manifested incidents,
independent sampling, fixed outcome semantics, and auditable inclusion before
model comparisons can be meaningful.

## References

[1] L. Zheng, Z. Chen, J. He, and H. Chen, “MULAN: Multi-modal
Causal Structure Learning and Root Cause Analysis for Microservice Systems,”
*Proceedings of the ACM Web Conference 2024*, 2024.
https://doi.org/10.1145/3589334.3645442

[2] W. Zhang, Z. Yang, F. Peng, L. Zhang, Y. Chen, and R. Chen,
“GALR: Graph-Based Root Cause Localization and LLM-Assisted Recovery for
Microservice Systems,” *Electronics*, vol. 15, no. 1, art. 243, 2026.
https://doi.org/10.3390/electronics15010243

[3] A. Cornacchia, I. Alabdulaal, I. Saghier, A. Mirdad, O. Fayoumi,
and M. Canini, “Between Promise and Pain: The Reality of Automating Failure
Analysis in Microservices with LLMs,” *APSys 2025*, 2025.
https://doi.org/10.1145/3725783.3764388

[4] M. Yu, H. Liu, J. Du, K. Lin, T. Dai, Y. Fu, and C. Yang,
“From Distributed Tracing to Proactive SLO Management: A Mini-Review of
Trace-Driven Performance Prediction for Cloud-Native Microservices,”
*Frontiers in Computer Science*, vol. 8, art. 1783945, 2026.
https://doi.org/10.3389/fcomp.2026.1783945

[5] L. Zhang et al., “A Survey of AIOps in the Era of Large Language
Models,” *ACM Computing Surveys*, vol. 58, no. 2, art. 44, 2025.
https://doi.org/10.1145/3746635
