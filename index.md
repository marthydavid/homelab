# homelab
This is the repo for my homelab

# Lab

## Network

| Type | Functions | Usage |
|----|----|----|
| Mikrotik [hAP AX^3](https://mikrotik.com/product/hap_ax3) | Router, BGP, VLAN | Main router for BP |
| Mikrotik [hAP AC^2](https://mikrotik.com/product/hap_ac2) | Router, BGP, VLAN | Main router for Family |
| Mikrotik [cAP AC](https://mikrotik.com/product/cap_ac) | Wifi CAP | AP |
| Mikrotik [CRS354-48G-4S+2Q+RM](https://mikrotik.com/product/crs354_48g_4splus2qplusrm) | VLAN, LACP, Routing | Main switch for servers, routing for homelab |
| TP-Link [T1600G-28TS](https://www.tp-link.com/business-networking/smart-switch/t1600g-28ts) | Spare| Spare|

## Compute

### In use

| Name | Motherboard | CPU | Memory | Boot | Disk | NIC |
|----|----|----|----|----|----|----|
| SM1 | [X11SCL-F](https://www.supermicro.com/en/products/motherboard/X11SCL-F) | Core [i5-9400](https://ark.intel.com/content/www/us/en/ark/products/134898/intel-core-i59400-processor-9m-cache-up-to-4-10-ghz.html)  | 128GB  | 120GB SataDOM | 500GB NVMe 2x1TB SSD | 1IPMI, 2x1Gig, 2x100Gig |
| SM2 | [X11SCL-F](https://www.supermicro.com/en/products/motherboard/X11SCL-F) | Core [i5-9400F](https://ark.intel.com/content/www/us/en/ark/products/190883/intel-core-i59400f-processor-9m-cache-up-to-4-10-ghz.html) | 128GB | 120GB SataDOM | 500GB NVMe 2x1TB SSD | 1IPMI, 2x1Gig, 2x100Gig |
| SM3 | [X11SCL-IF](https://www.supermicro.com/en/products/motherboard/X11SCL-IF) | Core [i3-8100T](https://ark.intel.com/content/www/us/en/ark/products/129944/intel-core-i38100t-processor-6m-cache-3-10-ghz.html)     | 64GB | 120GB SataDOM | 500GB NVMe 2x1TB SSD | 1IPMI, 2x1Gig, 2x100Gig |
| SM4 | [X10SDV-6C+-TLN4F](https://www.supermicro.com/en/products/motherboard/X10SDV-6C+-TLN4F) | Xeon [D-1528](https://ark.intel.com/content/www/us/en/ark/products/91198/intel-xeon-processor-d1528-9m-cache-1-90-ghz.html) | 128GB | 256GB Sata SSD | 500GB NVMe + 1TB SSD ZFS + 4X4TB HDD ZFS RaidZ1 | 1IPMI, 2x1Gig, 2x10Gig |
| NUC01 | [NUC11PAHi5](https://www.intel.com/content/www/us/en/products/sku/205040/intel-nuc-11-performance-kit-nuc11pahi5/specifications.html) | Core [i5-1135G7](https://www.intel.com/content/www/us/en/products/sku/208658/intel-core-i51135g7-processor-8m-cache-up-to-4-20-ghz/specifications.html) | 64GB | 1TB SSD | 1TB NVMe | 1x2.5Gig |

### Spare

| Name | Motherboard | CPU | Memory | Boot | Disk | NIC |
|----|----|----|----|----|----|----|
| Spare | [X11SCL-F](https://www.supermicro.com/en/products/motherboard/X11SCL-F) | | | | | |
| HP  | [Z2G4](https://support.hp.com/us-en/product/hp-z2-tower-g4-workstation/20063240/document/c06100744) | Core [G5400](https://ark.intel.com/content/www/us/en/ark/products/129951/intel-pentium-gold-g5400-processor-4m-cache-3-70-ghz.html) | 32GB | 250GB SSD     |                                | 1x1Gig |
| HP  | [Z2G4](https://support.hp.com/us-en/product/hp-z2-tower-g4-workstation/20063240/document/c06100744) | Core [G5400](https://ark.intel.com/content/www/us/en/ark/products/129951/intel-pentium-gold-g5400-processor-4m-cache-3-70-ghz.html) | 32GB | 250GB SSD     |                                | 1x1Gig |
| RPi 1 |  RPi 4b 8GB  | 4core ARMv8 | 8GB | 500GB SSD | -     | 1Gig |
| RPi 2 |  RPi 4b 8GB  | 4core ARMv8 | 8GB | 500GB SSD | -     | 1Gig |
| RPi 3 |  RPi 4b 4GB  | 4core ARMv8 | 4GB | 500GB SSD | -     | 1Gig |
| RPi 4 |  RPi 4b 4GB  | 4core ARMv8 | 4GB | 500GB SSD | -     | 1Gig |
| RPi 5 |  RPi 3b+ 1GB | 4core ARMv8 | 1GB | 16GB SD   | 320GB | 1Gig |


## Not in use

### Network

| Type | Functions | Usage |
|----|----|----|
| Mikrotik [hAP AC^3](https://mikrotik.com/product/hap_ac3) | Router, BGP, VLAN | - |
| Mikrotik [hAP AC^2](https://mikrotik.com/product/hap_ac2) | Router, BGP, VLAN | - |
| TP-Link [SG-108PE](https://www.tp-link.com/hu/business-networking/easy-smart-switch/tl-sg108pe/) | PoE for RPis | Switch for RPis |
| TP-Link [SG-108E](https://www.tp-link.com/hu/business-networking/easy-smart-switch/tl-sg108pe/) | - | - |

## UPS

### Main

| Type | Capacity | Usage |
|---|---|---|
| CyberPower [OR1500ERM1U](https://www.cyberpower.com/eu/en/product/sku/or1500erm1u) | 1500VA / 900W | Main |
| Eaton [5E650iUSBDIN](http://powerquality.eaton.com/5E650iUSBDIN.aspx?cx=58) | 650VA / 360W | NUC | 

## Software

### Hypervisors:

| Name | OS | Function |
|---|---|---|
| SM1 | ESXi 8.0.3 | VM Host |
| SM2 | ESXi 8.0.3 | VM Host |
| SM3 | ESXi 8.0.3 | VM Host |
| SM4 | Ubuntu 22.04 | NAS - K8s/VM Host |
| SM4-VM | ESXi 8.0.3 | VCSA Host |
| NUC01 | ESXi 8.0.3 | VM Host |

### NAS

| Name | OS |
|---|---|
| SM4 | Ubuntu 22.04 |


### OCI K8s Cluster

* [rancher](https://rancher.com)
* [cert-manager](https://cert-manager.io)
* [ingress-nginx](https://kubernetes.github.io/ingress-nginx)
* [fleet](https://fleet.rancher.io/)
* [vault](https://vaultproject.io)
* [external-secrets](https://external-secrets.io)



### Main K8s cluster

* [cert-manager](https://cert-manager.io)
* [ingress-nginx](https://kubernetes.github.io/ingress-nginx)
* [oauth2-proxy](https://oauth2-proxy.github.io/oauth2-proxy/)
* [ddns-route53](https://crazymax.dev/ddns-route53/)
* [prometheus-operator](https://prometheus-operator.dev/)
* [karma](https://karma-dashboard.io/)
* [metallb](https://metallb.universe.tf/)
* [babybuddy](https://docs.baby-buddy.net/)
* [kyverno](https://kyverno.io/)
* [external-dns](https://github.com/kubernetes-sigs/external-dns)
* [argo-cd](https://argo-cd.readthedocs.io/en/stable/)
* [nvidia-device-plugin](https://github.com/NVIDIA/k8s-device-plugin)
* [Servarr stack](https://wiki.servarr.com/)
* [Plex](https://plex.tv)
* [supermicro-letsencrypt](https://github.com/marthydavid/supermicro-letsencrypt)


### Decomissoned

| Name | Motherboard | CPU | Memory | Boot | Disk | NIC |
|----|----|----|----|----|----|----|
| - | [X10SLM+-LN4F](https://www.supermicro.com/en/products/motherboard/X10SLM+-LN4F)                     | Xeon [E3-1230v3](https://ark.intel.com/content/www/us/en/ark/products/75054/intel-xeon-processor-e3-1230-v3-8m-cache-3-30-ghz.html)  | 32GB | | | 1IPMI, 4x1Gig |
| - | [X10SLM+-LN4F](https://www.supermicro.com/en/products/motherboard/X10SLM+-LN4F)                     | Xeon [E3-1231v3](https://ark.intel.com/content/www/us/en/ark/products/80910/intel-xeon-processor-e31231-v3-8m-cache-3-40-ghz.html)   | 32GB | | | 1IPMI, 4x1Gig |
| - | Gigabyte                                                                                         | Core [i5-4750](https://ark.intel.com/content/www/us/en/ark/products/75043/intel-core-i5-4570-processor-6m-cache-up-to-3-60-ghz.html) | 32GB | | | 2x1Gig |
