# homelab

GitOps repo for a homelab. ArgoCD is the only deployment path (Rancher Fleet was removed; it lives only in git history). Read `docs/argocd-migration.md` and `docs/source-hydrator.md` before larger changes.

## Clusters
- `nas`: k3s on SM4, kube context `sm4`, the ArgoCD hub. Everything is deployed here. Auto-sync with prune and selfHeal.
- `metal1`: OKD 4.22 (sm1-sm3). OLM operators provide cert-manager, external-secrets, external-dns, MetalLB, NFD, nmstate, KEDA and LVMS. Never target metal1 with the Helm charts for those; use their CRs in `argocd/apps/okd/<dir>`. Keep OLM-generated OperatorGroup names.

## Layout
- `argocd/bootstrap/`: applied by hand (`kubectl apply -k argocd/bootstrap`), not by ArgoCD. Holds `root.yaml` (app-of-apps over `argocd/applicationsets`) and the cluster Secrets.
- `argocd/applicationsets/<group>/<app>.yaml`: one ApplicationSet per app. They use the cluster generator and select clusters by the `homelab/cluster` label.
- `argocd/apps/<group>/<app>/`: `values.yaml` or `*-values.yaml`, optional `values-<cluster>.yaml`, plain manifests, or kustomize `base/` + `overlays/<cluster>/`.
- `kube-vip/`: control-plane VIP, applied by hand, outside ArgoCD.

## Source Hydrator
Apps are hydrated from `main` to the `rendered` branch, which holds only generated manifests. Never edit `rendered` by hand. Review the `rendered` diff, not the ArgoCD UI diff. Hydration needs a single source, so Helm apps are wrapped in kustomize `helmCharts` (`overlays/<cluster>/kustomization.yaml`, chart version lives there, declare `apiVersions` for CRD-gated objects). Use a distinct `syncSource.path` per app. A newly converted app only gets output after a follow-up commit on `main`, once the app exists on the cluster with `sourceHydrator`.

## Conventions
- Commit messages are semantic (`chore(renovate): ...`); PRs go to `main`.
- Renovate does version bumps. Do not automerge Vault or OLM operator versions. The external-dns chart is held back (#1908).
- Never commit secrets. They come from Vault through ExternalSecrets.
- Validate before pushing: `kubectl kustomize --enable-helm <dir>` for kustomize apps, `helm template -f <values>` for Helm apps.

## Known gaps
Vault backend is down (points at the removed OCI cluster), no Prometheus on nas, immich values still set `postgresql:` and do not render. Details in `docs/argocd-migration.md`.
