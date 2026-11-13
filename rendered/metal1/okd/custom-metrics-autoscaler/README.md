# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout aa76a775a54974ff9009280b4bfff1daa7eaf39a
kustomize build ./argocd/apps/okd/custom-metrics-autoscaler --enable-helm --load-restrictor LoadRestrictionsNone
```
