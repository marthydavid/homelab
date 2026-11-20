# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 400cca404e95759617a549c4201f7b38ee884d12
kustomize build ./argocd/apps/truenas/immich/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
