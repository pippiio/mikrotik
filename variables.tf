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

variable "sites" {
  description = "Site-to-site WireGuard VPN configuration. All remote sites share a single wg-sites interface on this router. Set cidr to enable; omit or set cidr = null to disable."
  type = object({
    # UDP port the wg-sites interface listens on. Defaults to 51821 to avoid collision with the client VPN on 51820.
    listen_port = optional(number, 51821)

    # Transit subnet for the site-to-site tunnel. This router takes host 1 (e.g. 172.31.0.1/24).
    # Each peer's address must be a host within this CIDR. Set to null to disable the sites feature entirely.
    cidr = string

    # Names of local networks (vlans, wireguard, trunk/vlan) that traffic arriving on wg-sites is allowed to reach.
    allow_connections_to = optional(list(string), [])

    peers = optional(map(object({
      # Public IP or hostname of the remote router. Used to initiate the tunnel from this side.
      # Omit if the remote side is responsible for initiating the connection.
      endpoint = optional(string)

      # This peer's IP address within var.sites.cidr (e.g. "172.31.0.2").
      # Used as the next-hop gateway for all routes toward this peer's remote_cidrs.
      address = string

      # Subnets reachable behind this peer. Added to allowed_address on the WireGuard peer
      # and installed as static routes via this peer's address.
      remote_cidrs = list(string)

      # The remote router's WireGuard public key for the wg-sites interface.
      remote_public_key = optional(string)
    })), {})
  })

  default = {
    cidr  = null
    peers = {}
  }
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
