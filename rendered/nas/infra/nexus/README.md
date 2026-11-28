# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 72fc3b4a651b2f34cc28526489cd307486c7cbff
kustomize build ./argocd/apps/infra/nexus/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
