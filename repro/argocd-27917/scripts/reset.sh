#!/usr/bin/env bash
# reset.sh <instance> <scenario>: remove the parent, its children and their workload
# namespace inside the vcluster so the scenario can be run again from scratch.
source "$(dirname "$0")/lib.sh"
inst="${1:?instance}" scen="${2:?scenario}"
ns="argocd-$inst"

vc_kubectl -n "$ns" delete application "root-$inst-$scen" --ignore-not-found --wait=false >/dev/null
# children carry the resources finalizer, give the cascade a moment, then force whatever is left
for _ in $(seq 1 30); do
  left=$(vc_kubectl -n "$ns" get applications -l "repro.homelab/scenario=$scen" -o name 2>/dev/null | wc -l)
  [[ "$left" -eq 0 ]] && break
  sleep 2
done
for app in $(vc_kubectl -n "$ns" get applications -l "repro.homelab/scenario=$scen" -o name 2>/dev/null); do
  # the app may vanish between the list and these calls (cascade finished), that is fine
  vc_kubectl -n "$ns" patch "$app" --type merge -p '{"metadata":{"finalizers":null}}' >/dev/null 2>&1 || true
  vc_kubectl -n "$ns" delete "$app" --ignore-not-found --wait=false >/dev/null 2>&1 || true
done
vc_kubectl delete ns "repro-$inst-$scen" --ignore-not-found --wait=true >/dev/null
echo "reset $inst/$scen"
