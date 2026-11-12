# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout cdd98c4c9b0263f82e0c62a7b532199ee9a2364d
kustomize build ./argocd/apps/vault/vault/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
