# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 9fd2b17aacc7c0c7d096dafa71e4faeb3b1809fe
kustomize build ./argocd/apps/truenas/qbit/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
