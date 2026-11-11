# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 6cd48afb2e1f9e070b012262d1e3dbadc8433eb9
kustomize build ./argocd/apps/global-apps/reloader/overlays/nas --enable-helm
```
