# ArgoCD (replaced Rancher Fleet)

ArgoCD is the only GitOps path in this repo. Fleet and Rancher were removed after the migration;
the old `fleet/` and `fleet-gitrepos/` trees live only in git history.

## Target
The lab shrinks to two clusters:

| Cluster | kube context | What it is | Managed by ArgoCD |
|---|---|---|---|
| `nas` | `sm4` | k3s on SM4 (Pécs) and the ArgoCD hub | Everything (formerly deployed by Fleet) |
| `metal1` | `metal1` | OKD 4.22, three nodes (sm1–sm3) | Only apps OKD does not already provide; today just reloader |

metal1 gets cert-manager, external-secrets, external-dns, MetalLB, NFD and storage (LVMS) from
OLM operators. Do **not** target it with the Helm charts for those. Use their CRs/config instead.

The rpi `k3s`, `nuc`, `rke2-1`, `rke2-2`, `sm5` and `oci` clusters, Rancher and Fleet are gone.

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

### Mapping from Fleet (historical)
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
(set with `templatePatch`). `nas` is `"true"` (prune + selfHeal). With the Source Hydrator, the `rendered` branch diff is what gets
reviewed; set the label to `"false"` to go back to syncing by hand. The label lives in
`argocd/bootstrap/cluster-nas.yaml`, which is applied with `kubectl apply -k argocd/bootstrap`, not by ArgoCD.

## Bootstrap
```bash
helm --kube-context sm4 upgrade --install argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm --version 10.11.6 \
  -n argocd --create-namespace -f argocd/apps/argocd/values.yaml
kubectl --context sm4 apply -k argocd/bootstrap
```
After that, ArgoCD manages itself (`argocd/applicationsets/argocd/argocd.yaml`).

### Registering metal1
metal1's cluster Secret comes from Vault, not from `argocd cluster add`:
```bash
kubectl --context metal1 apply -f argocd/bootstrap/spokes/metal1-argocd-manager.yaml
# store server, the argocd-manager-token token and the API CA (base64 PEM) in Vault
vault kv put secret/argocd-cluster-metal1 server=https://api.metal1.okd.marthy.xyz:6443 \
  bearerToken=@token caData=@ca.b64
```
The ExternalSecret `cluster-metal1` (`argocd/apps/global-apps/external-secrets-config`) turns that
into the cluster Secret with `homelab/cluster=metal1` and `homelab/auto-sync=true`. Like any new
hydrated app, the first app on metal1 (`reloader-metal1`) only gets output on `rendered` after a
follow-up commit on `main` (docs/source-hydrator.md).

### OKD operators on metal1
The OLM operators on metal1 were installed by hand and captured into `argocd/apps/okd/<dir>` on
2026-11-12 (#2024). Each directory holds the Namespace, OperatorGroup, Subscription and the operand,
and the ApplicationSet `okd-operators` turns each one into an app `okd-<dir>-metal1`. All come from
`redhat-operators` with automatic approval:

| dir | operator(s) | operand |
|---|---|---|
| cert-manager-operator | openshift-cert-manager-operator | CertManager `cluster` |
| custom-metrics-autoscaler | openshift-custom-metrics-autoscaler-operator | KedaController `keda` |
| external-dns-operator | external-dns-operator | none |
| external-secrets-operator | openshift-external-secrets-operator | none yet (ESO not deployed, see below) |
| kubernetes-nmstate | kubernetes-nmstate-operator | NMState `nmstate` |
| metallb-operator | metallb-operator | MetalLB `metallb` |
| nfd | nfd | NodeFeatureDiscovery `nfd-instance` |
| openshift-storage | local-storage-operator, lvms-operator | LVMCluster `test-lvmcluster` |

To add an operator, create a new directory with the same files; the ApplicationSet picks it up.
Keep OLM-generated OperatorGroup names as they are (`openshift-nfd-5zfqg`), because two
OperatorGroups in one namespace break OLM.

Not in git yet: the ClusterIssuer `letsencrypt-prod`, its Route53 Secret and the route certificates.
They wait for ESO on metal1 (branch `feat/metal1-eso-vault`), which needs Vault Kubernetes auth at
`auth/kubernetes-metal1` first.

## Known gaps
- **Secrets backend is down.** `vault-backend` points at `vault.oci.marthy.xyz`, which went away
  with the OCI cluster. Existing Secrets on nas still work, but no ExternalSecret can refresh,
  and metal1 has no SecretStore.
- **Monitoring:** there is no Prometheus on nas. `prometheus-operator-crds` is installed so
  ServiceMonitors apply, but nothing scrapes them yet.
- **immich:** chart 0.12 removed the bundled postgres subchart, but `values-nas.yaml` still
  configures `postgresql:`, so it does not render.
- **kube-vip:** this is a control-plane VIP, so it belongs to cluster bootstrap, not ArgoCD.
  The manifests stay in `kube-vip/` and are applied by hand.

## Rancher leftovers on the cluster
Rancher left `wrangler.cattle.io/auth-prov-v2-crole*` finalizers on ClusterRoles and
ClusterRoleBindings, so objects with a `deletionTimestamp` never go away. The dead ones
(chaos-mesh, capi, provisioning-rke, prometheus-adapter) can have the finalizer stripped.
`argocd-repo-server` and `external-dns-external-dns` are still in use: check that ArgoCD
recreates them before touching them.
