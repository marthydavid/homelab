# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 93699344442f75f34d60954ff5e2eda05c77aa0b
kustomize build ./argocd/apps/ipmi/sm1/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
