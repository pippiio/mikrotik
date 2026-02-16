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
    This descripes a configuration of a MikroTek router for supporting a Kubernetes cluster

    router_name               : Name ( and hostname ) of router
    router_domain             : Domain name of router. Will be used with router_name when creating certificates
    router_admin_ip           : IP of router on routers admin network
    router_admin_network      : IP of network used for administration
    router_admin_network_size : Subnet size of admin network
    router_country            : Country code to use in certificates
    router_organization       : Name of organization to use in certificates
    dns_servers               : List of DNS servers this cluster will use
    cloud_name                : Name of cloud eg. odea-cloud
    node_ip_pool              : IP range used by nodes in Kubernetes cluster
    cluster_gateway_ip        : IP of router in Kubernetes network used as gateway
    cloud_network_address     : IP address of internal network used by Kubernetes
    interface_used_by_cluster : The set of interfaces used by the cluster
    interface_used_as_wan     : The WAN interface ( eg ether13 )
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
}

variable "router_insecure_first_run" {
  description = "Set to true during first provision to prevent terraform to lock it self out"
  type        = bool
  default     = false
}

variable "router_admin_username" {
  description = "The username for the admin user on the MikroTek device"
  type        = string
  default     = "admin"
}

variable "router_admin_password" {
  description = "The password for the admin user on the MikroTek device"
  type        = string
  sensitive   = true
  nullable    = false
}
