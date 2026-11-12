# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 77fb737edc8c26c67a1e91a08041589e515a3337
kustomize build ./argocd/apps/global-apps/blackbox-exporter/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
