#!/usr/bin/env bash
# Writes a kubeconfig for the virtual cluster and keeps a port-forward to it running in the
# background. Never touches ~/.kube/config. Idempotent.
source "$(dirname "$0")/lib.sh"
require_host_ctx

mkdir -p "$(dirname "$VC_KUBECONFIG")"
PIDFILE="$(dirname "$VC_KUBECONFIG")/port-forward.pid"

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  :
else
  nohup kubectl --context "$HOST_CTX" -n "$HOST_NS" port-forward "svc/$VC_NAME" "${VC_LOCAL_PORT}:443" \
    >"$(dirname "$VC_KUBECONFIG")/port-forward.log" 2>&1 &
  echo $! >"$PIDFILE"
fi

# vcluster stores the admin kubeconfig of the virtual cluster in the secret vc-<name>
host_kubectl -n "$HOST_NS" get secret "vc-$VC_NAME" -o jsonpath='{.data.config}' | base64 -d \
  | sed -E "s#server: .*#server: https://127.0.0.1:${VC_LOCAL_PORT}#" >"$VC_KUBECONFIG"
chmod 600 "$VC_KUBECONFIG"

for _ in $(seq 1 30); do
  if vc_kubectl get ns >/dev/null 2>&1; then
    echo "virtual cluster reachable: KUBECONFIG=$VC_KUBECONFIG"
    exit 0
  fi
  sleep 2
done
echo "virtual cluster not reachable, see $(dirname "$VC_KUBECONFIG")/port-forward.log" >&2
exit 1
