# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout cfe1f40a8b9266571d1b522e825dcfa9d0598ace
kustomize build ./argocd/apps/global-apps/descheduler/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
