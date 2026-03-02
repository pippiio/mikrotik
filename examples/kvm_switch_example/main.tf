module "mikrotik" {
  source = "git@github.com:pippiio/mikrotik?ref=88a6ed21eface6cc70436fc553a613b8ad86ce70"

  device_insecure_first_run = var.device_insecure_first_run

  cloud_settings = {
    device_name                     = "kvm-sw"
    device_ip                       = "192.168.88.2"
    interface_used_as_admin         = "ether13"
    cluster_name                    = "kvm"
    certificate_domain              = "techchapter.com"
    certificate_country             = "DK"
    certificate_organization        = "Tech Chapter ApS"
    certificate_ca_certificate_file = "certificates/ca.pem"
    interfaces_used_by_cluster = [
      "ether1",
      "ether2",
      "ether3",
      "ether4",
      "ether5",
      "ether6",
      "ether7",
      "ether8",
      "ether9",
      "bond1"
    ]
  }

  switching = {
    interface_bonds = {
      "bond1" = {
        interfaces = ["ether10", "ether11"]
      }
    }
  }

}
