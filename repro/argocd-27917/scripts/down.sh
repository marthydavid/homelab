#!/usr/bin/env bash
# Removes the whole reproduction from the host cluster: the vcluster (and with it everything
# inside) and the host namespace. Refuses to touch a namespace without the repro label.
source "$(dirname "$0")/lib.sh"

label=$(host_kubectl get ns "$HOST_NS" -o jsonpath='{.metadata.labels.homelab/repro}' 2>/dev/null || true)
if [[ "$label" != "argocd-27917" ]]; then
  echo "namespace $HOST_NS on $HOST_CTX is missing or not labelled homelab/repro=argocd-27917, not deleting" >&2
  exit 1
fi

PIDFILE="$(dirname "$VC_KUBECONFIG")/port-forward.pid"
[[ -f "$PIDFILE" ]] && kill "$(cat "$PIDFILE")" 2>/dev/null || true
rm -f "$PIDFILE" "$VC_KUBECONFIG"

helm --kube-context "$HOST_CTX" uninstall "$VC_NAME" --namespace "$HOST_NS" --wait || true
host_kubectl delete pvc -n "$HOST_NS" --all --ignore-not-found
host_kubectl delete ns "$HOST_NS" --wait
