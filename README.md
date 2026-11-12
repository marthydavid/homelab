Generated on metal1 with the jq logic of stakater/operator-versions (get-versions.sh).
`metal1/<package>.json` lists the head version of every channel of each OLM package;
Renovate's custom datasource `okd-operators` reads it. Seeded by hand on 2026-11-12; the
publisher CronJob in `argocd/apps/okd/operator-versions` keeps it current once enabled.
