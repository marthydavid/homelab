# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 4bccef726492261b9c568f672fe84f464e77df91
kustomize build ./argocd/apps/truenas/prowlarr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
