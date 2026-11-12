# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 801e78b610ca057b008741fa57cd5bb901dcf4c9
kustomize build ./argocd/apps/truenas/seerr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
