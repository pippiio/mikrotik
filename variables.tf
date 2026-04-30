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
