resource "routeros_system_identity" "id" {
  name = var.routing.router_name
}

resource "routeros_ip_dns_forwarders" "dns_servers" {
  dns_servers = var.routing.dns_servers
  name = "dns_servers"
}

resource "routeros_ip_pool" "node_ip_pool" {
  name = var.routing.cloud_name
  ranges = var.routing.node_ip_pool
}


resource "routeros_interface_bridge" "cloud" {
  name           = var.routing.cloud_name
  arp            = "proxy-arp"
  vlan_filtering = false
}

resource "routeros_ip_dhcp_server" "dhcp" {
  address_pool = routeros_ip_pool.node_ip_pool.name
  interface    = routeros_interface_bridge.cloud.name
  name         = var.routing.cloud_name
}

# 7.20
resource "routeros_routing_bgp_instance" "bgp_instance" {
  name      = "${var.routing.cloud_name}-k8s"
  as        = 64100
  router_id = var.routing.cluster_gateway_ip
}

resource "routeros_routing_bgp_template" "k8s_template" {
  name             = "${var.routing.cloud_name}-k8s"
  address_families = "ip"
  as               = 65100
  disabled         = false
  routing_table    = "main"
}

resource "routeros_routing_bgp_connection" "k8s_listener" {
  name             = "${var.routing.cloud_name}-k8s-listener"
  address_families = "ip"
  as               = 65100
  connect          = false
  disabled         = false
  listen           = true
  multihop         = true
  nexthop_choice   = "force-self"
  routing_table    = "main"
  local {
    address = var.routing.cluster_gateway_ip
    role    = "ebgp"
  }
  output {
    default_originate = "always"
  }
  remote {
    address = "${var.routing.cluster_network_address}/${var.routing.cluster_subnet_size}"
    as      = 65200
  }
  templates = [
    routeros_routing_bgp_template.k8s_template.name
  ]
  instance  = routeros_routing_bgp_template.k8s_template.name
}

# Next 2 resouces are for 7.18 but nor supported in 7.20
# resource "routeros_routing_bgp_template" "k8s_template" {
#   name             = "${var.routing.cloud_name}-k8s"
#   address_families = "ip"
#   as               = 65100
#   disabled         = false
#   routing_table    = "main"
#   router_id        = var.routing.cluster_gateway_ip
# }

# resource "routeros_routing_bgp_connection" "k8s_listener" {
#   name             = "${var.routing.cloud_name}-k8s-listener"
#   address_families = "ip"
#   as               = 65100
#   connect          = false
#   disabled         = false
#   listen           = true
#   multihop         = true
#   nexthop_choice   = "force-self"
#   routing_table    = "main"
#   local {
#     address = var.routing.cluster_gateway_ip
#     role    = "ebgp"
#   }
#   output {
#     default_originate = "always"
#   }
#   remote {
#     address = "${var.routing.cluster_network_address}/${var.routing.cluster_subnet_size}"
#     as      = 65200
#   }
#   templates = [
#     routeros_routing_bgp_template.k8s_template.name
#   ]
#   router_id = var.routing.cluster_gateway_ip
# }

resource "routeros_interface_bridge_port" "cloud" {
  bridge    = routeros_interface_bridge.cloud.name
  for_each  = var.routing.interfaces_used_by_cluster
  interface = "${each.value}"
}

resource "routeros_interface_list_member" "lan" {
  interface = routeros_interface_bridge.cloud.name
  list      = "LAN"
}

data "routeros_interfaces" "interface_wan" {
    filter = {
      name = "WAN"
    }
}

resource "routeros_interface_list" "list" {
  name = "WAN"
  count     = length(data.routeros_interfaces.interface_wan.interfaces) == 0 ? 1 : 0
}

resource "routeros_interface_list_member" "wan" {
  interface = var.routing.interface_used_as_wan
  list      = "WAN"
  count     = length(data.routeros_interfaces.interface_wan.interfaces) == 0 ? 1 : 0
}

resource "routeros_ip_address" "cloud_ips" {
  address   = "${var.routing.cluster_gateway_ip}/${var.routing.cluster_subnet_size}"
  interface = routeros_interface_bridge.cloud.name
  network   = var.routing.cluster_network_address
}

resource "routeros_ip_dhcp_server_network" "dhcp_server_network" {
  address   = "${var.routing.cluster_network_address}/${var.routing.cluster_subnet_size}"
  gateway    = var.routing.cluster_gateway_ip
  dns_server = var.routing.dns_servers
  netmask    = var.routing.cluster_subnet_size
}

resource "routeros_ip_firewall_filter" "rule_border_gateway_protocol" {
  comment     = "Allow Border Gateway Protocol"
  action      = "accept"
  chain       = "input"
  dst_port    = "179"
  protocol    = "tcp"
  log         = false
  log_prefix  = ""
}

resource "routeros_ip_firewall_filter" "rule_allow_established" {
  comment          = "Allow establised/related connections"
  action           = "accept"
  chain            = "input"
  connection_state = "established,related"
}

resource "routeros_ip_firewall_filter" "rule_drop_invalid" {
  comment          = "Drop invalid"
  action           = "drop"
  chain            = "input"
  connection_state = "invalid"
}

resource "routeros_ip_firewall_filter" "drop_all_other_wan" {
  comment          = "Drop all other WAN input"
  action           = "drop"
  chain            = "input"
  in_interface     = var.routing.interface_used_as_wan
  disabled         = var.router_insecure_first_run ? true : false
}

resource "routeros_ip_firewall_nat" "nat" {
  action             = "masquerade"
  chain              = "srcnat"
  out_interface_list = "WAN"
  log                = false
  log_prefix         = ""
}
