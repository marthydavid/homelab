# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 0a66b56970b329fa845d77122362653d7e17b086
kustomize build ./argocd/apps/database/operator/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
