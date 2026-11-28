# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout f8e733b2b13395fbcee7e7dc0a8e70f6b43cc15a
kustomize build ./argocd/apps/infra/nexus/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
