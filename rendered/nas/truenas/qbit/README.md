# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout da14e1c650a16c62c7d57134ef086d7cb4ec798b
kustomize build ./argocd/apps/truenas/qbit/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
