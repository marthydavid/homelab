# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 37516abf866e3d8b359a252a95c64ea5ff1e87d2
kustomize build ./argocd/apps/okd/custom-metrics-autoscaler --enable-helm --load-restrictor LoadRestrictionsNone
```
