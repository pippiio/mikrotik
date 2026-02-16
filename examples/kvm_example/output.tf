data "routeros_system_resource" "system" {

}

output "version" {
  value = data.routeros_system_resource.system.version
}
