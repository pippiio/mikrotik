provider "routeros" {
  hosturl        = "https://${var.device_admin_ip}"
  username       = var.device_admin_username
  password       = var.device_admin_password
  ca_certificate = var.device_ca_certificate_file
}

# provider "routeros" {
#   hosturl        = "http://192.168.122.70"
#   username       = var.device_admin_username
#   password       = var.device_admin_password
#   insecure = true
# }
