# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 9170cb92f94a88f4203804778516bbc28391b88a
kustomize build ./argocd/apps/truenas/qbit/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
