# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 951bc64fb8674e68f191426a12731d8bd5746bfb
kustomize build ./argocd/apps/global-apps/kyverno/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
