# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout cac20ca1d0ebd3f3894d8ed4e8507f3133f770d4
kustomize build ./argocd/apps/okd/external-secrets-operator --enable-helm --load-restrictor LoadRestrictionsNone
```
