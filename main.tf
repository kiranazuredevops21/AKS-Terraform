############################
# RESOURCE GROUP
############################

resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group
  location = var.azure_region
}

############################
# KEY VAULT (Existing)
############################

data "azurerm_key_vault" "azure_vault" {
  name                = var.keyvault_name
  resource_group_name = var.keyvault_rg
}

############################
# RBAC FOR TERRAFORM TO READ SECRETS
############################

resource "azurerm_role_assignment" "kv_secret_user" {
  scope                = data.azurerm_key_vault.azure_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_client_config.current.object_id
}

############################
# READ SSH PUBLIC KEY FROM KEYVAULT
############################

data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = var.sshkvsecret
  key_vault_id = data.azurerm_key_vault.azure_vault.id

  depends_on = [
    azurerm_role_assignment.kv_secret_user
  ]
}

############################
# VIRTUAL NETWORK
############################

resource "azurerm_virtual_network" "aks_vnet" {
  name                = var.aks_vnet_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  address_space       = var.vnetcidr
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = var.subnetcidr
}

############################
# AKS CLUSTER (MODERN - MANAGED IDENTITY)
############################

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = var.dns_name

  default_node_pool {
    name            = var.agent_pools.name
    node_count      = var.agent_pools.count
    vm_size         = var.agent_pools.vm_size
    os_disk_size_gb = var.agent_pools.os_disk_size_gb
    vnet_subnet_id  = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = data.azurerm_key_vault_secret.ssh_public_key.value
    }
  }

  role_based_access_control_enabled = true

  network_profile {
    network_plugin = "azure"
  }

  tags = {
    Environment = "Demo"
  }
}
