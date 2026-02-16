provider "routeros" {
  hosturl        = "https://${var.router_admin_ip}"
  username       = var.router_admin_username
  password       = var.router_admin_password
  ca_certificate = var.router_ca_certificate_file
}

# provider "routeros" {
#   hosturl        = "http://192.168.122.158"
#   username       = var.router_admin_username
#   password       = var.router_admin_password
#   insecure = true
# }
