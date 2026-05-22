locals {
  disabled_services = {
    telnet  = 23
    ftp     = 21
    www-ssl = 443
    api-ssl = 8729
  }

  wg_only_services = local.wg_enabled || var.wireguard.external ? {
    ssh    = 22
    winbox = 8291
    www    = 80
    api    = 8728
  } : {}
}

resource "routeros_ip_service" "disabled" {
  for_each = local.disabled_services

  numbers  = each.key
  port     = each.value
  disabled = true
}

resource "routeros_ip_service" "wg_only" {
  for_each = local.wg_only_services

  numbers  = each.key
  port     = each.value
  address  = local.wg_enabled || var.wireguard.external ? "${var.wireguard.cidr},${cidrhost("${var.admin_ip}/24", 0)}/24" : null
  disabled = false
}

resource "routeros_ipv6_settings" "this" {
  disable_ipv6 = true
}

resource "routeros_ip_dns" "dns" {
  allow_remote_requests = true
  servers               = ["1.1.1.1", "8.8.8.8"]
}
