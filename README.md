<!-- BEGIN_TF_DOCS -->
# MikroTik module

The is a generic Terraform module within the pippi.io family, maintained by
Tech Chapter. The pippi.io modules are build to support common use cases
often seen at Tech Chapters clients. They are created with best practices in
mind and battle tested at scale. All modules are free and open-source under
the Mozilla Public License Version 2.0.

The mikrotik module is made to provision and manage a MikroTik ethernet
router to support an internal Kubernetes cluster.

## Example usage

Setting up router:

```hcl
module "mikrotik" {
  source = "../../"

  device_insecure_first_run = var.device_insecure_first_run

  cloud_settings = {
    device_name                     = "kvmexample"
    device_ip                       = "192.168.88.1"
    interface_used_as_admin         = "kvmexample"
    cluster_name                    = "kvmexample"
    certificate_domain              = "techchapter.com"
    certificate_country             = "DK"
    certificate_organization        = "Tech Chapter ApS"
    certificate_ca_certificate_file = "certificates/ca.pem"
    interfaces_used_by_cluster = [
      "bond1",
      "ether4"
    ]
  }

  switching = {
    interface_used_as_admin = "ether1"
    interface_bonds = {
      "bond1" = {
        interfaces = ["ether2", "ether3"]
      }
    }
  }

  routing = {
    interface_used_as_wan = "ether1"
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
````

Setting up a switch behind that router:

```hcl
module "mikrotik" {
  source = "../../"

  device_insecure_first_run = var.device_insecure_first_run

  cloud_settings = {
    device_name                     = "kvm-sw"
    device_ip                       = "192.168.88.2"
    interface_used_as_admin         = "ether13"
    cluster_name                    = "kvm"
    certificate_domain              = "techchapter.com"
    certificate_country             = "DK"
    certificate_organization        = "Tech Chapter ApS"
    certificate_ca_certificate_file = "certificates/ca.pem"
    interfaces_used_by_cluster = [
      "ether1",
      "ether2",
      "ether3",
      "ether4",
      "ether5",
      "ether6",
      "ether7",
      "ether8",
      "ether9",
      "bond1"
    ]
  }

  switching = {
    interface_bonds = {
      "bond1" = {
        interfaces = ["ether10", "ether11"]
      }
    }
  }

}
````

## Target configuration

In the above example, the router will be set up to NAT connections from ports 2, 3, and 4 to port 1.
Port 1 will be the WAN port. On the WAN port, only WireGuard traffic will be allowed. This means that WireGuard is required to manage the router.

The Kubernetes nodes will run on ports 2, 3, and 4. They will have IPs in the range 10.25.0.1 – 10.25.0.10 and use 10.25.0.1 as the gateway.
An admin IP range 192.168.88.0/24 will be configured with access from WireGuard. The router will accept connections on IP 192.168.88.1 but will also accept connections on 10.25.0.1.

BGP (Border Gateway Protocol) will be activated on the Kubernetes ports.

## Inputs

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| <a name="input_cloud_settings"></a> [cloud\_settings](#input\_cloud\_settings) | This describes the configuration of a MikroTik router that is common for devices used as routers and switches<br/><br/>device\_name                     : Name (and hostname) of the MikroTik device (string)<br/>device\_ip                       : IP of device on the admin network (Default: "192.168.88.1")<br/>interface\_used\_as\_admin         : Limit administration interfaces to a port, e.g. same as cloud\_name (string)<br/>cloud\_name                      : Name of the cloud, e.g., odea-cloud (string)<br/>interfaces\_used\_by\_cluster      : The set of interfaces used by the cluster, e.g., ["ether1"] (set(string))<br/>certificate\_domain              : Domain name of the device. Will be used with device\_name when creating certificates (string)<br/>certificate\_country             : Country code to use in certificates, e.g., DK (string)<br/>certificate\_organization        : Name of organization to use in certificates (string)<br/>certificate\_ca\_certificate\_file : Filename of the CA certificate on your computer, e.g., certificates/ca.pem (string) | n/a | yes |
| <a name="input_device_insecure_first_run"></a> [device\_insecure\_first\_run](#input\_device\_insecure\_first\_run) | Set to true during first provision to prevent Terraform from locking itself out. | `false` | no |
| <a name="input_routing"></a> [routing](#input\_routing) | This describes the configuration of a MikroTik router for supporting a Kubernetes cluster.<br/><br/>router\_admin\_network     : IP of the network used for administration (Default: "192.168.88.0")<br/>router\_admin\_subnet\_size : Subnet size of the admin network (string)<br/>dns\_servers              : List of DNS servers this cluster will use (Default: ["1.1.1.1", "1.0.0.1"])<br/>node\_ip\_pool             : IP range used by nodes in the Kubernetes cluster (Default: ["10.25.0.10-10.25.0.14"])<br/>cluster\_gateway\_ip       : IP of the router in the Kubernetes network used as the gateway (Default: "10.25.0.1")<br/>cluster\_network\_address  : IP address of the internal network used by Kubernetes (Default: "10.25.0.0")<br/>cluster\_subnet\_size      : Subnet size of the internal network used by Kubernetes (Default: "24")<br/>interface\_used\_as\_wan    : The WAN interface, e.g., ether13 (string) | <pre>{<br/>  "interface_used_as_wan": "",<br/>  "this_is_a_router": false<br/>}</pre> | no |
| <a name="input_switching"></a> [switching](#input\_switching) | This section describtes configuration for a switch.<br/>The same MikroTik device can function as a router and a switch.<br/>But it can also only function as a switch.<br/><br/>interface\_bonds : Create a new interface by bonding 2 fysical interfaces. (Default: {}) | n/a | yes |
| <a name="input_wireguard"></a> [wireguard](#input\_wireguard) | This section describes the WireGuard configuration on the router.<br/><br/>gateway\_ip   : IP of the router in the VPN network (Default: "10.3.254.1")<br/>network\_ip   : Network IP of the VPN network (Default: "10.3.254.0")<br/>network\_size : Subnet size of the VPN network (Default: "24")<br/>peer         : Describes the peers to expect VPN connections from (Default: {}) | <pre>{<br/>  "peer": {},<br/>  "this_is_a_vpn": false<br/>}</pre> | no |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [routeros_interface_bonding.bond](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_bonding) | resource |
| [routeros_interface_bridge.cloud](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_bridge) | resource |
| [routeros_interface_bridge_port.cloud](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_bridge_port) | resource |
| [routeros_interface_list.lan](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_list) | resource |
| [routeros_interface_list.list](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_list) | resource |
| [routeros_interface_list_member.lan](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_list_member) | resource |
| [routeros_interface_list_member.wan](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_list_member) | resource |
| [routeros_interface_list_member.wireguard_lan](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_list_member) | resource |
| [routeros_interface_wireguard.wireguard](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_wireguard) | resource |
| [routeros_interface_wireguard_peer.wireguard_peer](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/interface_wireguard_peer) | resource |
| [routeros_ip_address.cloud_ips](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_address) | resource |
| [routeros_ip_address.lan](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_address) | resource |
| [routeros_ip_address.wireguard_ip](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_address) | resource |
| [routeros_ip_dhcp_server.dhcp](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_dhcp_server) | resource |
| [routeros_ip_dhcp_server_network.dhcp_server_network](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_dhcp_server_network) | resource |
| [routeros_ip_dns_forwarders.dns_servers](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_dns_forwarders) | resource |
| [routeros_ip_firewall_filter.drop_all_other_wan](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_firewall_filter) | resource |
| [routeros_ip_firewall_filter.rule_allow_established](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_firewall_filter) | resource |
| [routeros_ip_firewall_filter.rule_allow_wireguard](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_firewall_filter) | resource |
| [routeros_ip_firewall_filter.rule_allow_wireguard_to_k8s](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_firewall_filter) | resource |
| [routeros_ip_firewall_filter.rule_allow_wireguard_to_local](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_firewall_filter) | resource |
| [routeros_ip_firewall_filter.rule_border_gateway_protocol](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_firewall_filter) | resource |
| [routeros_ip_firewall_filter.rule_drop_invalid](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_firewall_filter) | resource |
| [routeros_ip_firewall_nat.nat](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_firewall_nat) | resource |
| [routeros_ip_pool.node_ip_pool](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_pool) | resource |
| [routeros_ip_service.disabled](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_service) | resource |
| [routeros_ip_service.enabled](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_service) | resource |
| [routeros_ip_service.tls](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/ip_service) | resource |
| [routeros_routing_bgp_connection.k8s_listener](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/routing_bgp_connection) | resource |
| [routeros_routing_bgp_instance.bgp_instance](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/routing_bgp_instance) | resource |
| [routeros_routing_bgp_template.k8s_template](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/routing_bgp_template) | resource |
| [routeros_system_certificate.tls_cert](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/system_certificate) | resource |
| [routeros_system_identity.id](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/resources/system_identity) | resource |
| [routeros_ip_firewall.fw](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/data-sources/ip_firewall) | data source |
| [routeros_system_resource.system](https://registry.terraform.io/providers/terraform-routeros/routeros/1.99/docs/data-sources/system_resource) | data source |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_version"></a> [version](#output\_version) | Shows the version of the MikroTik router |

## First run

When you start a new and unconfigured MikroTik router it will not yet have any password or any IPs configured.

You can create a new secure password and have it stored to `terraform.tfvars` like this:

```bash
# Warning this will overwrite your password if you run it twice
echo "device_admin_password = \"$(openssl rand -base64 32)\"" > terraform.tfvars
cat terraform.tfvars
```

It is useful to use DHCP to give the router an IP when you set it up for the first time. Configure the WAN port to get an IP from DHCP like this:

```
/ip dhcp-client
add interface=ether1
print # This will show you the new IP of the router
```

Then create a file called `providers.tf` with the following content:

```hcl
provider "routeros" {
  hosturl        = "http://192.168.122.158"
  username       = var.device_admin_username
  password       = var.device_admin_password
  insecure = true
}
```

Replace 192.168.122.158 in the above example with the IP from the router.

To prevent Terraform from locking itself out, you can use the device_insecure_first_run variable like this:

```bash
terraform init
TF_VAR_device_insecure_first_run=true terraform apply
```

This will set up everything except it will still allow you to manage the router without encryption and will not drop connections from the WAN port.

After the first run, you can download the server CA certificate from the router and start using it through a secure connection.

## Go secure

First, we need to set up a VPN connection with WireGuard. After that, we will get
the CA certificate from the router and store it on your computer for validating
the secure connections.

### Setup WireGuard

The file `examples/kvm_example/setupWireGuard.bash` can help you create a WireGuard
configuration. As input, it will need the a name of your configuration, the WAN
ip of your router, and the public key of the WireGuard interface in the router.

Here is how to get the public key from the MikroTik router:

```
/interface/wireguard print
```

With that information you can now call the script like this:

```bash
./setupWireguard.bash kvm_example 192.168.122.158 dCw9QfDZeMrrVlmKwNlGbj24W+IVsFmvrs18WbyneHw=
```

You will have to copy the configuration file to the `/etc/wireguard/` folder
and also modify the WireGuard section of the module configuration.

To apply the changes and start the connection do the following:

```bash
TF_VAR_device_insecure_first_run=true terraform apply
sudo wg-quick up kvm_example
```

When connected though WireGuard, the IP of the router will be `192.168.88.1`.

### Get the CA certificate

As we are using self-signed certificates, the CA certificate is just the
certificate of the router. Therefore, we can just download the router's
certificate, store it as ca.pem and assume it is the CA certificate.

Download the certificate to a file:

```bash
mkdir -p certificate
echo | openssl s_client -connect 192.168.88.1:443 | openssl x509 > certificate/ca.pem
```

### Setup Terraform

For Terraform to use the new secure connection, we will need to update the `providers.tf`` file

Make it look like this:

```hcl
provider "routeros" {
  hosturl        = "https://${var.device_admin_ip}"
  username       = var.device_admin_username
  password       = var.device_admin_password
  ca_certificate = var.device_ca_certificate_file
}
```

If the device you are configuring is not on IP 192.168.88.1 in the admin network, 
you have to add the correct IP in `terraform.tfvars`. Like this:

```bash
echo "device_admin_ip = \"192.168.88.2\"" >> terraform.tfvars
````

Now that we have connected to the router through a VPN and configured a secure
connection to its API, we can rerun the terraform apply without the device_insecure_first_run variable:

```bash
terraform apply
```


## Disable DHCP on WAN interface

When you are done configuring the router, you can set a fixed IP:

```
/ip address
add address=10.3.8.90/30 interface=ether13 network=10.3.8.88
/ip dhcp-client
set [find interface=ether1] disabled=yes
```
<!-- END_TF_DOCS -->