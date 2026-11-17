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
[`vcluster/values.yaml`](vcluster/values.yaml). No SCC is relaxed: all 17 pods on the host run under
`restricted-v2`. By default the vcluster chart also creates a cluster-scoped ClusterRole/ClusterRoleBinding
on the host (read PersistentVolumes, write VolumeSnapshotContents); the values switch that off
(`rbac.clusterRole.enabled: false`), so the host footprint is the `vcluster-argocd-27917` namespace
(one namespaced Role, one 5Gi PVC on `lvms-vg1`) and nothing cluster-scoped.

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

Each scenario is a parent Application (`root-<instance>-<scenario>`) that renders its children through a
Helm chart ([`gitops/app-of-apps`](gitops/app-of-apps)), the pattern from the issue. The children carry
`argocd.argoproj.io/sync-wave` annotations, `selfHeal: true` and `retry.limit: 100`.

* **`slow-workload`** (the issue body): wave 100 `a-database` is a ConfigMap (wave 0) plus a
  Deployment/Service (wave 1) that needs 45s to become Ready. Wave 300 `b-seed-job` is a Job that
  fails if the database is not serving yet, so an opened gate shows up as a failed Job.
* **`mixed-live`** (the root-cause analysis in the issue comments): wave 1 `b-operator` has a Job that
  applies cleanly plus an OLM `Subscription` whose CRD does not exist in the vcluster (apply fails, the
  resource stays `Live == nil`), with a Lua health override for `operators.coreos.com_Subscription`
  in `argocd-cm`. Wave 2 `c-consumer` is a Job that must not start before the operator is installed.

The check in [`scripts/observe.py`](scripts/observe.py): at the moment a wave N+1 child Application first
appears, were all lower-wave children `Synced` **and** `Healthy`? If not, the gate released early. A
higher-wave child that is never created while a lower-wave one is unsettled means the gate held. The
expected children come from the chart, and the run is aborted as inconclusive if an instance lists
resources outside its own destination namespace.

Why `Synced` and `Healthy` and not just `Healthy`: the issue states the expectation as "must not start
until the lower-wave child is `Synced`", and in `mixed-live` the bug is a child that reports `Healthy`
while a resource failed to apply (it stays `OutOfSync`), so a health-only check cannot see it.

## Results (2026-11-17, metal1 OKD 4.22, vcluster v0.37.7)

Valid runs only, i.e. after pitfalls 1 and 2 below were fixed. Same values, same manifests, same git
revision for both instances; the Argo CD version (via its chart) is the variable.

| scenario | v3.3.9 (chart 9.5.11) | v3.6.1 (chart 10.18.0) |
|---|---|---|
| `slow-workload` | gate **held**: wave 300 created at t+49..51s, when `a-database` turned Synced+Healthy; `seed-db` succeeded (3 runs) | gate **released early**: wave 300 created at t+3..4s while `a-database` was Progressing (its Deployment needs 45s); `seed-db` **failed** (3 runs) |
| `mixed-live` | gate **held**: `c-consumer` never created in the 200s window, `b-operator` stayed `OutOfSync`/`Missing` (2 runs) | gate **released early**: `c-consumer` created at t+7s and completed while `b-operator` was `OutOfSync`/`Healthy` with `resource mapping not found for name: "fake-operator"` (2 runs) |

What this shows: with Argo CD's default behaviour otherwise equal, v3.6.1 reports a child Application
`Healthy` while parts of it are not applied or not ready, and the parent's sync-wave gate opens on that.
That is the symptom of #27917, reproduced on the latest chart.

What it does not show:

* The cause. The timelines are consistent with the analysis in the issue (the child is `Healthy` from
  t+1s on v3.6.1 while it is still `OutOfSync` with its sync `Running` and its Deployment only due in a
  later wave, which is what skipping `Live == nil` resources in `setApplicationHealth` would produce), but
  nothing here instruments the controller. Reading `controller/health.go` at v3.6.1 shows the unconditional skip.
* That `mixed-live` also holds on a stock v3.3.9. Reading `controller/health.go` at v3.3.9, a `Missing`
  resource is only aggregated when the kind has an `argocd-cm` health override or a Go-coded check
  (`GetHealthCheckFunc`: Deployment, StatefulSet, Job, Service, ... , no CRs). Upstream ships a built-in Lua
  check for `operators.coreos.com/Subscription`, but that counts as neither. So the control holds in
  `mixed-live` because of the custom `Subscription` override in `argocd/values.yaml` (the third ingredient
  in the issue comment); without it v3.3.9 would skip the missing Subscription too. `slow-workload` does not
  depend on this, its Deployment has a Go-coded check. Read from source, not tested.
* Anything about v3.4.2 (the reported version), the versions in between, or the fix in #28066. An image
  built from that PR can be dropped into a third instance to test it.
* That the chart is the culprit: the two charts differ in more than the image tag. The values are shared, the
  rendered workloads are the same set, but chart defaults can differ.

## Pitfalls found while building this (each one silently invalidated a run)

1. **Child Application health is opt-in.** Argo CD does not assess `argoproj.io/Application` health since
   1.8, so by default no version waits for a child and sync waves between child Applications do nothing.
   [`argocd/values.yaml`](argocd/values.yaml) adds the documented
   `resource.customizations.health.argoproj.io_Application` Lua (docs/operator-manual/health.md). Without it
   both v3.3.9 and v3.6.1 release the gate within seconds and the control group is useless.
2. **Application names must be unique per Argo CD instance.** Resource tracking is by app name, two
   instances in one cluster with equally named Applications claim and prune each other's resources.
   Names are `<instance>-<scenario>-<child>` and `root-<instance>-<scenario>` for that reason.
3. **OpenShift UIDs.** The chart pins `runAsUser: 999` on redis, `restricted-v2` rejects it on the host, so
   the values null it. The vcluster default `runAsUser: 0` is nulled the same way.
4. Do not `export KUBECONFIG=<vcluster kubeconfig>` before running the scripts, the host calls use
   `--context metal1` and would no longer find it. Pass `--kubeconfig` per command instead.

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
VC=~/.cache/argocd-27917/kubeconfig
kubectl --kubeconfig $VC -n argocd-latest get applications
kubectl --kubeconfig $VC -n argocd-latest port-forward svc/argocd-latest-server 8080:80   # UI, admin password in argocd-initial-admin-secret
```
