/**
 * # MikroTik module
 * 
 * The is a generic Terraform module within the pippi.io family, maintained by
 * Tech Chapter. The pippi.io modules are build to support common use cases
 * often seen at Tech Chapters clients. They are created with best practices in
 * mind and battle tested at scale. All modules are free and open-source under
 * the Mozilla Public License Version 2.0.
 * 
 * The mikrotik module is made to provision and manage a MikroTik ethernet
 * router to support an internal Kubernetes cluster.
 */

resource "routeros_system_identity" "id" {
  name = var.cloud_settings.device_name
}

resource "routeros_interface_bridge" "cloud" {
  name           = var.cloud_settings.cluster_name
  arp            = "proxy-arp"
  vlan_filtering = false
}

resource "routeros_interface_bridge_port" "cloud" {
  bridge    = routeros_interface_bridge.cloud.name
  for_each  = var.cloud_settings.interfaces_used_by_cluster
  interface = each.value
}

resource "routeros_interface_list" "lan" {
  name = "LAN"
}

resource "routeros_interface_list_member" "lan" {
  interface = routeros_interface_bridge.cloud.name
  list      = "LAN"
}

resource "routeros_ip_address" "lan" {
  address   = "${var.cloud_settings.device_ip}/24"
  interface = routeros_interface_bridge.cloud.name
  network   = "192.168.88.0"
}


