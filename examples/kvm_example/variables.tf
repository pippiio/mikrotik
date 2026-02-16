variable "router_insecure_first_run" {
  description = "Set to true during first provision to prevent terraform to lock it self out"
  type        = bool
  default     = false
}

variable "router_ca_certificate_file" {
  type = string
  default = "certificate/ca.pem"
}

variable "router_admin_ip" {
  type = string
  default = "192.168.88.1"
}

variable "router_admin_username" {
  description = "The username for the admin user on the MikroTek device"
  type        = string
  default     = "admin"
}

variable "router_admin_password" {
  description = "The password for the admin user on the MikroTek device"
  type        = string
  sensitive   = true
  nullable    = false
}

variable "openvpn_admin_account_secret" {
  description = "The password required to login admin to the openvpn server"
  type        = string
  sensitive   = true
  nullable    = false
}
