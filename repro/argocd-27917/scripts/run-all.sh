#!/usr/bin/env bash
# Runs every scenario on every Argo CD instance, one after the other, and prints a matrix.
source "$(dirname "$0")/lib.sh"
timeout="${1:-240}"
declare -A result
for scen in "${SCENARIOS[@]}"; do
  for inst in "${!ARGOCD_CHART[@]}"; do
    echo "================ $scen on $inst (chart ${ARGOCD_CHART[$inst]}) ================"
    set +e
    "$(dirname "$0")/run-scenario.sh" "$inst" "$scen" "$timeout"
    rc=$?
    set -e
    case $rc in
      0) result[$scen,$inst]="gate held" ;;
      3) result[$scen,$inst]="EARLY RELEASE (bug)" ;;
      2) result[$scen,$inst]="inconclusive" ;;
      *) result[$scen,$inst]="ERROR, no observation (rc=$rc)" ;;
    esac
  done
done
echo
echo "================ summary ================"
for scen in "${SCENARIOS[@]}"; do
  for inst in "${!ARGOCD_CHART[@]}"; do
    printf '%-14s %-8s chart %-8s %s\n' "$scen" "$inst" "${ARGOCD_CHART[$inst]}" "${result[$scen,$inst]}"
  done
done
