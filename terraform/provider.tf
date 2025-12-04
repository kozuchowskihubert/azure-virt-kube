terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  # Backend configuration - using local state for initial setup
  # To use remote Azure backend, uncomment and configure:
  # backend "azurerm" {
  #   resource_group_name  = "terraform-state-rg"
  #   storage_account_name = "tfstatewineemulator"
  #   container_name       = "tfstate"
  #   key                  = "wine-emulator.tfstate"
  # }
}

provider "azurerm" {
  features {}
  # Uses Azure CLI authentication by default
}

provider "azuread" {
  # Uses Azure CLI authentication by default
}

provider "random" {
  # No configuration needed
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "k3d-wine-emulator"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    config_context = "k3d-wine-emulator"
  }
}
