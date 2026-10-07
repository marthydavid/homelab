# cloudflared (Cloudflare Tunnel)

Exposes ingress-nginx to the internet without an open port or DDNS.

## One-time setup (Cloudflare dashboard / Vault)
1. Add `marthy.xyz` to Cloudflare and switch the registrar's nameservers (import the Route53 records first).
2. Zero Trust -> Networks -> Tunnels -> create a `cloudflared` tunnel; copy its token into Vault `secret/cloudflare` as `tunnel_token`.
3. Create an API token (Zone:Zone:Read, Zone:DNS:Edit on marthy.xyz) -> Vault `secret/cloudflare` as `api_token`.
4. Tunnel public hostnames: `*.marthy.xyz` and each host below -> `https://ingress-nginx-controller.ingress-nginx.svc.cluster.local:443`, with "No TLS Verify" on (or set the Origin Server Name per host).
5. DNS: `pecs.marthy.xyz` CNAME `<tunnel-id>.cfargotunnel.com`, proxied. Public ingresses keep `external-dns.alpha.kubernetes.io/target: pecs.marthy.xyz` and now carry `cloudflare-proxied: "true"` instead of the Route53-only `alias`.

## Caveats
* Universal SSL only covers `*.marthy.xyz`. Hosts like `baby.pecs.marthy.xyz` need Advanced Certificate Manager (paid) or must move to a single label.
* Cloudflare's proxy caps request bodies at 100 MB (free/pro): Nexus docker pushes of large layers will fail through the tunnel. Keep those on the LAN or DNS-only.
* Private ingresses (no `target` annotation) stay unproxied A records to 192.168.20.1.

## Cutover cleanup (after verifying)
Delete `fleet/global-apps/ddns-route53`, `external-dns-secrets/aws-cred.yaml` + overlays, `cert-manager-config/clusterissuersecret.yaml` + overlays, and the README entry.
