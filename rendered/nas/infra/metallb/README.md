# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 7f8db8bb343397871f88b944fb14c1a8dac58e95
kustomize build ./argocd/apps/infra/metallb/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
