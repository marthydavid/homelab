# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 3a8e4a83dfe562309d10fb814c60b0a1676ff5e5
kustomize build ./argocd/apps/truenas/qbit/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
