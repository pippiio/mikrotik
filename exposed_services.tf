locals {
  exposed_service_hosts = {
    for item in flatten([
      for service_name, service in var.exposed_services : [
        for address in service.addresses : {
          key      = "${service_name}-${address}"
          address  = address
          gateway  = service.gateway
          ports    = service.ports
          protocol = service.protocol
          comment  = service_name
        }
      ]
    ]) : item.key => item
  }
}

resource "routeros_ip_route" "exposed_service" {
  for_each = local.exposed_service_hosts

  dst_address = "${each.value.address}/32"
  gateway     = each.value.gateway
  comment     = each.value.comment
}
