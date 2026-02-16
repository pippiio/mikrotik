# <module>

The _<module>_ is a generic [Terraform](https://www.terraform.io/) module within the [pippi.io](https://pippi.io) family, maintained by [Tech Chapter](https://techchapter.com/). The pippi.io modules are build to support common use cases often seen at Tech Chapters clients. They are created with best practices in mind and battle tested at scale. All modules are free and open-source under the Mozilla Public License Version 2.0.

The mikrotik module is made to provision and manage a [MikroTik ethernet router](https://mikrotik.com/products/group/ethernet-routers) to support an internal Kubernetes cluster.

### Example usage
```hcl
module "example" {
  source = "../../"

  router_insecure_first_run    = var.router_insecure_first_run
  openvpn_admin_account_secret = var.openvpn_admin_account_secret
  router_admin_password        = var.router_admin_password
  routing = {
    router_name                = "example"
    router_domain              = "techchapter.com"
    router_country             = "DK"
    router_organization        = "Tech Chapter ApS"
    router_ca_certificate_file = "certificates/ca.pem"
    cloud_name                 = "example"
    interface_used_as_wan      = "ether1"
    interfaces_used_by_cluster = [
      "ether2",
      "ether3",
      "ether4"
    ]
  }

  wireguard = {
    peer = {
      "techops" = {
        ip_address = "10.3.254.20"
        public_key = "564VzAawdhktPb6eoUbgCqwl8AKTBwqcLhQKSzBGnxs="
      }
    }
  }
}

```


### Target configuration

In the above example the router will be setup to NAT connections from port 2, 3 and 4 to port 1.
Port 1 will be the WAN port. On the WAN port only WireGuard traffic will be allowed. This means that WireGuard is required to manage the router.

The Kubernetes nodes will run on ports 2, 3 and 4. They will have IPs in the range 10.25.0.10 - 10.25.0.1 and use 10.25.0.1 as gateway.
An admin IP range 192.168.88.0/24 will be configured with access from WireGuard. The router will accept connections on IP 192.168.88.1 but will also accept connections on 10.25.0.1 . 

BGP ( Border Gateway Protocol ) will be activated on the Kubernetes ports.

### First run

When you start a new and unconfigured MikroTik router it will not yet have any password or any IPs configured.

You can create a new secure password and have it stored to `terraform.tfvars` like this:

```bash
# Warning this will overwrite your password if you run it twice
echo "router_admin_password = \"$(openssl rand -base64 32)\"" > terraform.tfvars
cat terraform.tfvars
```

It is useful to use DHCP to give the router an IP when you set it up the first time. Configure the WAN port to get an IP from dhcp like this:

```
/interface list member
add interface=ether1 list=WAN
/ip dhcp-client
add disabled=no interface=ether1
print # This will show you the new IP of the router
```

Then create a file called `providers.tf` with the following content:

```hcl
provider "routeros" {
  hosturl        = "http://192.168.122.158"
  username       = var.router_admin_username
  password       = var.router_admin_password
  insecure = true
}
```

Replace 192.168.122.158 in the above example with the IP from the router.

To prevent Terraform from locking it self out you can use the router_insecure_first_run variable like this:

```bash
TF_VAR_router_insecure_first_run=true terraform apply
```

This will set up everything except it will still allow you to manage the router without encryption and will not drop connections from the WAN port.

After the first run, you can download the server CA certificate from the router and start using it though a secure connection.

### Go secure

First set up WireGuard and update the `main.tf` file with your WireGuard public key and rerun Terraform apply. I use the following WireGuard file:

```
[Interface]
ListenPort = 51820
PrivateKey = ThisIsMyPrivateKey
Address = 10.3.254.20/32
DNS = 1.1.1.1
PostUp = ip route add 192.168.88.0/24 dev denlille
PostUp = ip route add    10.25.0.0/24 dev denlille
Table = off

[Peer]
PublicKey = dCw9QfDZeMrrVlmKwNlGbj24W+IVsFmvrs18WbyneHw=
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = 192.168.122.158:51820
```

Update the public key of the router and your private keys. And the WAN point next to Endpoint.

When connected though WireGuard the IP of the router will be `192.168.88.1`

Now store the routers CA certificate in a file:

```bash
mkdir -p certificate
echo | openssl s_client -connect 192.168.88.1:443 | openssl x509 > certificate/ca.pem
```

Update providers.tf so that Terraform will use HTTPS when connecting to the router. And to establish the connection though the WireGuard VPN.

```hcl
provider "routeros" {
  hosturl        = "https://${var.router_admin_ip}"
  username       = var.router_admin_username
  password       = var.router_admin_password
  ca_certificate = var.router_ca_certificate_file
}
```

### Disable dhcp on WAN interface

Then you are done configuring the router you can set a fixed IP:

```
/ip address
add address=10.3.8.90/30 interface=ether13 network=10.3.8.88
/ip dhcp-client
add disabled=yes interface=ether1
```
