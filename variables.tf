variable "cloud_settings" {
  type = object({
    device_name = string
    device_ip            = optional(string, "192.168.88.1")
    cluster_name = string
    interfaces_used_by_cluster = set(string)
    certificate_domain              = string
    certificate_country             = string
    certificate_organization        = string
    certificate_ca_certificate_file = string
  })
  description = <<-EOL
    This describes the configuration of a MikroTik router that is common for devices used as routers and switches

    device_name                : Name (and hostname) of the MikroTik (string)
    device_ip            : IP of the router on the router's admin network (Default: "192.168.88.1")
    cloud_name                 : Name of the cloud, e.g., odea-cloud (string)
    certificate_domain              : Domain name of the router. Will be used with router_name when creating certificates (string)
    certificate_country             : Country code to use in certificates, e.g., DK (string)
    certificate_organization        : Name of organization to use in certificates (string)
    certificate_ca_certificate_file : Filename of the CA certificate, e.g., certificates/ca.pem (string)
    interfaces_used_by_cluster : The set of interfaces used by the cluster, e.g., ether1 (set(string))
    switch_admin_ip            : IP of the router on the router's admin network (Default: "192.168.88.1")
  EOL
  
}
variable "routing" {
  default = {
    this_is_a_router           = false
    interface_used_as_wan      = ""
  }
  type = object({
    this_is_a_router           = optional(bool, true)
    router_admin_network       = optional(string, "192.168.88.0")
    router_admin_subnet_size   = optional(string, "24")
    dns_servers                = optional(set(string), ["1.1.1.1", "1.0.0.1"])
    node_ip_pool               = optional(list(string), ["10.25.0.10-10.25.0.14"])
    cluster_gateway_ip         = optional(string, "10.25.0.1")
    cluster_network_address    = optional(string, "10.25.0.0")
    cluster_subnet_size        = optional(string, "24")
    interface_used_as_wan      = string
  })
  description = <<-EOL
    This describes the configuration of a MikroTik router for supporting a Kubernetes cluster.

    router_domain              : Domain name of the router. Will be used with router_name when creating certificates (string)
    router_admin_network       : IP of the network used for administration (Default: "192.168.88.0")
    router_admin_subnet_size   : Subnet size of the admin network (string)
    dns_servers                : List of DNS servers this cluster will use (Default: ["1.1.1.1", "1.0.0.1"])
    node_ip_pool               : IP range used by nodes in the Kubernetes cluster (Default: ["10.25.0.10-10.25.0.14"])
    cluster_gateway_ip         : IP of the router in the Kubernetes network used as the gateway (Default: "10.25.0.1")
    cluster_network_address    : IP address of the internal network used by Kubernetes (Default: "10.25.0.0")
    cluster_subnet_size        : Subnet size of the internal network used by Kubernetes (Default: "24")
    interface_used_as_wan      : The WAN interface, e.g., ether13 (string)
  EOL
}

variable "switching" {
  type = object({
    interface_used_as_admin = optional(string)
    interface_bonds = optional(list(object({
      name = string
      interfaces = set(string)
    })), [])
  })
  description = <<-EOL
    This section describtes configuration for a switch.
    The same MikroTik device can function as a router and a switch.
    But it can also only function as a switch.

    interface_used_as_admin : Limit administration interfaces to a port (Default: any)
    interface_bonds : Create a new interface by bonding 2 fysical interfaces. (Default: {})
  EOL
}

variable "wireguard" {
  default = {
    this_is_a_vpn = false
    peer = {}
  }
  type = object({
    this_is_a_vpn = optional(bool, true)
    gateway_ip    = optional(string, "10.3.254.1")
    network_ip    = optional(string, "10.3.254.0")
    network_size  = optional(string, "24")
    peer = optional(map(object({
      public_key = string
      ip_address = string
    })), {})
  })
  description = <<-EOL
    This section describes the WireGuard configuration on the router.

    gateway_ip   : IP of the router in the VPN network (Default: "10.3.254.1")
    network_ip   : Network IP of the VPN network (Default: "10.3.254.0")
    network_size : Subnet size of the VPN network (Default: "24")
    peer         : Describes the peers to expect VPN connections from (Default: {})
  EOL
}

variable "device_insecure_first_run" {
  description = "Set to true during first provision to prevent Terraform from locking itself out."
  type        = bool
  default     = false
}

variable "device_admin_ip" {
  type = string
  default = "192.168.88.1"
}
