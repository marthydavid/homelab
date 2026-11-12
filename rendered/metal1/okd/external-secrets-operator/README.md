# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 98ee931900d18764556f4fef0b95c6d7376446fd
kustomize build ./argocd/apps/okd/external-secrets-operator --enable-helm --load-restrictor LoadRestrictionsNone
```
