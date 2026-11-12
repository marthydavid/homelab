# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout c1e3d9fb3e482ab2cffb8230b958e3e65b8f02a5
kustomize build ./argocd/apps/truenas/seerr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
