# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout f974078ac546c71bd2fa788d9766bcffc74fffd6
kustomize build ./argocd/apps/truenas/radarr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
