data "routeros_system_resource" "system" {

}

output "version" {
  value       = data.routeros_system_resource.system.version
  description = "Shows the version of the MikroTik router"
}
