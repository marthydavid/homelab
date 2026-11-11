# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout f5155ec8f435436ed6164dc2facef8c721f9cd77
kustomize build ./argocd/apps/truenas/radarr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
