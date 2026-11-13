# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 01831d140b40554b7e92331c1a6b7c5020ef5ac9
kustomize build ./argocd/apps/okd/custom-metrics-autoscaler --enable-helm --load-restrictor LoadRestrictionsNone
```
