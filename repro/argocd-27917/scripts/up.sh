#!/usr/bin/env bash
# Creates the vcluster on the host cluster and installs one Argo CD per entry of
# ARGOCD_CHART (see lib.sh) inside it. Idempotent, safe to re-run.
source "$(dirname "$0")/lib.sh"

helm repo add loft https://charts.loft.sh --force-update >/dev/null
helm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null
helm repo update loft argo >/dev/null

echo ">> host namespace $HOST_NS on context $HOST_CTX"
host_kubectl apply -f "$REPRO_DIR/vcluster/namespace.yaml"

echo ">> vcluster $VC_NAME (chart $VC_CHART_VERSION)"
helm --kube-context "$HOST_CTX" upgrade --install "$VC_NAME" loft/vcluster \
  --version "$VC_CHART_VERSION" --namespace "$HOST_NS" \
  -f "$REPRO_DIR/vcluster/values.yaml" --wait --timeout 10m

"$(dirname "$0")/connect.sh"

# the CRD owner must be installed first, the others only reference the CRDs
echo ">> argo-cd instance $CRD_OWNER (chart ${ARGOCD_CHART[$CRD_OWNER]}) in namespace argocd-$CRD_OWNER"
vc_helm upgrade --install "argocd-$CRD_OWNER" argo/argo-cd --version "${ARGOCD_CHART[$CRD_OWNER]}" \
  --namespace "argocd-$CRD_OWNER" --create-namespace -f "$REPRO_DIR/argocd/values.yaml" --wait --timeout 10m

for inst in "${!ARGOCD_CHART[@]}"; do
  [[ "$inst" == "$CRD_OWNER" ]] && continue
  # an optional argocd/values-<instance>.yaml adds per-instance settings (e.g. the `fixed` image)
  inst_values=()
  [[ -f "$REPRO_DIR/argocd/values-$inst.yaml" ]] && inst_values=(-f "$REPRO_DIR/argocd/values-$inst.yaml")
  echo ">> argo-cd instance $inst (chart ${ARGOCD_CHART[$inst]}) in namespace argocd-$inst"
  vc_helm upgrade --install "argocd-$inst" argo/argo-cd --version "${ARGOCD_CHART[$inst]}" \
    --namespace "argocd-$inst" --create-namespace \
    -f "$REPRO_DIR/argocd/values.yaml" -f "$REPRO_DIR/argocd/values-baseline.yaml" "${inst_values[@]}" \
    --wait --timeout 10m
done

echo ">> done. Images (repo-server / application-controller):"
for inst in "${!ARGOCD_CHART[@]}"; do
  repo="$(vc_kubectl -n "argocd-$inst" get deploy "argocd-$inst-repo-server" -o jsonpath='{.spec.template.spec.containers[0].image}')"
  ctrl="$(vc_kubectl -n "argocd-$inst" get sts "argocd-$inst-application-controller" -o jsonpath='{.spec.template.spec.containers[0].image}')"
  printf '   %-8s %s | %s\n' "$inst" "$repo" "$ctrl"
done
