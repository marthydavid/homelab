# argo-cd#27917: app-of-apps sync-wave no longer waits for lower-wave children

Reproduction environment for [argoproj/argo-cd#27917](https://github.com/argoproj/argo-cd/issues/27917)
("App-of-Apps sync-wave no longer waits for lower-wave child Applications to finish syncing,
regression v3.3.9 → v3.4.2"). Fix proposal: [argoproj/argo-cd#28066](https://github.com/argoproj/argo-cd/pull/28066).

It runs on **metal1** inside a **vcluster**, from this branch, and is *not* part of the GitOps
hub: everything lives under `repro/`, outside `argocd/applicationsets`, so the `root` app-of-apps on
`nas` never picks it up.

## Why a vcluster

A vcluster has its own API server, etcd, CRDs and RBAC. The Argo CD CRDs, the Applications and the
fake operator CRs exist only inside it, so an OpenShift GitOps / Argo CD operator on metal1 can
neither see nor reconcile them (only pods, services, configmaps and secrets are synced down into the
host namespace `vcluster-argocd-27917`). Today metal1 has no `argoproj.io` CRDs and no GitOps
operator, the isolation matters as soon as someone installs one.

OpenShift specifics: the vcluster default `runAsUser: 0` is rejected by the `restricted-v2` SCC, see
[`vcluster/values.yaml`](vcluster/values.yaml). No SCC is relaxed, no cluster-scoped host resource is created.

## What runs inside

| instance | helm chart (`argo/argo-cd`) | Argo CD | role |
|---|---|---|---|
| `latest` | 10.18.0 | v3.6.1 | the chart the repro is about, owns the CRDs |
| `v339` | 9.5.11 | v3.3.9 | last known-good version from the issue, control group |

Chart versions are in [`scripts/lib.sh`](scripts/lib.sh) (`ARGOCD_CHART`); add an instance there to
compare another version (chart 9.5.14 is the reported v3.4.2). Each instance is namespaced
(`argocd-<instance>`) and only reconciles its own Applications.

Both are plain chart installs with [`argocd/values.yaml`](argocd/values.yaml): one controller replica,
no sharding, no HA (dex, notifications and the ApplicationSet controller are switched off to save memory).

## Scenarios

Each scenario is a parent Application (`root-<scenario>`) that renders its children through a Helm
chart ([`gitops/app-of-apps`](gitops/app-of-apps)), the pattern from the issue. The children carry
`argocd.argoproj.io/sync-wave` annotations, `selfHeal: true` and `retry.limit: 100`.

* **`slow-workload`** (the issue body): wave 100 `a-database` is a ConfigMap (wave 0) plus a
  Deployment/Service (wave 1) that needs 45s to become Ready. Wave 300 `b-seed-job` is a Job that
  fails if the database is not serving yet, so an opened gate shows up as a failed Job.
* **`mixed-live`** (the root-cause analysis in the issue comments): wave 1 `b-operator` has a Job that
  applies cleanly plus an OLM `Subscription` whose CRD does not exist in the vcluster (apply fails, the
  resource stays `Live == nil`), with a Lua health override for `operators.coreos.com_Subscription`
  in `argocd-cm`. Wave 2 `c-consumer` is a Job that must not start before the operator is installed.

The check in [`scripts/observe.py`](scripts/observe.py): at the moment a wave N+1 child Application first
appears, were all lower-wave children `Healthy`? If not, the gate released early.

## Run it

Needs `kubectl` (context `metal1`), `helm`, `python3`. Nothing here changes your kubeconfig, the
virtual cluster kubeconfig is written to `~/.cache/argocd-27917/kubeconfig`.

```bash
repro/argocd-27917/scripts/up.sh                       # vcluster + both Argo CDs (idempotent)
repro/argocd-27917/scripts/run-all.sh                  # every scenario on every instance, prints a matrix
repro/argocd-27917/scripts/run-scenario.sh latest mixed-live   # one run, live timeline
repro/argocd-27917/scripts/down.sh                     # remove everything from metal1
```

The Applications pull from `GIT_REVISION` (default: this branch) of this repository, so the branch has
to stay on GitHub while you run it. Look around with:

```bash
export KUBECONFIG=~/.cache/argocd-27917/kubeconfig
kubectl -n argocd-latest get applications
kubectl -n argocd-latest port-forward svc/argocd-latest-server 8080:80   # UI, admin password in argocd-initial-admin-secret
```
