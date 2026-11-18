# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 80b5254c8684bdc8f91208074a9c7904d2490c3a
kustomize build ./argocd/apps/truenas/sonarr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
