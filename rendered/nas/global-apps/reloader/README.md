# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 2c557073e104a0ee904ab44221295e5ffde8fdb7
kustomize build ./argocd/apps/global-apps/reloader/overlays/nas --enable-helm
```
