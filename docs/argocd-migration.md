# Fleet → ArgoCD migration

## Target
The lab shrinks from ~7 Fleet-managed clusters to two:

| Cluster | Role | Notes |
|---|---|---|
| `nas` (Pécs, k3s) | Main cluster and ArgoCD hub | Runs everything it ran under Fleet, plus baby buddy |
| `metal1` | Second cluster | global-apps, metallb, ingress-nginx, openebs, intel GPU stack |

The rpi `k3s`, `nuc`, `rke2-1`, `rke2-2`, `sm5` and `oci` clusters are dropped, along with their
values and overlays.

## Layout
```
argocd/
  bootstrap/              # applied once by hand: root app + nas cluster Secret
  applicationsets/<group>/<app>.yaml
  apps/<group>/<app>/
    values.yaml | *-values.yaml   # Helm apps: the old Fleet valuesFiles
    values-<cluster>.yaml          # optional per-cluster values (ignoreMissingValueFiles)
    *.yaml                         # plain-manifest apps without per-cluster changes
    base/ + overlays/<cluster>/    # plain-manifest apps with per-cluster patches (kustomize)
```

Each ApplicationSet uses the cluster generator and selects clusters by the `homelab/cluster` label
on the ArgoCD cluster Secret. Helm apps use two sources: the upstream chart and this repo as `$values`.

### Mapping from Fleet
| Fleet | ArgoCD |
|---|---|
| `GitRepo.targets` / `clusterSelector` | `homelab/cluster In [...]` on the ApplicationSet |
| `targetCustomizations[].helm.valuesFiles` | `values-<cluster>.yaml` |
| `targetCustomizations[].yaml.overlays` | `overlays/<cluster>/` kustomization (patches target the base object, `allowNameChange` keeps Fleet renames) |
| `dependsOn` | No hard ordering: `SkipDryRunOnMissingResource` + sync retry with backoff until CRDs/secrets exist |
| `diff.comparePatches` | `ignoreDifferences` |
| `defaultNamespace` | `destination.namespace` + `CreateNamespace=true` |

### Sync policy
Applications sync automatically only on clusters whose Secret has `homelab/auto-sync: "true"`
(set with `templatePatch`). `metal1` is new and empty, so it gets auto-sync from day one. `nas` starts
with `"false"`, so ArgoCD only shows diffs against what Fleet deployed there.

## Bootstrap
1. Apply `fleet-gitrepos/argo.yaml`. ArgoCD then moves from the rpi cluster to `nas`, reusing the
   existing `argocd.marthy.xyz` ingress, which already points at `pecs.marthy.xyz`.
2. `kubectl --context nas apply -k argocd/bootstrap`
3. Register metal1:
   ```bash
   argocd cluster add <metal1-context> --name metal1 \
     --label homelab/cluster=metal1 --label homelab/auto-sync=true
   ```

## Cutover on nas
For each group:
1. In the ArgoCD UI, check that `<app>-nas` has no unexpected diffs against the Fleet-deployed resources.
2. Remove the bundle from Fleet without deleting its resources: set `keepResources: true` on the
   GitRepo, then delete the bundle dir or the GitRepo.
3. Sync the app in ArgoCD.
Once every group is done, set `homelab/auto-sync: "true"` in `argocd/bootstrap/cluster-nas.yaml`.

## Known gaps
- **Monitoring:** `rancher-monitoring` (and its CRDs) is still Fleet/Rancher-only, and many apps
  ship ServiceMonitors into `cattle-monitoring-system`. See the monitoring decision issue.
- **metal1 networking:** metallb-config has no pool or peer for metal1 yet, and ingress-nginx uses
  global values only.
- **kube-vip:** this is a control-plane VIP, so it belongs to cluster bootstrap (k3s/rke2 static
  manifest), not ArgoCD.
- **immich:** chart 0.12 removed the bundled postgres subchart, but `values-nas.yaml` still
  configures `postgresql:`. It fails to render under Fleet today too.
