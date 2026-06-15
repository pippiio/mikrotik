resource "routeros_ip_firewall_filter" "forward_drop_all" {
  chain   = "forward"
  action  = "drop"
  comment = "Drop all other forward traffic"
}

resource "routeros_ip_firewall_filter" "forward_established_related" {
  chain            = "forward"
  action           = "accept"
  connection_state = "established,related"
  comment          = "Allow established/related forward traffic"

  place_before = routeros_ip_firewall_filter.forward_drop_all.id
}

resource "routeros_ip_firewall_filter" "forward_invalid" {
  chain            = "forward"
  action           = "drop"
  connection_state = "invalid"
  comment          = "Drop invalid forward traffic"

  place_before = routeros_ip_firewall_filter.forward_drop_all.id
}

resource "routeros_ip_firewall_filter" "allow" {
  for_each = local.allow_connections

  chain         = "forward"
  action        = "accept"
  in_interface  = each.value.src == "sites" ? routeros_interface_wireguard.sites[0].name : null
  src_address   = each.value.src != "sites" ? local.subnets[each.value.src] : null
  dst_address   = !strcontains(each.value.dst, "wan") ? local.subnets[each.value.dst] : null
  out_interface = strcontains(each.value.dst, "wan") ? local.wan_enabled ? routeros_interface_ethernet.wan[0].name : routeros_interface_vlan.transit[local.wan_trunk.name].name : null
  comment       = "Allow ${each.value.src} to ${each.value.dst}"

  place_before = routeros_ip_firewall_filter.forward_drop_all.id
}

resource "routeros_ip_firewall_filter" "transit_allow_wan" {
  for_each = local.transit_vlans_wan

  chain         = "forward"
  action        = "accept"
  src_address   = each.value
  out_interface = routeros_interface_ethernet.wan[0].name
  comment       = "Allow ${each.key} to wan"

  place_before = routeros_ip_firewall_filter.forward_drop_all.id
}

locals {
  allow_connections = {
    for item in flatten([
      flatten([for vlan_name, vlan in var.vlans : [
        for connection in vlan.allow_connections_to : {
          src = vlan_name
          dst = connection
        }
      ]]),
      flatten([for vlan_name, vlan in var.vlans : [
        for connection in vlan.allow_connections_from : {
          src = connection
          dst = vlan_name
        }
      ]]),
      flatten([for connection in var.wireguard.allow_connections_to : {
        src = "wireguard"
        dst = connection
      }]),
      flatten([for connection in var.sites.allow_connections_to : {
        src = "sites"
        dst = connection
      }])
    ]) : "${item.src}/${item.dst}" => item
  }

  transit_vlans_wan = {
    for item in flatten([for trunk_name, trunk in var.trunks : [
      for dst_vlan_name, dst_vlan in trunk.dst_vlans : {
        name = "${trunk_name}/${dst_vlan_name}"
        cidr = dst_vlan.cidr
      }
    ] if local.wan_enabled]) : item.name => item.cidr
  }

  subnets = {
    for item in flatten([
      [for vlan_name, vlan in var.vlans : {
        name = vlan_name
        cidr = vlan.cidr
      }],
      flatten([for trunk_name, trunk in var.trunks : [
        for dst_vlan_name, dst_vlan in trunk.dst_vlans : {
          name = "${trunk_name}/${dst_vlan_name}"
          cidr = dst_vlan.cidr
        }
      ]]),
      [{
        name = "wireguard"
        cidr = var.wireguard.cidr
      }]
    ]) : item.name => item.cidr
  }
}
