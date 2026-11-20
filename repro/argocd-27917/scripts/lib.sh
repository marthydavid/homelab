#!/usr/bin/env bash
# Shared settings for the argo-cd#27917 reproduction scripts. Source this, do not run it.
set -euo pipefail

REPRO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Host cluster that runs the vcluster. Everything on the host goes through this context
# explicitly, the current kubectl context is never used or changed.
HOST_CTX="${HOST_CTX:-metal1}"
HOST_NS="${HOST_NS:-vcluster-argocd-27917}"
VC_NAME="${VC_NAME:-argocd-27917}"
VC_CHART_VERSION="${VC_CHART_VERSION:-0.37.7}"

# kubeconfig for the *virtual* cluster, kept out of ~/.kube/config and out of git
VC_KUBECONFIG="${VC_KUBECONFIG:-${XDG_CACHE_HOME:-$HOME/.cache}/argocd-27917/kubeconfig}"
VC_LOCAL_PORT="${VC_LOCAL_PORT:-18443}"

# Argo CD instances: name -> argo-helm chart version (app version in the comment).
# `latest` is the chart this repro is about, `v339` is the last known-good version from the issue.
declare -A ARGOCD_CHART=(
  [latest]="${ARGOCD_LATEST_CHART:-10.18.0}"   # Argo CD v3.6.1
  [v339]="${ARGOCD_V339_CHART:-9.5.11}"        # Argo CD v3.3.9
  # latest chart, but the application-controller is the build of v3.6.1 + argo-cd#28066 (see
  # argocd/values-fixed.yaml and scripts/build-image.sh, the image must exist before up.sh)
  [fixed]="${ARGOCD_FIXED_CHART:-10.18.0}"
)
# Which instance owns the CRDs (only one release may install them).
CRD_OWNER="latest"

# Git source the Applications inside the vcluster pull from.
GIT_REPO_URL="${GIT_REPO_URL:-https://github.com/marthydavid/homelab}"
GIT_REVISION="${GIT_REVISION:-repro/argocd-27917-appofapps-syncwave}"

SCENARIOS=(slow-workload mixed-live)

host_kubectl() { kubectl --context "$HOST_CTX" "$@"; }
vc_kubectl() { kubectl --kubeconfig "$VC_KUBECONFIG" "$@"; }
vc_helm() { helm --kubeconfig "$VC_KUBECONFIG" "$@"; }

require_host_ctx() {
  if ! host_kubectl get ns "$HOST_NS" >/dev/null 2>&1; then
    echo "host namespace $HOST_NS not found on context $HOST_CTX" >&2
    return 1
  fi
}
