# ArgoCD Source Hydrator (`rendered` branch)

The Source Hydrator renders manifests from a *dry* source (this repo, `main`) and commits the
result to a *hydrated* branch, `rendered`. ArgoCD then syncs from `rendered`, so every change
shows up as a reviewable manifest diff in git, and what is applied no longer depends on the
repo-server's Helm/Kustomize at sync time.

## What is enabled
- `commitServer.enabled: true` and `configs.params.hydrator.enabled: true` in
  `argocd/apps/argocd/values.yaml` (ArgoCD v3.6.x, chart 10.17).
- No Application uses it yet. Enabling it changes nothing until one sets `spec.sourceHydrator`.

## Write access for `rendered`
The commit-server pushes to `rendered`, so ArgoCD needs a `repository-write` credential for
`https://github.com/marthydavid/homelab`. It is built by the ExternalSecret
`argocd/apps/global-apps/external-secrets-config/argocd-repo-write.yaml` from Vault `secret/argocd`
(keys `githubAppID`, `githubAppInstallationID`, `githubAppPrivateKey`; `url` and `type` are fixed in
the template). The GitHub App needs `contents: write` on the repo. Do not edit `rendered` by hand.

## Constraint: single source only
`sourceHydrator` replaces `source`. It does **not** support `sources:`. Today most apps here are
multi-source Helm (upstream chart plus `$values/...` from this repo): 35 of the 51
ApplicationSets. Those cannot be switched directly. The 16 single-source ones (plain manifests
and kustomize overlays) can.

Options for the multi-source Helm apps, in order of preference:
1. Wrap the chart in a kustomize dir with `helmCharts:` + `valuesFile` next to it (needs
   `kustomize.buildOptions: --enable-helm` in `argocd-cm`).
2. Wrap it in a local Helm chart that depends on the upstream chart (values go under the
   dependency name; Renovate understands `Chart.yaml` dependencies).

## Verified: wrapping a Helm app with kustomize
Checked on `global-apps/reloader` (chart 2.2.20, `global-values.yaml`): `kubectl kustomize --enable-helm`
on this layout renders the same 6 objects, with identical content, as `helm template -f global-values.yaml`.
```
argocd/apps/global-apps/reloader/overlays/<cluster>/
  kustomization.yaml   # helmCharts: name, repo, version, releaseName, namespace, includeCRDs, valuesFile
  values.yaml          # global values (+ cluster values merged, or use additionalValuesFiles)
```
Caveats:
- `valuesFile` must live inside the kustomization directory (default load restrictions), so shared
  `global-values.yaml` has to be copied or symlinked into each overlay, or listed per overlay.
- `includeCRDs: true` matches ArgoCD's default of installing chart CRDs.
- Needs `kustomize.buildOptions: --enable-helm` in `argocd-cm` (set in `argocd/apps/argocd/values.yaml`).
- The chart version moves from the ApplicationSet into `kustomization.yaml`; Renovate's kustomize
  manager reads `helmCharts`, but check it after the first conversion.

## Shape of a hydrated Application
```yaml
spec:
  sourceHydrator:
    drySource:
      repoURL: https://github.com/marthydavid/homelab
      targetRevision: main
      path: argocd/apps/global-apps/dashboards
    syncSource:
      targetBranch: rendered
      path: rendered/{{ .name }}/global-apps/dashboards   # one dir per app and cluster
    # hydrateTo: rendered-next    # optional staging branch for review before promotion
```
Use a distinct `syncSource.path` per Application, otherwise they overwrite each other.
`rendered` is an orphan branch that holds only generated manifests.

## Converting an app: needs a second commit
An app that is switched to `sourceHydrator` can come up `Hydrated` with sync status `Unknown` and no
manifest on `rendered` (`rendered/...: app path does not exist`). Hydration is batched per commit on
`main`: an app that joins after the batch for that commit was handled gets marked done without being
pushed (seen with the 11-app bulk change and with reloader). A hard hydrate annotation does not fix it.
A **new commit on `main`** re-hydrates every hydrated app in one batch and fills the gap, but only if
the converted apps already exist on the cluster with `sourceHydrator` when that commit lands (the root
app has to have applied the ApplicationSet change first; a follow-up merged straight after the
conversion is too early). So: merge the conversion, wait until `kubectl -n argocd get app <app> -o
jsonpath='{.spec.sourceHydrator}'` is set, **then** merge any further commit to `main` (a docs fix is
enough), and check that `rendered/<cluster>/<group>/<app>/manifest.yaml` exists and the app is Synced.

## Current state (nas)
Hydrated to `rendered`: all plain-manifest/kustomize apps, and the Helm apps wrapped with kustomize
`helmCharts` (`argocd/apps/<group>/<app>/overlays/nas/kustomization.yaml`; the chart version lives there and
Renovate bumps it).

Still on multi-source Helm (not hydrated):
- `storage/openebs`: kustomize rejects the chart's duplicate CRDs (issue #1922).
- `monitoring/kube-prometheus-stack`: very large CRDs, a single `manifest.yaml` may hit size limits.
- `argocd`: manages the hydrator itself, left as is.
- `prometheus-operator-crds`, `database/barman-cloud-plugin`: chart straight from a Helm repo, no values from
  this repo (the hydrator needs a git dry source).

Gotcha when wrapping a chart: kustomize does not tell the chart which API versions the cluster has, so charts that
gate objects on `.Capabilities.APIVersions` (ServiceMonitors, ...) render less than ArgoCD's own Helm. Declare them
in `helmCharts.apiVersions` (`monitoring.coreos.com/v1` and its `ServiceMonitor`/`PodMonitor`/`PrometheusRule`
kinds are set everywhere). An app that shows OutOfSync right after conversion is the signal; do not sync it before
the output matches live.

## Rollout plan
1. Merge the enablement PR, sync the `argocd` app by hand, check `argocd-commit-server` is Running.
2. Add write credentials (see above).
3. Pilot one single-source app, e.g. `global-apps/dashboards`, on `nas`.
4. Convert the kustomize-based apps, then wrap and convert the Helm apps one group at a time.
5. `homelab/auto-sync: "true"` is on for `nas`: reviewing the `rendered` diff replaces reviewing each
   app's diff in the UI.
