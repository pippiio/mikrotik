module "mikrotik" {
  source = "../../"

  router_insecure_first_run    = var.router_insecure_first_run
  openvpn_admin_account_secret = var.openvpn_admin_account_secret
  router_admin_password        = var.router_admin_password
  routing = {
    router_name                = "kvmexample"
    router_domain              = "techchapter.com"
    router_country             = "DK"
    router_organization        = "Tech Chapter ApS"
    router_ca_certificate_file = "certificates/ca.pem"
    cloud_name                 = "kvmexample"
    interface_used_as_wan      = "ether1"
    interfaces_used_by_cluster = [
      "ether2",
      "ether3",
      "ether4"
    ]
  }

  wireguard = {
    peer = {
      "techops" = {
        ip_address = "10.3.254.20"
        public_key = "564VzAawdhktPb6eoUbgCqwl8AKTBwqcLhQKSzBGnxs="
      }
    }
  }

}
