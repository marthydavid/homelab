# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 10124cafe8ac5371ce30454f637b8336a907c174
kustomize build ./argocd/apps/global-apps/blackbox-exporter/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
