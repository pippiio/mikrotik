locals {
  bgp_enabled = var.bgp != null
  bgp_peers   = local.bgp_enabled ? var.bgp.peers : {}

  bgp_accept_rules = {
    for item in flatten([
      for peer_name, peer in local.bgp_peers : [
        for idx, prefix in peer.accept_prefixes : {
          key    = "${peer_name}-${idx}"
          peer   = peer_name
          prefix = prefix
        }
      ]
    ]) : item.key => item
  }
}

resource "routeros_routing_bgp_instance" "this" {
  count = local.bgp_enabled ? 1 : 0

  name      = "bgp"
  as        = tostring(var.bgp.as)
  router_id = var.bgp.router_id
}

resource "routeros_routing_filter_rule" "bgp_accept" {
  for_each = local.bgp_accept_rules

  chain = "${each.value.peer}-in"
  rule  = "if (dst in ${each.value.prefix} && dst-len == 32) { accept }"
}

resource "routeros_routing_filter_rule" "bgp_reject" {
  for_each = local.bgp_peers

  chain = "${each.key}-in"
  rule  = "reject"

  depends_on = [routeros_routing_filter_rule.bgp_accept]
}

resource "routeros_routing_bgp_connection" "peer" {
  for_each = local.bgp_peers

  name     = each.key
  instance = routeros_routing_bgp_instance.this[0].name
  as       = tostring(var.bgp.as)
  listen   = true
  connect  = false

  local {
    role    = each.value.remote_as == var.bgp.as ? "ibgp" : "ebgp"
    address = cidrhost(var.vlans[each.value.vlan].cidr, 1)
  }

  remote {
    address = var.vlans[each.value.vlan].cidr
    as      = tostring(each.value.remote_as)
  }

  input {
    filter = "${each.key}-in"
  }

  depends_on = [routeros_routing_filter_rule.bgp_reject]
}
