# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 12b55a0d5c501b626f531ff1e33b738db8d79265
kustomize build ./argocd/apps/okd/custom-metrics-autoscaler --enable-helm --load-restrictor LoadRestrictionsNone
```
