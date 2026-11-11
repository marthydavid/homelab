# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout a11d96a29fe4e2c0786fd480d55d83f2895a9063
kustomize build ./argocd/apps/global-apps/kyverno/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
