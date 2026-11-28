#!/usr/bin/env bash
# Builds Argo CD v3.6.1 + argo-cd#28066 on the host cluster (see build/buildconfig.yaml) and
# follows the build log. Result: image-registry.openshift-image-registry.svc:5000/<ns>/argocd-27917-test:v3.6.1-pr28066
source "$(dirname "$0")/lib.sh"
require_host_ctx

FORK_URL="${FORK_URL:-https://github.com/marthydavid/argo-cd.git}"
FORK_BRANCH="${FORK_BRANCH:-fix/27917-aggregate-missing-on-v3.6.1}"

host_kubectl apply -f "$REPRO_DIR/build/imagestream.yaml" -f "$REPRO_DIR/build/buildconfig.yaml"

# stamp the binary with the commit that is actually built
commit="$(git ls-remote "$FORK_URL" "refs/heads/$FORK_BRANCH" | cut -f1)"
[[ -n "$commit" ]] || { echo "branch $FORK_BRANCH not found on $FORK_URL" >&2; exit 1; }
echo ">> building $FORK_BRANCH @ $commit"

# --wait is what makes the exit status reflect a failed build, --follow alone returns 0
exec oc --context "$HOST_CTX" -n "$HOST_NS" start-build argocd-pr28066 \
  --build-arg="GIT_COMMIT=$commit" --build-arg="BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)" --follow --wait
