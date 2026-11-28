# metal1 restricted network

Goal: VLAN 11 (metal1, `192.168.11.0/24`) has no direct internet path. Images come from the Nexus
mirror on sm4, and a short list of non-registry hosts goes through Squid on sm4. The mirror is not
air-gapped: Nexus is a pull-through cache and reaches the upstream registries on demand.

## Why one Nexus host per registry
Digest pulls are content-addressed and cannot collide, but tag pulls can: a shared `group` repo
resolves `name:tag` from whichever member answers first. Each upstream therefore gets its own
Nexus repo, connector and ingress host (`<registry>.nexus.marthy.xyz`), and the `group` repo is not
used as a mirror target.

| Source registry | Nexus host |
|---|---|
| quay.io | quay-io.nexus.marthy.xyz |
| docker.io | docker-io.nexus.marthy.xyz |
| ghcr.io | ghcr-io.nexus.marthy.xyz |
| mirror.gcr.io | mirror-gcr-io.nexus.marthy.xyz |
| registry.access.redhat.com | access-redhat-com.nexus.marthy.xyz |
| registry.redhat.io | not mirrored yet: needs a Red Hat registry service account added to Nexus |

## Cutover order (each step reversible)
1. Merge the Nexus change (new proxies and connectors) and check each host answers `/v2/` with a token.
2. Apply one `ImageDigestMirrorSet` and one `ImageTagMirrorSet` on metal1 (below). This causes one
   rolling MachineConfig update of the three masters.
3. Watch the pulls move: `cdn01.quay.io` traffic from sm4 should drop to cache fills only.
4. Squid: allow `192.168.11.0/24` only to the allowlist, deny the rest (`conf.d/00-metal1-restricted.conf`
   must sort before `debian.conf`, which holds `http_access allow localnet`).
5. hAP: enable the disabled `lab egress: default deny for VLAN 11` rule (Safe Mode).
6. metal1: drop telemetry and the update graph if no longer wanted.

## metal1 mirror sets
```yaml
apiVersion: config.openshift.io/v1
kind: ImageDigestMirrorSet
metadata: {name: image-digest-mirror}
spec:
  imageDigestMirrors:
  - {source: quay.io, mirrors: [quay-io.nexus.marthy.xyz]}
  - {source: docker.io, mirrors: [docker-io.nexus.marthy.xyz]}
  - {source: ghcr.io, mirrors: [ghcr-io.nexus.marthy.xyz]}
  - {source: mirror.gcr.io, mirrors: [mirror-gcr-io.nexus.marthy.xyz]}
  - {source: registry.access.redhat.com, mirrors: [access-redhat-com.nexus.marthy.xyz]}
---
apiVersion: config.openshift.io/v1
kind: ImageTagMirrorSet
metadata: {name: image-tag-mirror}
spec:
  imageTagMirrors:
  - {source: quay.io, mirrors: [quay-io.nexus.marthy.xyz]}
  - {source: docker.io, mirrors: [docker-io.nexus.marthy.xyz]}
  - {source: ghcr.io, mirrors: [ghcr-io.nexus.marthy.xyz]}
  - {source: mirror.gcr.io, mirrors: [mirror-gcr-io.nexus.marthy.xyz]}
  - {source: registry.access.redhat.com, mirrors: [access-redhat-com.nexus.marthy.xyz]}
```
`mirrorSourcePolicy` stays at the default (`AllowContactingSource`) until Squid blocks the
registries, so a mirror outage does not stop pulls during the transition.

## Squid (sm4) `/etc/squid/conf.d/00-metal1-restricted.conf`
```
acl metal1_nodes src 192.168.11.0/24
acl metal1_allowed dstdomain acme-v02.api.letsencrypt.org login.microsoftonline.com
http_access allow metal1_nodes metal1_allowed
http_access deny metal1_nodes
```
Add `registry.redhat.io` and its content hosts here until its credentials are in Nexus.
