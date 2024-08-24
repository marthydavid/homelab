Need to use the forked repo/image
```bash
ALTER EXTENSION vectors UPDATE;
SELECT pgvectors_upgrade();
```
```bash
 pgvectors_upgrade
-------------------

(1 row)
```
restart pod

```bash
SELECT
        I.relname AS indexname
    FROM pg_index X JOIN
         pg_class I ON I.oid = X.indexrelid JOIN
         pg_am A ON A.oid = I.relam
    WHERE A.amname = 'vectors';
```
```bash
 indexname
------------
 clip_index
 face_index
(2 rows)
```
```bash
REINDEX INDEX  clip_index;
REINDEX INDEX  face_index;
```

restart immich pod