# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout ff94760e25a1003af2c1373123da6a13256a6386
kustomize build ./argocd/apps/truenas/tautulli/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
