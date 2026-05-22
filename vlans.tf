locals {
  physical_vlans = {
    for vlan_name, vlan in var.vlans : vlan_name => vlan
    if length(coalesce(vlan.interfaces, [])) > 1
  }

  vlan_interfaces = {
    for item in flatten([
      for vlan_name, vlan in local.physical_vlans : [
        for interface in vlan.interfaces : {
          vlan_name = vlan_name
          vlan      = vlan
          interface = interface
        }
      ]
      if length(coalesce(vlan.interfaces, [])) > 0
    ]) : "${item.vlan_name}/${item.interface}" => item
  }
}

resource "routeros_interface_bridge" "vlan" {
  for_each = local.physical_vlans

  name           = "vlan-${each.key}"
  vlan_filtering = true
}

resource "routeros_interface_bridge_port" "vlan" {
  for_each  = local.vlan_interfaces
  bridge    = routeros_interface_bridge.vlan[each.value.vlan_name].name
  interface = each.value.interface
  pvid      = each.value.vlan.id
}

resource "routeros_interface_bridge_vlan" "vlan" {
  for_each = local.physical_vlans

  bridge   = routeros_interface_bridge.vlan[each.key].name
  vlan_ids = [each.value.id]
  tagged   = [routeros_interface_bridge.vlan[each.key].name]
  untagged = each.value.interfaces
}

resource "routeros_interface_list" "vlan" {
  for_each = local.physical_vlans

  name = "VLAN-${each.key}-list"
}

resource "routeros_interface_list_member" "vlan" {
  for_each = local.physical_vlans

  interface = routeros_interface_bridge.vlan[each.key].name
  list      = routeros_interface_list.vlan[each.key].name
}

resource "routeros_interface_vlan" "vlan" {
  for_each = local.physical_vlans

  interface = routeros_interface_bridge.vlan[each.key].name
  name      = "VLAN-${each.key}"
  vlan_id   = each.value.id
}

resource "routeros_ip_address" "vlan" {
  for_each = local.physical_vlans

  address   = "${cidrhost(each.value.cidr, 1)}/${split("/", each.value.cidr)[1]}"
  interface = routeros_interface_vlan.vlan[each.key].name
  network   = cidrhost(each.value.cidr, 0)
}

resource "routeros_ip_pool" "vlan" {
  for_each = local.physical_vlans

  name   = "VLAN-${each.key}"
  ranges = ["${cidrhost(each.value.cidr, 2)}-${cidrhost(each.value.cidr, 254)}"]
}

resource "routeros_ip_dhcp_server" "vlan" {
  for_each = local.physical_vlans

  name         = "VLAN-${each.key}"
  interface    = routeros_interface_vlan.vlan[each.key].name
  address_pool = routeros_ip_pool.vlan[each.key].name
  disabled     = false
}

resource "routeros_ip_dhcp_server_network" "lan_net" {
  for_each = local.physical_vlans

  address    = each.value.cidr
  gateway    = cidrhost(each.value.cidr, 1)
  dns_server = [cidrhost(each.value.cidr, 1), "1.1.1.1"]
}

