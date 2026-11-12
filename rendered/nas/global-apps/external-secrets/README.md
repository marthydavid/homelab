# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 6e2363ddaa9214f7b7afbe836a3a412c045a4191
kustomize build ./argocd/apps/global-apps/external-secrets/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
