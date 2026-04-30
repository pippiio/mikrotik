locals {
  dst_vlans = {
    for item in flatten([
      for trunk_name, trunk in var.trunks : [
        for dst_vlan_name, dst_vlan in trunk.dst_vlans : {
          trunk_name    = trunk_name
          trunk         = trunk
          dst_vlan_name = dst_vlan_name
          dst_vlan      = dst_vlan
        }
      ]
      if length(trunk.dst_vlans) > 0
    ]) : "${item.trunk_name}/${item.dst_vlan_name}" => item
  }

  bonds = {
    for trunk_name, trunk in var.trunks : trunk_name => {
      name       = trunk_name
      interfaces = trunk.interfaces
    }
    if length(trunk.interfaces) > 1
  }

  wan_trunk = try([
    for trunk_name, trunk in var.trunks : merge(trunk, {
      name = trunk_name
    })
    if trunk.wan
  ][0], null)
}

resource "routeros_interface_bonding" "bond" {
  for_each = local.bonds

  name      = "BOND-${each.value.name}"
  mode      = "802.3ad"
  slaves    = each.value.interfaces
  lacp_rate = "1sec"
}
resource "routeros_interface_vlan" "transit" {
  for_each = var.trunks

  name      = "VLAN-${each.value.id}-TRANSIT"
  interface = routeros_interface_bonding.bond[each.key].name
  vlan_id   = each.value.id
}

resource "routeros_ip_address" "transit" {
  for_each = var.trunks

  address   = "${each.value.src_address}/30"
  interface = routeros_interface_vlan.transit[each.key].name
  network   = cidrhost("${each.value.src_address}/30", 0)
}

resource "routeros_ip_route" "transit" {
  for_each = local.dst_vlans

  dst_address = each.value.dst_vlan.cidr
  gateway     = each.value.trunk.dst_address
  comment     = "VLAN-${each.value.dst_vlan.id}"
}

resource "routeros_ip_route" "transit_wan" {
  count = local.wan_trunk != null ? 1 : 0

  dst_address = "0.0.0.0/0"
  gateway     = local.wan_trunk.dst_address
  comment     = "TRANSIT-WAN"
}
