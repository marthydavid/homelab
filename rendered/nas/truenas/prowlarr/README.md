# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 9a20b793a4809607bfae13aad5a9a769fb363b51
kustomize build ./argocd/apps/truenas/prowlarr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
