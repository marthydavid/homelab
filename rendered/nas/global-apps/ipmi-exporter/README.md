# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 6c8c8ca487ebadfdd5ffcc4c9a9ecdc10e0aea69
kustomize build ./argocd/apps/global-apps/ipmi-exporter/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
