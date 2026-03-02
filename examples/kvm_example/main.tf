module "mikrotik" {
  source = "git@github.com:pippiio/mikrotik?ref=88a6ed21eface6cc70436fc553a613b8ad86ce70"

  device_insecure_first_run = var.device_insecure_first_run

  cloud_settings = {
    device_name                     = "kvmexample"
    device_ip                       = "192.168.88.1"
    interface_used_as_admin         = "kvmexample"
    cluster_name                    = "kvmexample"
    certificate_domain              = "techchapter.com"
    certificate_country             = "DK"
    certificate_organization        = "Tech Chapter ApS"
    certificate_ca_certificate_file = "certificates/ca.pem"
    interfaces_used_by_cluster = [
      "bond1",
      "ether4"
    ]
  }

  switching = {
    interface_used_as_admin = "ether1"
    interface_bonds = {
      "bond1" = {
        interfaces = ["ether2", "ether3"]
      }
    }
  }

  routing = {
    interface_used_as_wan = "ether1"
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
