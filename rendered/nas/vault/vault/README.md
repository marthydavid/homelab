# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout e87ba764d02c624d3fa9d5971d79e0a1d67080e8
kustomize build ./argocd/apps/vault/vault/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
