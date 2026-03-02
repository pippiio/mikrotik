resource "routeros_interface_bonding" "bond" {
  for_each = var.switching.interface_bonds
  name     = each.key
  slaves   = each.value.interfaces
}

resource "routeros_interface_bridge" "cloud" {
  name           = var.cloud_settings.cluster_name
  arp            = "proxy-arp"
  vlan_filtering = false
}

resource "routeros_interface_bridge_port" "cloud" {
  bridge     = routeros_interface_bridge.cloud.name
  for_each   = var.cloud_settings.interfaces_used_by_cluster
  interface  = each.value
  depends_on = [resource.routeros_interface_bonding.bond]
}
