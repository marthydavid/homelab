# Vault on nas (OCI Object Storage + OCI KMS)

Needs an OCI user whose API key can read/write the `vault` and `vault-lock` buckets and `use keys` on the
`vault` KMS key. Create the bootstrap Secret by hand (it cannot live in Vault itself):

```bash
kubectl create namespace vault
kubectl -n vault create secret generic vault-oci \
  --from-file=key.pem=<path-to-private-key.pem> \
  --from-literal=config="[DEFAULT]
user=<user-ocid>
fingerprint=<key-fingerprint>
tenancy=<tenancy-ocid>
region=eu-frankfurt-1
key_file=/home/vault/.oci/key.pem"
```

Policy for that user's group:

```
Allow group <group> to manage objects in compartment <c> where any {target.bucket.name='vault', target.bucket.name='vault-lock'}
Allow group <group> to read buckets in compartment <c> where any {target.bucket.name='vault', target.bucket.name='vault-lock'}
Allow group <group> to use keys in compartment <c> where target.key.id='<key ocid>'
```

If the old server's data is still in the `vault` bucket, Vault starts with it as is; otherwise
`kubectl -n vault exec vault-0 -- vault operator init` (prints recovery keys, store them offline).

Then point the ClusterSecretStore (`argocd/apps/global-apps/external-secrets-config`) at
`http://vault.vault.svc.cluster.local:8200` (done).
