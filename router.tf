resource "routeros_ip_dns_forwarders" "dns_servers" {
  dns_servers = var.routing.dns_servers
  name        = "dns_servers"
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_ip_pool" "node_ip_pool" {
  name   = var.cloud_settings.cluster_name
  ranges = var.routing.node_ip_pool
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_ip_dhcp_server" "dhcp" {
  address_pool = routeros_ip_pool.node_ip_pool[0].name
  interface    = routeros_interface_bridge.cloud.name
  name         = var.cloud_settings.cluster_name
  count = var.routing.this_is_a_router ? 1 : 0
}

# 7.20
resource "routeros_routing_bgp_instance" "bgp_instance" {
  name      = "${var.cloud_settings.cluster_name}-k8s"
  as        = 64100
  router_id = var.routing.cluster_gateway_ip
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_routing_bgp_template" "k8s_template" {
  name             = "${var.cloud_settings.cluster_name}-k8s"
  address_families = "ip"
  as               = 65100
  disabled         = false
  routing_table    = "main"
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_routing_bgp_connection" "k8s_listener" {
  name             = "${var.cloud_settings.cluster_name}-k8s-listener"
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
    routeros_routing_bgp_template.k8s_template[0].name
  ]
  instance = routeros_routing_bgp_template.k8s_template[0].name
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_interface_list" "list" {
  name = "WAN"
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_interface_list_member" "wan" {
  interface = var.routing.interface_used_as_wan
  list      = "WAN"
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_ip_address" "cloud_ips" {
  address   = "${var.routing.cluster_gateway_ip}/${var.routing.cluster_subnet_size}"
  interface = routeros_interface_bridge.cloud.name
  network   = var.routing.cluster_network_address
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_ip_dhcp_server_network" "dhcp_server_network" {
  address    = "${var.routing.cluster_network_address}/${var.routing.cluster_subnet_size}"
  gateway    = var.routing.cluster_gateway_ip
  dns_server = var.routing.dns_servers
  netmask    = var.routing.cluster_subnet_size
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_ip_firewall_filter" "rule_border_gateway_protocol" {
  comment    = "Allow Border Gateway Protocol"
  action     = "accept"
  chain      = "input"
  dst_port   = "179"
  protocol   = "tcp"
  log        = false
  log_prefix = ""
  count = var.routing.this_is_a_router ? 1 : 0
}

# resource "routeros_ip_firewall_filter" "rule_k8s_to_internet" {
#   comment          = "Allow LAN to internet traffic"
#   action           = "accept"
#   chain            = "forward"
#   connection_state = "new"
#   in-interface     = "LAN"
#   out-interface    = var.routing.interface_used_as_wan
#   log              = false
#   log_prefix       = ""
# }

resource "routeros_ip_firewall_filter" "rule_allow_established" {
  comment          = "Allow establised/related connections"
  action           = "accept"
  chain            = "input"
  connection_state = "established,related"
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_ip_firewall_filter" "rule_drop_invalid" {
  comment          = "Drop invalid"
  action           = "drop"
  chain            = "input"
  connection_state = "invalid"
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_ip_firewall_filter" "drop_all_other_wan" {
  comment      = "Drop all other WAN input"
  action       = "drop"
  chain        = "input"
  in_interface = var.routing.interface_used_as_wan
  disabled     = var.device_insecure_first_run ? true : false
  count = var.routing.this_is_a_router ? 1 : 0
}

resource "routeros_ip_firewall_nat" "nat" {
  action             = "masquerade"
  chain              = "srcnat"
  out_interface_list = "WAN"
  log                = false
  log_prefix         = ""
  count = var.routing.this_is_a_router ? 1 : 0
}
