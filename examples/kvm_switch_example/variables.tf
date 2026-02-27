variable "device_insecure_first_run" {
  description = "Set to true during first provision to prevent terraform to lock it self out"
  type        = bool
  default     = false
}

variable "device_ca_certificate_file" {
  description = "Path to CA certificate used to verify the connection to the router"
  type        = string
  default     = "certificate/ca.pem"
}

variable "device_admin_ip" {
  description = "The IP of the router in the admin network"
  type        = string
  default     = "192.168.88.1"
}

variable "device_admin_username" {
  description = "The username for the admin user on the MikroTek device"
  type        = string
  default     = "admin"
}

variable "device_admin_password" {
  description = "The password for the admin user on the MikroTek device"
  type        = string
  sensitive   = true
  nullable    = false
}
