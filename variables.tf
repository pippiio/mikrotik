variable "routing" {
  type = object({
    router_name                = string
    router_domain              = string
    router_admin_ip            = optional(string, "192.168.88.1")
    router_admin_network       = optional(string, "192.168.88.0")
    router_admin_subnet_size   = optional(string, "24")
    router_country             = string
    router_organization        = string
    router_ca_certificate_file = string
    dns_servers                = optional(set(string), ["1.1.1.1", "1.0.0.1"])
    cloud_name                 = string
    node_ip_pool               = optional(list(string), ["10.25.0.10-10.25.0.14"])
    cluster_gateway_ip         = optional(string, "10.25.0.1")
    cluster_network_address    = optional(string, "10.25.0.0")
    cluster_subnet_size        = optional(string, "24")
    interfaces_used_by_cluster = set(string)
    interface_used_as_wan      = string
  })
  description = <<-EOL
    This describes the configuration of a MikroTik router for supporting a Kubernetes cluster.

    router_name                : Name (and hostname) of the router (string)
    router_domain              : Domain name of the router. Will be used with router_name when creating certificates (string)
    router_admin_ip            : IP of the router on the router's admin network (Default: "192.168.88.1")
    router_admin_network       : IP of the network used for administration (Default: "192.168.88.0")
    router_admin_subnet_size   : Subnet size of the admin network (string)
    router_country             : Country code to use in certificates, e.g., DK (string)
    router_organization        : Name of organization to use in certificates (string)
    router_ca_certificate_file : Filename of the CA certificate, e.g., certificates/ca.pem (string)
    dns_servers                : List of DNS servers this cluster will use (Default: ["1.1.1.1", "1.0.0.1"])
    cloud_name                 : Name of the cloud, e.g., odea-cloud (string)
    node_ip_pool               : IP range used by nodes in the Kubernetes cluster (Default: ["10.25.0.10-10.25.0.14"])
    cluster_gateway_ip         : IP of the router in the Kubernetes network used as the gateway (Default: "10.25.0.1")
    cluster_network_address    : IP address of the internal network used by Kubernetes (Default: "10.25.0.0")
    cluster_subnet_size        : Subnet size of the internal network used by Kubernetes (Default: "24")
    interfaces_used_by_cluster : The set of interfaces used by the cluster, e.g., ether1 (set(string))
    interface_used_as_wan      : The WAN interface, e.g., ether13 (string)
  EOL
}

variable "wireguard" {
  type = object({
    gateway_ip   = optional(string, "10.3.254.1")
    network_ip   = optional(string, "10.3.254.0")
    network_size = optional(string, "24")
    peer         = optional(map(object({
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

variable "router_insecure_first_run" {
  description = "Set to true during first provision to prevent Terraform from locking itself out."
  type        = bool
  default     = false
}

variable "router_admin_username" {
  description = "The username for the admin user on the MikroTik device."
  type        = string
  default     = "admin"
}

variable "router_admin_password" {
  description = "The password for the admin user on the MikroTik device."
  type        = string
  sensitive   = true
  nullable    = false
}
