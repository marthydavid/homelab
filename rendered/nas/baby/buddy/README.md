# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 2a405ee7a9461c3e48f5f079400b022031e34d59
kustomize build ./argocd/apps/baby/buddy/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
