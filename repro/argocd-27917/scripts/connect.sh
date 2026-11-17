#!/usr/bin/env bash
# Writes a kubeconfig for the virtual cluster and makes sure a port-forward to it is running
# in the background. Never touches ~/.kube/config. Idempotent and cheap when the tunnel works,
# the other scripts call it before they use the virtual cluster.
#
# A bare `kubectl port-forward` dies on any dropped connection ("lost connection to pod"), so it
# runs under a tiny supervisor loop that restarts it, and "running" is judged by whether the
# virtual cluster answers, not by whether a process exists.
source "$(dirname "$0")/lib.sh"
require_host_ctx

CACHE="$(dirname "$VC_KUBECONFIG")"
PIDFILE="$CACHE/port-forward.pid"
mkdir -p "$CACHE"

tunnel_ok() { [[ -s "$VC_KUBECONFIG" ]] && vc_kubectl --request-timeout=5s get --raw /readyz >/dev/null 2>&1; }

write_kubeconfig() {
  # vcluster stores the admin kubeconfig of the virtual cluster in the secret vc-<name>; it only
  # appears once the control plane is up, which can be after `helm install --wait` returned
  for _ in $(seq 1 90); do
    host_kubectl -n "$HOST_NS" get secret "vc-$VC_NAME" >/dev/null 2>&1 && break
    sleep 2
  done
  host_kubectl -n "$HOST_NS" get secret "vc-$VC_NAME" -o jsonpath='{.data.config}' | base64 -d \
    | sed -E "s#server: .*#server: https://127.0.0.1:${VC_LOCAL_PORT}#" >"$VC_KUBECONFIG"
  chmod 600 "$VC_KUBECONFIG"
}

if tunnel_ok; then
  echo "virtual cluster reachable: KUBECONFIG=$VC_KUBECONFIG"
  exit 0
fi

# not working: stop whatever is left of an earlier supervisor (its whole process group) and start fresh
if [[ -f "$PIDFILE" ]]; then
  kill -- "-$(cat "$PIDFILE")" 2>/dev/null || kill "$(cat "$PIDFILE")" 2>/dev/null || true
  rm -f "$PIDFILE"
fi
write_kubeconfig
setsid nohup bash -c '
  while true; do
    kubectl --context "$0" -n "$1" port-forward "svc/$2" "$3:443"
    sleep 1
  done' "$HOST_CTX" "$HOST_NS" "$VC_NAME" "$VC_LOCAL_PORT" >"$CACHE/port-forward.log" 2>&1 &
echo $! >"$PIDFILE"

for _ in $(seq 1 30); do
  if tunnel_ok; then
    echo "virtual cluster reachable: KUBECONFIG=$VC_KUBECONFIG"
    exit 0
  fi
  sleep 2
done
echo "virtual cluster not reachable, see $CACHE/port-forward.log" >&2
exit 1
