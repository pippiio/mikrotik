locals {
  sites_enabled = var.sites.cidr != null

  sites_gateway = local.sites_enabled ? "${cidrhost(var.sites.cidr, 1)}/${split("/", var.sites.cidr)[1]}" : null

  site_routes = {
    for item in flatten([
      for peer_name, peer in var.sites.peers : [
        for cidr in peer.remote_cidrs : {
          peer_name = peer_name
          cidr      = cidr
        }
      ]
    ]) : "${item.peer_name}/${item.cidr}" => item
  }
}

resource "routeros_interface_wireguard" "sites" {
  count = local.sites_enabled ? 1 : 0

  name        = "wg-sites"
  listen_port = var.sites.listen_port
}

resource "routeros_ip_address" "sites" {
  count = local.sites_enabled ? 1 : 0

  address   = local.sites_gateway
  interface = routeros_interface_wireguard.sites[0].name
  network   = cidrhost(var.sites.cidr, 0)
}

resource "routeros_interface_wireguard_peer" "sites_peer" {
  for_each = var.sites.peers

  interface        = routeros_interface_wireguard.sites[0].name
  public_key       = each.value.remote_public_key
  allowed_address  = each.value.remote_cidrs
  endpoint_address = each.value.endpoint
  endpoint_port    = each.value.endpoint != null ? var.sites.listen_port : null
  comment          = each.key
}

resource "routeros_ip_route" "sites_peer" {
  for_each = local.site_routes

  dst_address = each.value.cidr
  gateway     = var.sites.peers[each.value.peer_name].address
  comment     = "site/${each.key}"
}

output "site_public_key" {
  value       = local.sites_enabled ? routeros_interface_wireguard.sites[0].public_key : null
  description = "This router's WireGuard public key for the shared sites interface. Cross-wire into remote peers' remote_public_key."
}
