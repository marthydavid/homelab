# homelab
This is the repo for my homelab

# Lab

## Network

### Main
Type | Functions
----|----
Mikrotik [hAP AC^3](https://mikrotik.com/product/hap_ac3) | Router, BGP, VLAN
Mikrotik [hAP AC^2](https://mikrotik.com/product/hap_ac2) | Router, BGP, VLAN
TP-Link [T1600G-28TS](https://www.tp-link.com/business-networking/smart-switch/t1600g-28ts) | VLAN, LACP
TP-Link [SG-108PE](https://www.tp-link.com/hu/business-networking/easy-smart-switch/tl-sg108pe/) | PoE for RPis

### Remote
Type | Functions
----|----
Mikrotik [hAP AC^2](https://mikrotik.com/product/hap_ac2) | Router, BGP, VLAN
Mikrotik [cAP AC](https://mikrotik.com/product/cap_ac) | Wifi CAP

## Compute

### Main
Name | Motherboard | CPU | Memory | Boot | Disk | NIC
----|----|----|----|----|----|----
SM1 | [X10SLM+-LN4F](https://www.supermicro.com/en/products/motherboard/X10SLM+-LN4F)                    | Xeon [E3-1230v3](https://ark.intel.com/content/www/us/en/ark/products/75054/intel-xeon-processor-e3-1230-v3-8m-cache-3-30-ghz.html)  | 32GB | 120GB SataDOM | 250GB SSD 320GB HDD | 1IPMI, 4x1Gig
SM2 | [X10SLM+-LN4F](https://www.supermicro.com/en/products/motherboard/X10SLM+-LN4F)                    | Xeon [E3-1265Lv3](https://ark.intel.com/content/www/us/en/ark/products/75463/intel-xeon-processor-e31265l-v3-8m-cache-2-50-ghz.html) | 32GB | 120GB SataDOM | 250GB SSD 320GB HDD | 1IPMI, 4x1Gig
SM3 | [X10SLM+-LN4F](https://www.supermicro.com/en/products/motherboard/X10SLM+-LN4F)                    | Xeon [E3-1231v3](https://ark.intel.com/content/www/us/en/ark/products/80910/intel-xeon-processor-e31231-v3-8m-cache-3-40-ghz.html)   | 32GB | 120GB SataDOM | 250GB SSD 320GB HDD | 1IPMI, 4x1Gig
SM4 | [X11SCL-IF](https://www.supermicro.com/en/products/motherboard/X11SCL-IF)                          | Core [i3-8100T](https://ark.intel.com/content/www/us/en/ark/products/129944/intel-core-i38100t-processor-6m-cache-3-10-ghz.html)     | 64GB | 120GB SataDOM | 500GB NVMe 1TB SSD 1TB HDD  | 1IPMI, 2x1Gig
SM5 | [X10SDV-6C+-TLN4F](https://www.supermicro.com/en/products/motherboard/X10SDV-6C+-TLN4F)            | Xeon [D-1528](https://ark.intel.com/content/www/us/en/ark/products/91198/intel-xeon-processor-d1528-9m-cache-1-90-ghz.html)          | 64GB | 500GB NVMe| 4x1TB SSD ZFS Mirror+Stripe 2X2TB HDD ZFS Mirror| 1IPMI, 2x1Gig, 2x10Gig
HP | [Z2G4](https://support.hp.com/us-en/product/hp-z2-tower-g4-workstation/20063240/document/c06100744) | Core [i5-9400](https://ark.intel.com/content/www/us/en/ark/products/134898/intel-core-i59400-processor-9m-cache-up-to-4-10-ghz.html) | 96GB | 250GB SSD | 500GB NVMe 1TB SSD | 3x1Gig
RPi 1|  RPi 4b 8GB  | 4core ARMv8 | 8GB | 500GB SSD | -     | 1Gig
RPi 2|  RPi 4b 8GB  | 4core ARMv8 | 8GB | 500GB SSD | -     | 1Gig
RPi 3|  RPi 4b 4GB  | 4core ARMv8 | 4GB | 500GB SSD | -     | 1Gig
RPi 4|  RPi 4b 4GB  | 4core ARMv8 | 4GB | 500GB SSD | -     | 1Gig
RPi 5|  RPi 3b+ 1GB | 4core ARMv8 | 1GB | 16GB SD   | 320GB | 1Gig

### Remote
Name | Motherboard | CPU | Memory | Boot | Disk | NIC
----|----|----|----|----|----|----
Remote | Gigabyte                                                                                        | Core [i5-4750](https://ark.intel.com/content/www/us/en/ark/products/75043/intel-core-i5-4570-processor-6m-cache-up-to-3-60-ghz.html) | 32GB | 250GB SSD | 4x4TB HDD ZFS RAIDZ1 | 2x1Gig


## UPS

### Main
Type | Capacity
---|---
CyberPower [OR1500ERM1U](https://www.cyberpower.com/eu/en/product/sku/or1500erm1u) | 1500VA / 900W

### Remote
Type | Capacity
---|---
Eaton [5E650iUSBDIN](http://powerquality.eaton.com/5E650iUSBDIN.aspx?cx=58) | 650VA / 360W

## Software

### Hypervisors:
Name | OS | Function
---|---|---
HP | ESXi 7 | Main VM Host
SM1 |  ESXi 7 | VM Host(Sometimes vSAN cluster)
SM2 |  ESXi 7 | VM Host(Sometimes vSAN cluster)
SM3 |  ESXi 7 | VM Host(Sometimes vSAN cluster)
SM4 |  ESXi 7 | VM Host

### K3s cluster
Name | OS | Function
---|---|---
RPi 1 | Ubuntu 21.10 | K3s worker
RPi 2 | Ubuntu 21.10 | K3s worker
RPi 3 | Ubuntu 21.10 | K3s worker
RPi 4 | Ubuntu 21.10 | K3s ctrl plane

### NAS
Name | OS
---|---
SM5 | TrueNAS Scale

### Off-site
Name | OS | Function
---|---|---
Remote | Ubuntu 20.04 | K3s cluster + Rancher



### Main K8s cluster
* rancher
* cert-manager
* ingress-nginx
* oauth2-proxy
* ddns-route53
* Radarr
* Sonarr
* prometheus-operator
* karma
* metallb
* fleet
* kube-vip