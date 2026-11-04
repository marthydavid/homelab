# Fleet → ArgoCD migration

## Target
The lab shrinks to two clusters:

| Cluster | kube context | What it is | Managed by ArgoCD |
|---|---|---|---|
| `nas` | `sm4` | k3s on SM4 (Pécs) and the ArgoCD hub | Everything that Fleet used to deploy there |
| `metal1` | `metal1` | OKD 4.22, three nodes (sm1–sm3) | Only apps OKD does not already provide; today just reloader |

metal1 gets cert-manager, external-secrets, external-dns, MetalLB, NFD and storage (LVMS) from
OLM operators. Do **not** target it with the Helm charts for those. Use their CRs/config instead.

The rpi `k3s`, `nuc`, `rke2-1`, `rke2-2`, `sm5` and `oci` clusters, Rancher and Fleet are gone.
On nas the Fleet agent no longer runs, so the releases there are frozen at their last
Fleet-deployed versions.

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
| `dependsOn` | Chains inside one app use sync-waves (external-secrets -> store/secrets, cnpg operator -> database secrets -> cluster). Dependencies between separate apps are not ordered: `SkipDryRunOnMissingResource` + sync retry with backoff until CRDs/secrets exist (see #1925) |
| `diff.comparePatches` | `ignoreDifferences` |
| `defaultNamespace` | `destination.namespace` + `CreateNamespace=true` |

### Sync policy
Applications sync automatically only on clusters whose Secret has `homelab/auto-sync: "true"`
(set with `templatePatch`). `nas` is `"false"`: the repo is ahead of what is deployed there, so
syncing an app also upgrades it. Review each diff and sync by hand, then flip the label once
everything is in sync.

## Bootstrap
```bash
helm --kube-context sm4 upgrade --install argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm --version 10.11.6 \
  -n argocd --create-namespace -f argocd/apps/argocd/values.yaml
kubectl --context sm4 apply -k argocd/bootstrap
# metal1: run with the current kube context set to sm4 (argocd --core talks to the hub's API)
argocd cluster add metal1 --core --name metal1 --yes \
  --label homelab/cluster=metal1 --label homelab/auto-sync=true
```
After that, ArgoCD manages itself (`argocd/applicationsets/argocd/argocd.yaml`).

## Known gaps
- **Secrets backend is down.** `vault-backend` points at `vault.oci.marthy.xyz`, which went away
  with the OCI cluster. Existing Secrets on nas still work, but no ExternalSecret can refresh,
  and metal1 has no SecretStore.
- **Monitoring:** there is no Prometheus on nas. `prometheus-operator-crds` is installed so
  ServiceMonitors apply, but nothing scrapes them yet.
- **immich:** chart 0.12 removed the bundled postgres subchart, but `values-nas.yaml` still
  configures `postgresql:`, so it does not render.
- **kube-vip:** this is a control-plane VIP, so it belongs to cluster bootstrap, not ArgoCD.
