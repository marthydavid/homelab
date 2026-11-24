# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 6e4b488152de6fcb51a91bf34ab4126535aecac3
kustomize build ./argocd/apps/truenas/qbit/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
