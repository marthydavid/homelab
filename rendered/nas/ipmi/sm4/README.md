# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 44c6be56ee639bfffd029a86c1b04d06d29d0171
kustomize build ./argocd/apps/ipmi/sm4/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
