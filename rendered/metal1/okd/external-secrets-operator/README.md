# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 1c963ffbbe47aa934ef7195c20242907413fd944
kustomize build ./argocd/apps/okd/external-secrets-operator --enable-helm --load-restrictor LoadRestrictionsNone
```
