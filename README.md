# MikroTik Terraform module

## Example Configs

### Example Config for Router connected together with switch

This example uses the MikroTik module to configure a router with a static WAN connection, local management VLAN, switch trunk, kube VLAN, and WireGuard access.

The WAN is connected on sfp-sfpplus4 with a static public IP and gateway. Local devices are placed on the management VLAN across the Ethernet ports. Two SFP+ ports connect to a downstream switch trunk, which provides access to the kube VLAN. WireGuard creates a remote-access network and allows VPN clients to reach WAN, management, and kube networks.

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
}
```

### Example Config for two Routers connected via site-to-site VPN

This example configures two MikroTik routers in separate locations, each managing their own local networks, connected to each other over a site-to-site WireGuard VPN.

Both routers are managed from the same Terraform root. Each module instance outputs its `site_public_key`, which is cross-wired into the other's `remote_public_key`. Terraform resolves the dependency automatically across module outputs.

Site A is a router with a WAN connection and a management VLAN. Site B is a router with a WAN connection and a kube VLAN. The `sites` block on each router allows its local networks to reach the other site through a shared `wg-sites` tunnel. Both sites also run independent WireGuard access for remote users.

```terraform
module "site_a" {
  source = "git@github.com:pippiio/mikrotik"

  admin_ip = "192.168.89.1"

  wan = {
    interface = "sfp-sfpplus4"
    address   = "1.2.3.4/29"
    gateway   = "1.2.3.3"
    speed     = "1G-baseX"
  }

  vlans = {
    management = {
      id   = 10
      cidr = "10.10.8.0/24"
      interfaces = [
        "ether1",
        "ether2",
      ]
      allow_connections_to = ["wan"]
    }
  }

  sites = {
    cidr                 = "172.31.0.0/24"
    allow_connections_to = ["management"]
    peers = {
      site_b = {
        endpoint          = "2.3.4.5"
        address           = "172.31.0.2"
        remote_cidrs      = ["10.20.8.0/24"]
        remote_public_key = "<Public Key from Site B>"
      }
    }
  }
}

output "site_a_wireguard_public_key" {
  value     = module.site_a.site_public_key
  sensitive = true
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
/ip address add address=192.168.89.1/24 interface=ether13
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
