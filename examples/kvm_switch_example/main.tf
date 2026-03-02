module "mikrotik" {
  source = "git@github.com:pippiio/mikrotik?ref=3e016f0083b35d576ee24d1e3769f9c85ee9a0da"

  device_insecure_first_run = var.device_insecure_first_run

  cloud_settings = {
    device_name                     = "kvmexample-sw"
    device_ip                       = "192.168.88.2"
    interface_used_as_admin         = "ether13"
    cluster_name                    = "kvmexample"
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
