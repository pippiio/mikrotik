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
  # A vlan peer is a dynamic group of potential neighbors (e.g. any k8s node
  # in the subnet), so this device only listens passively - there's no
  # single address to dial. A trunk peer is a single known neighbor on a
  # direct link, so this device both listens and dials out: whichever side
  # connects first establishes the session, and it works regardless of
  # which side's config gets applied first.
  listen  = true
  connect = each.value.trunk != null

  local {
    role    = each.value.remote_as == var.bgp.as ? "ibgp" : "ebgp"
    address = each.value.trunk != null ? var.trunks[each.value.trunk].src_address : cidrhost(var.vlans[each.value.vlan].cidr, 1)
  }

  remote {
    address = each.value.trunk != null ? var.trunks[each.value.trunk].dst_address : var.vlans[each.value.vlan].cidr
    as      = tostring(each.value.remote_as)
  }

  input {
    filter = "${each.key}-in"
  }

  depends_on = [routeros_routing_filter_rule.bgp_reject]
}
