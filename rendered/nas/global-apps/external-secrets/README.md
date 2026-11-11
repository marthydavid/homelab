# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 9fd0fc5400294f9a4361bc5c0030ec88de0e6150
kustomize build ./argocd/apps/global-apps/external-secrets/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
