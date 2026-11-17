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

for inst in "${!ARGOCD_CHART[@]}"; do
  extra=()
  [[ "$inst" != "$CRD_OWNER" ]] && extra=(-f "$REPRO_DIR/argocd/values-baseline.yaml")
  echo ">> argo-cd instance $inst (chart ${ARGOCD_CHART[$inst]}) in namespace argocd-$inst"
  # the CRD owner must be installed first, the others only reference the CRDs
  if [[ "$inst" == "$CRD_OWNER" ]]; then
    vc_helm upgrade --install "argocd-$inst" argo/argo-cd --version "${ARGOCD_CHART[$inst]}" \
      --namespace "argocd-$inst" --create-namespace -f "$REPRO_DIR/argocd/values.yaml" --wait --timeout 10m
  fi
done
for inst in "${!ARGOCD_CHART[@]}"; do
  [[ "$inst" == "$CRD_OWNER" ]] && continue
  vc_helm upgrade --install "argocd-$inst" argo/argo-cd --version "${ARGOCD_CHART[$inst]}" \
    --namespace "argocd-$inst" --create-namespace \
    -f "$REPRO_DIR/argocd/values.yaml" -f "$REPRO_DIR/argocd/values-baseline.yaml" --wait --timeout 10m
done

echo ">> done. Argo CD versions:"
for inst in "${!ARGOCD_CHART[@]}"; do
  printf '   %-8s %s\n' "$inst" "$(vc_kubectl -n "argocd-$inst" get deploy -o jsonpath='{.items[?(@.metadata.name=="argocd-'"$inst"'-repo-server")].spec.template.spec.containers[0].image}')"
done
