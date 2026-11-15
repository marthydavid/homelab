# Manifest Hydration

To hydrate the manifests in this repository, run the following commands:

```shell
git clone https://github.com/marthydavid/homelab
# cd into the cloned directory
git checkout 78ecf0cc29b46c33933e48e16ec2e6379fa75ed5
kustomize build ./argocd/apps/truenas/radarr/overlays/nas --enable-helm --load-restrictor LoadRestrictionsNone
```
