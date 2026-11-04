# immich

Postgres runs as the CNPG cluster `immich-postgres` (`../immich-postgres`, VectorChord image);
the chart (0.12) only deploys immich, machine-learning and valkey. CNPG creates the
`immich-postgres-app` secret the chart reads.

## One-off migration steps (all manual, nothing here is automatic)

1. Snapshot the retained volumes first: Postgres `pvc-888fd4fe-1884-4c5e-8b41-f243531c9ba4`
   and library `pvc-e8b89821-362b-4aad-af8c-c980c31d17dc` (`zfs snapshot` on sm4).
2. Re-bind the Released library PV so `immich-prereq` claims it instead of creating an empty volume:
   `kubectl patch pv pvc-e8b89821-362b-4aad-af8c-c980c31d17dc --type json -p '[{"op":"remove","path":"/spec/claimRef"}]'`
3. Sync `truenas-immich-prereq-nas`, then `truenas-immich-postgres-nas` (needs the CNPG operator).
4. Restore the old database: start the old pgvecto.rs Postgres (PVC `data-immich-postgresql-0`),
   `pg_dump` it, restore into `immich-postgres` (the vchord extension is created by the cluster; drop the
   pgvecto.rs `vectors` index columns per the immich VectorChord migration docs before restoring).
5. Sync `truenas-immich-nas`.
