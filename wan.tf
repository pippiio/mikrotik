locals {
  wan_enabled = var.wan.interface != null
}

resource "routeros_interface_list" "wan" {
  count = local.wan_enabled ? 1 : 0

  name = "WAN"
}

resource "routeros_interface_list_member" "wan" {
  count = local.wan_enabled ? 1 : 0

  interface = var.wan.interface
  list      = routeros_interface_list.wan[0].name
}

resource "routeros_ip_address" "wan" {
  count = local.wan_enabled ? 1 : 0

  address   = var.wan.address
  interface = var.wan.interface
  network   = cidrhost(var.wan.address, 0)
}

resource "routeros_interface_ethernet" "wan" {
  count = local.wan_enabled ? 1 : 0

  factory_name     = var.wan.interface
  name             = var.wan.interface
  auto_negotiation = true
  speed            = var.wan.speed
}

resource "routeros_ip_route" "wan" {
  count = local.wan_enabled ? 1 : 0

  dst_address = "0.0.0.0/0"
  gateway     = cidrhost(var.wan.address, 1)
}

resource "routeros_ip_firewall_nat" "wan" {
  count = local.wan_enabled ? 1 : 0

  chain         = "srcnat"
  action        = "masquerade"
  out_interface = var.wan.interface
}
