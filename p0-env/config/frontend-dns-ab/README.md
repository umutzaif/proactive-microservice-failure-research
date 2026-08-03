# Frontend DNS A/B tooling

Purpose: test whether the v0.10.6 frontend's per-request GCP metadata DNS
autodetection contributes to local `/` latency. This directory does not change
the normal deployment by itself.

Inputs:

- upstream frontend source at `p0-env/source/microservices-demo/src/frontend`;
- `frontend-env-platform.patch`;
- pinned Go builder digest and the upstream distroless runtime;
- explicit `ENV_PLATFORM=local` during the A/B execution.

Outputs:

- local image `makale/frontend:v0.10.6-env-platform-v1`;
- tooling-only A/B JSON under `P1-FRONTEND-DNS-AB-001`.

Dependencies: Docker Desktop, Minikube, Kubernetes and the pinned Online
Boutique v0.10.6 loadgenerator image.

Risks and common mistakes:

- a new pod has cold/lazy gRPC connection effects;
- DNS negative caching creates sequence carry-over;
- setting `ENV_PLATFORM=local` without patching does not skip the upstream
  unconditional lookup;
- a completed script is not automatically a causal result or scientific run.

Independent verification:

1. run `git apply --check --unidiff-zero` against the upstream frontend source;
2. inspect the built image ID;
3. require A controls to agree before interpreting B;
4. verify upstream image, environment, replicas and temporary-pod cleanup;
5. compare pre/post host event counters.

The current attempts are inconclusive and the patch is not accepted into the
scientific deployment. The user is not expected to modify these files unless a
new randomized/concurrent A/B design is explicitly approved.
