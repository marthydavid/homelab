# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout e7d89c4e883b369a87e7ed0b9f53a33131d92d5f
kustomize build ./argocd/apps/truenas/nut-exporter/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
