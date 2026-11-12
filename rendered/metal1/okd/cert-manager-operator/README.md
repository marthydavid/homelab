# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 137fbecb325e02ad2cab7a012ccad6d36cefc78a
kustomize build ./argocd/apps/okd/cert-manager-operator --enable-helm --load-restrictor LoadRestrictionsNone
```
