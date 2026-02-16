resource "routeros_interface_wireguard" "wireguard" {
  name        = "wireguard"
  listen_port = "51820"
}

resource "routeros_interface_wireguard_peer" "wireguard_peer" {
  interface = routeros_interface_wireguard.wireguard.name
  for_each  = var.wireguard.peer
  name      = each.key
  public_key = "${each.value.public_key}"
  allowed_address = [
    "${each.value.ip_address}/32"
  ]
}

resource "routeros_ip_address" "wireguard_ip" {
  address   = "${var.wireguard.gateway_ip}/${var.wireguard.network_size}"
  interface = routeros_interface_wireguard.wireguard.name
  network   = var.wireguard.network_ip
}

resource "routeros_interface_list_member" "wireguard_lan" {
  interface = routeros_interface_wireguard.wireguard.name
  list      = "LAN"
}

data "routeros_ip_firewall" "fw" {
  rules {
    filter = {
      chain = "input"
      action = "drop"
      in_interface = var.routing.interface_used_as_wan
    }
  }
}

resource "routeros_ip_firewall_filter" "rule_allow_wireguard" {
  comment      = "Allow WireGuard"
  action       = "accept"
  chain        = "input"
  dst_port     = "51820"
  protocol     = "udp"
  log          = false
  log_prefix   = ""
  count        = length(data.routeros_ip_firewall.fw.rules)
  place_before = data.routeros_ip_firewall.fw.rules[0].id
}

resource "routeros_ip_firewall_filter" "rule_allow_wireguard_to_local" {
  comment          = "Allow WireGuard traffic to LOCAL"
  action           = "accept"
  chain            = "forward"
  src_address      = "${var.wireguard.network_ip}/${var.wireguard.network_size}"
  dst_address      = "${var.routing.router_admin_network}/${var.routing.router_admin_subnet_size}"
  log              = false
  log_prefix       = ""
  count            = length(data.routeros_ip_firewall.fw.rules)
  place_before     = data.routeros_ip_firewall.fw.rules[0].id
}

resource "routeros_ip_firewall_filter" "rule_allow_wireguard_to_k8s" {
  comment          = "Allow WireGuard traffic to Kubernetes cluster"
  action           = "accept"
  chain            = "forward"
  src_address      = "${var.wireguard.network_ip}/${var.wireguard.network_size}"
  dst_address      = "${var.routing.cluster_network_address}/${var.routing.cluster_subnet_size}"
  log              = false
  log_prefix       = ""
  count            = length(data.routeros_ip_firewall.fw.rules)
  place_before     = data.routeros_ip_firewall.fw.rules[0].id
}

