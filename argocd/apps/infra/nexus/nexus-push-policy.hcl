# Vault policy for the External Secrets AppRole (vault-backend ClusterSecretStore): write access to
# exactly one KV v2 secret, so the PushSecret nexus3-root-seed can seed it. Read is already granted
# by the existing policy. Apply with a Vault admin token:
#
#   vault policy write nexus-push nexus-push-policy.hcl
#   vault write auth/approle/role/external-secrets \
#     token_policies="$(vault read -format=json auth/approle/role/external-secrets \
#       | jq -r '.data.token_policies + ["nexus-push"] | unique | join(",")')"
#
# (the role name is the one behind roleId 8e435180-... in the ClusterSecretStore; the repo marks it
# "external-secrets"). To remove the write access afterwards, drop nexus-push from the role.

path "secret/data/nexus" {
  capabilities = ["create", "update", "read"]
}

path "secret/metadata/nexus" {
  capabilities = ["create", "update", "read"]
}
