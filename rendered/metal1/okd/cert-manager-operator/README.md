# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 295112a7e082deae9022514134bb782a26258af7
kustomize build ./argocd/apps/okd/cert-manager-operator --enable-helm --load-restrictor LoadRestrictionsNone
```
