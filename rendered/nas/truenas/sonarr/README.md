# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout efe06249e339c96f502f6967df79993dca13faab
kustomize build ./argocd/apps/truenas/sonarr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
