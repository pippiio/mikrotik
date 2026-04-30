locals {
  wg_enabled = var.wireguard.endpoint != null

  wireguard_gateway = local.wg_enabled ? "${cidrhost(var.wireguard.cidr, 1)}/${split("/", var.wireguard.cidr)[1]}" : null
}

resource "routeros_interface_wireguard" "wg" {
  count = local.wg_enabled ? 1 : 0

  name        = "wg-vpn"
  listen_port = var.wireguard.listen_port
}

resource "routeros_ip_address" "wg" {
  count = local.wg_enabled ? 1 : 0

  address   = local.wireguard_gateway
  interface = routeros_interface_wireguard.wg[0].name
  network   = cidrhost(var.wireguard.cidr, 0)
}

resource "wireguard_asymmetric_key" "peer" {
  for_each = var.wireguard.peers
}

resource "routeros_interface_wireguard_peer" "peer" {
  for_each = var.wireguard.peers

  interface       = routeros_interface_wireguard.wg[0].name
  public_key      = wireguard_asymmetric_key.peer[each.key].public_key
  allowed_address = [each.value.address]
  comment         = each.key
}

locals {
  wireguard_client_configs = {
    for key, peer in var.wireguard.peers : key => <<-EOT
    [Interface]
    PrivateKey = ${wireguard_asymmetric_key.peer[key].private_key}
    Address = ${peer.address}
    DNS = ${cidrhost(var.wireguard.cidr, 1)}

    [Peer]
    PublicKey = ${routeros_interface_wireguard.wg[0].public_key}
    Endpoint = ${var.wireguard.endpoint}:${var.wireguard.listen_port}
    AllowedIPs = 0.0.0.0/0
    PersistentKeepalive = 25
    EOT
  }
}

output "wireguard_client_configs" {
  value     = local.wireguard_client_configs
  sensitive = true
}
