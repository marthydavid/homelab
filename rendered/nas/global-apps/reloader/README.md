# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 86b53acf1d86bdbec22cfa42fabc1d12c9ad2970
kustomize build ./argocd/apps/global-apps/reloader/overlays/nas --enable-helm
```
