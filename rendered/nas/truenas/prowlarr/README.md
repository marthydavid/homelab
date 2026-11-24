# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 607d9785ba9d67a69a0f48d3ac9aa23d0ca7d668
kustomize build ./argocd/apps/truenas/prowlarr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
