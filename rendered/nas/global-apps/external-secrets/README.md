# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 23f6787a8d7d880a16297e816bb7283fd98873e4
kustomize build ./argocd/apps/global-apps/external-secrets/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
