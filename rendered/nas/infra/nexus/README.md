# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 4919c52833a3c104b8dd8b41374a3e4ab42caad4
kustomize build ./argocd/apps/infra/nexus/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
