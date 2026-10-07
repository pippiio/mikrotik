# MikroTik Terraform module

## Variables

| Variable | Purpose |
| --- | --- |
| `admin_ip` | IP of the admin port created by hand during first setup. |
| `wan` | Physical WAN uplink: interface, static address, gateway, speed. |
| `vlans` | Local VLANs: subnet, interfaces, and which other networks they can reach. |
| `trunks` | Trunk link to another MikroTik device, with the VLANs reachable across it. |
| `wireguard` | WireGuard VPN: a local tunnel, or `external = true` to treat it as a network provided upstream. |
| `bgp` | BGP peering to learn routes, with per-prefix filtering and optional WAN/VPN exposure. Each peer is either a `vlan` (a dynamic group of neighbors, e.g. any Kubernetes node in a subnet) or a `trunk` (a single known neighbor on a direct link, e.g. an upstream router), never both. |
| `exposed_services` | Expose services to WAN and VPN through static routes and firewall rules. This allows exposing services that don't support BGP. |

## Example Configs

The two examples below show a complete chain: Kubernetes nodes advertise LoadBalancer IPs over BGP to the switch (`bgp` with a `vlan` peer), the switch re-advertises those same routes to the router over their trunk (`bgp` with a `trunk` peer on both ends — this is plain BGP route propagation, nothing module-specific), and the router allows WAN/VPN traffic in to them (`expose` on that same peer). BGP only carries routes, not ports, so `expose`'s ports/protocol still have to be declared explicitly and kept in sync with reality — the addresses are the only part that's actually dynamic. If a device doesn't speak BGP at all, `exposed_services` covers the same WAN/VPN exposure for a manually-maintained address list instead.

### Example Config for Router connected together with switch

This example uses the MikroTik module to configure a router with a static WAN connection, local management VLAN, switch trunk, kube VLAN, and WireGuard access.

The WAN is connected on sfp-sfpplus4 with a static public IP and gateway. Local devices are placed on the management VLAN across the Ethernet ports. Two SFP+ ports connect to a downstream switch trunk, which provides access to the kube VLAN. WireGuard creates a remote-access network and allows VPN clients to reach WAN, management, and kube networks.

`bgp` peers with the switch over their trunk (AS 65010 here, vs. the switch's AS 65000) to learn routes for a Kubernetes LoadBalancer pool, rather than relying on a static route. `trunk = "switch"` makes this a direct, point-to-point session: both sides dial out *and* listen, so whichever side applies first still succeeds in establishing the connection. `accept_prefixes` mirrors the switch's own filter, so the router only accepts `/32` routes within the known pool even if the switch ever sent more. `expose` then allows that pool in from WAN and WireGuard on ports 80/443 — this only works if the switch is actually learning and re-advertising routes for that same pool, which is the `bgp` block in the switch example below.

```terraform
module "mikrotik" {
  source = "git@github.com:pippiio/mikrotik"

  admin_ip = "192.168.89.1"

  wan = {
    interface = "sfp-sfpplus4"
    address   = "1.2.3.4/29" # Typically provided from your hosting provider
    gateway   = "1.2.3.3"    # Typically provided from your hosting provider
    speed     = "1G-baseX"
  }

  trunks = {
    switch = {
      id          = 99
      src_address = "172.16.99.1"
      dst_address = "172.16.99.2"
      interfaces = [
        "sfp-sfpplus1",
        "sfp-sfpplus2"
      ]
      dst_vlans = {
        "kube" = {
          id   = 20
          cidr = "10.20.8.0/24"
        }
      }
    }
  }

  vlans = {
    management = {
      id   = 10
      cidr = "10.10.8.0/24"
      interfaces = [
        "ether1",
        "ether2",
        "ether3",
        "ether4",
        "ether5",
        "ether6",
        "ether7",
        "ether8",
        "ether9",
        "ether10",
        "ether11",
        "ether12",
      ]
      allow_connections_to = [
        "wan",
        "switch/kube",
      ]
    }
  }

  wireguard = {
    cidr     = "10.30.8.0/24"
    endpoint = "1.2.3.4"

    peers = {
      user = {
        address = "10.30.8.2/32"
      }
    }

    allow_connections_to = [
      "wan",
      "management",
      "switch/kube",
    ]
  }

  bgp = {
    as        = 65010
    router_id = "172.16.99.1" # this device's side of the trunk
    peers = {
      "switch-downlink" = {
        trunk           = "switch"
        remote_as       = 65000
        accept_prefixes = ["1.2.3.0/29"]
        expose = {
          address_range = "1.2.3.5-1.2.3.6"
          ports         = [80, 443]
        }
      }
    }
  }
}

output "wireguard_client_configs" {
  value     = module.mikrotik.wireguard_client_configs
  sensitive = true
}
```

### Example Config for Switch connected together with router

This example configures a MikroTik device connected upstream to another router over a trunk. The trunk uses combo1 and combo2, with VLAN ID 99 for the router link and wan = true to mark the upstream path as the WAN route.

The upstream router provides the management and wireguard VLANs across the trunk. This device exposes the local kube VLAN on ether1 through ether8, using subnet 10.20.8.0/24. The kube network is allowed to reach the upstream WAN, while management and WireGuard traffic from the upstream router are allowed to reach kube.

WireGuard is marked as external, meaning this device does not terminate the VPN itself. It treats WireGuard as a network provided by the upstream router.

`bgp` has two peers here. `k8s-nodes` peers with any node in the kube VLAN as AS 65020 — a `vlan` peer, so it only listens passively (`listen = true`, `connect = false`) rather than dialing out, since there's no single address to dial against an entire dynamic subnet. `accept_prefixes` is a safety filter: only `/32` routes within `1.2.3.0/29` are accepted via BGP, everything else is rejected, so a misbehaving peer can't inject arbitrary routes. `expose` then allows that same pool in from the upstream trunk (treated as the WAN side here, since `wan = true` on this trunk) on ports 80/443.

`router-uplink` is a `trunk` peer instead — a single known neighbor (the router, AS 65010) on the other end of the trunk — so it both listens and dials out. It has no `accept_prefixes` or `expose`: this device doesn't need to accept routes *from* the router, it only needs to re-advertise the k8s-nodes pool upstream, which plain BGP does automatically for any route it already holds. That re-advertised route, filtered and exposed on the router's side, is the `bgp` block in the router example above.

```terraform
module "mikrotik" {
  source = "../module"

  admin_ip = "192.168.88.1"

  trunks = {
    router = {
      id          = 99
      src_address = "172.16.99.2"
      dst_address = "172.16.99.1"
      wan         = true
      interfaces = [
        "combo1",
        "combo2"
      ]
      dst_vlans = {
        "management" = {
          id   = 10
          cidr = "10.10.8.0/24"
        }
        "wireguard" = {
          id   = 30
          cidr = "10.30.8.0/24"
        }
      }
    }
  }

  wireguard = {
    endpoint = null
    cidr     = "10.30.8.0/24"
    external = true
  }

  vlans = {
    kube = {
      id   = 20
      cidr = "10.20.8.0/24"
      interfaces = [
        "ether1",
        "ether2",
        "ether3",
        "ether4",
        "ether5",
        "ether6",
        "ether7",
        "ether8",
      ]
      allow_connections_to = [
        "router/wan"
      ]
      allow_connections_from = [
        "router/wireguard",
        "router/management"
      ]
    }
  }

  bgp = {
    as        = 65000
    router_id = "10.20.8.1"
    peers = {
      "k8s-nodes" = {
        vlan            = "kube"
        remote_as       = 65020
        accept_prefixes = ["1.2.3.0/29"]
        expose = {
          address_range = "1.2.3.5-1.2.3.6"
          ports         = [80, 443]
        }
      }
      "router-uplink" = {
        trunk     = "router"
        remote_as = 65010
      }
    }
  }
}
```

## First Setup on new RouterOS machine

### 1. Prepare the local network interface

Use a static IP on the ETH/Boot adapter.

```bash
sudo nmcli device set enp0s20f0u2 managed no
sudo ip addr add 192.168.89.2/24 dev enp0s20f0u2
sudo ip link set enp0s20f0u2 up
```

Your computer should now use:

```text
192.168.89.2/24
```

The MikroTik router will later use:

```text
192.168.89.1/24
```

### 2. Reset the MikroTik router

1. Connect your computer to the MikroTik **ETH/Boot** port.
2. Power off the MikroTik router.
3. Hold the **Reset** button.
4. Power on the router while still holding **Reset**.
5. Release the button when the LED starts flashing.
6. Wait for the router to reboot.

### 3. Connect with WinBox using MAC address

Open **WinBox** and go to the **Neighbors** tab.

Connect to the MikroTik router using its **MAC address**, not an IP address.

When asked whether to remove the default configuration, choose:

```text
Yes
```

### 4. Set the admin IP on the ETH/Boot port

After connecting, open a terminal in WinBox.

Find the ETH/Boot interface name:

```routeros
/interface print
```

Set an admin IP address like `192.168.88.1` on the ETH/Boot interface.

Example using `ether13`:

```routeros
/ip address add address=192.168.89.1/24 interface=ether1
```

Verify the IP address:

```routeros
/ip address print
```

Test connectivity from your computer:

```bash
ping 192.168.89.1
```

### 5. Configure Terraform

Set the MikroTik admin IP as the Terraform variable `admin_ip`.

Example `terraform.tfvars`:

```hcl
admin_ip = "192.168.89.1"
```

Use the same variable in the RouterOS provider `hosturl`.

Example provider configuration:

```hcl
variable "admin_ip" {
  type = string
}

module "mikrotik" {
  source = "git@github.com:pippiio/mikrotik"

  admin_ip = var.admin_ip

  ...
}

provider "routeros" {
  hosturl  = "http://${var.admin_ip}"
  username = var.routeros_username
  password = var.routeros_password
}
```

### 6. Run Terraform

From the Terraform project directory:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

Confirm the apply when prompted:

```text
yes
```

### Checklist

```text
1. Disable NetworkManager management for enp0s20f0u2
2. Assign 192.168.89.2/24 to enp0s20f0u2
3. Bring enp0s20f0u2 up
4. Reset the MikroTik router
5. Connect with WinBox using MAC address on ETH/Boot port
6. Remove default configuration when asked
7. Set MikroTik admin IP on ETH/Boot port to 192.168.89.1/24
8. Set Terraform admin_ip = "192.168.89.1"
9. Set RouterOS provider hosturl using var.admin_ip
10. Run terraform init, validate, plan, and apply
```
