terraform {
  required_version = ">= 1.14"

  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
      version = "~>1.99"
    }
  }
}
