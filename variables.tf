variable "resource_group" {}
variable "azure_region" {}

variable "keyvault_name" {}
variable "keyvault_rg" {}
variable "sshkvsecret" {}

variable "aks_vnet_name" {}
variable "vnetcidr" {
  type = list(string)
}

variable "subnetcidr" {
  type = list(string)
}

variable "cluster_name" {}
variable "dns_name" {}
variable "admin_username" {}

variable "agent_pools" {
  type = object({
    name            = string
    count           = number
    vm_size         = string
    os_disk_size_gb = number
  })
}
