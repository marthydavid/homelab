# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout f0a35d80d31522a08ccb396eda22ca92d4bd017a
kustomize build ./argocd/apps/global-apps/reloader/overlays/metal1 --enable-helm --load-restrictor LoadRestrictionsNone
```
