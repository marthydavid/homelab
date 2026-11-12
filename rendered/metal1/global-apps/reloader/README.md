# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout ef64c463eb095601a19518b7fc80a5020cf9011c
kustomize build ./argocd/apps/global-apps/reloader/overlays/metal1 --enable-helm --load-restrictor LoadRestrictionsNone
```
