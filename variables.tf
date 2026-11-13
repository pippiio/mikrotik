variable "admin_ip" {
  type        = string
  description = "IP used by admin port created by hand on first setup"
}

variable "wan" {
  type = object({
    interface = string
    address   = string
    gateway   = string
    speed     = string
  })

  default = {
    interface = null
    address   = null
    gateway   = null
    speed     = null
  }
}

variable "vlans" {
  type = map(object({
    id                     = number
    cidr                   = string
    interfaces             = optional(list(string), [])
    allow_connections_to   = optional(list(string), [])
    allow_connections_from = optional(list(string), [])
  }))

  default = {}
}

variable "wireguard" {
  type = object({
    listen_port          = optional(number, 51820)
    cidr                 = string
    endpoint             = string
    allow_connections_to = optional(list(string), [])
    external             = optional(bool, false)
    peers = optional(map(object({
      address = string
    })), {})
  })

  default = {
    cidr     = null
    endpoint = null
  }
}

variable "bgp" {
  type = object({
    as        = number
    router_id = optional(string)
    peers = optional(map(object({
      vlan            = optional(string)
      trunk           = optional(string)
      remote_as       = number
      accept_prefixes = optional(list(string), [])
      expose = optional(object({
        address_range = string
        ports         = list(number)
        protocol      = optional(string, "tcp")
      }), null)
    })), {})
  })

  default = null

  validation {
    condition = var.bgp == null ? true : alltrue([
      for peer in var.bgp.peers : (peer.vlan != null) != (peer.trunk != null)
    ])
    error_message = "Each bgp peer must set exactly one of `vlan` (a dynamic, listening peer group) or `trunk` (a static, point-to-point peer)."
  }
}

variable "exposed_services" {
  type = map(object({
    gateway   = string
    addresses = list(string)
    ports     = list(number)
    protocol  = optional(string, "tcp")
  }))

  default = {}
}

variable "trunks" {
  type = map(object({
    id          = number
    src_address = string
    dst_address = string
    wan         = optional(bool, false)
    interfaces  = list(string)
    dst_vlans = map(object({
      id   = number
      cidr = string
    }))
  }))

  default = {}
}
