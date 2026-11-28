# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 6cc844894ce861d6cec8f21b23e0dd1010e5e14f
kustomize build ./argocd/apps/infra/nexus/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
