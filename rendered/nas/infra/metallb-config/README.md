# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 17078c3a44674c1b170d208644e8284ddc37fc93
kustomize build ./argocd/apps/infra/metallb-config/overlays/nas --enable-helm
```
