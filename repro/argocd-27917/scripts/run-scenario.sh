#!/usr/bin/env bash
# run-scenario.sh <instance> <scenario> [timeout-seconds]
# Creates the parent Application in that Argo CD instance, triggers its sync and records
# the order in which the child Applications appear. Exit codes of observe.py:
#   0 wave gate held, 3 gate released early (bug reproduced), 2 inconclusive.
source "$(dirname "$0")/lib.sh"
inst="${1:?instance}" scen="${2:?scenario}" timeout="${3:-240}"
ns="argocd-$inst"

"$(dirname "$0")/reset.sh" "$inst" "$scen"

helm template roots "$REPRO_DIR/gitops/roots" --set instance="$inst" --set "scenarios={$scen}" \
  --set repoURL="$GIT_REPO_URL" --set targetRevision="$GIT_REVISION" | vc_kubectl apply -f - >/dev/null

# wait until the controller has picked the Application up, then start the sync
vc_kubectl -n "$ns" wait --for=jsonpath='{.status.sync.status}' "application/root-$scen" --timeout=120s >/dev/null
vc_kubectl -n "$ns" patch application "root-$scen" --type merge \
  -p '{"operation":{"initiatedBy":{"username":"repro"},"sync":{"syncOptions":["ServerSideApply=true"]}}}' >/dev/null

exec python3 "$(dirname "$0")/observe.py" --kubeconfig "$VC_KUBECONFIG" --namespace "$ns" \
  --scenario "$scen" --timeout "$timeout"
