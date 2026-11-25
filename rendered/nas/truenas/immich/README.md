# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout aebc6f3a862373b781fa85b0171ff388e6fe279d
kustomize build ./argocd/apps/truenas/immich/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
