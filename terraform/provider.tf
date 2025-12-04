terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
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

  backend "azurerm" {
    # This will use existing Azure profile
    # Configuration can be provided via environment variables:
    # ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET
    # or via Azure CLI authentication
  }
}

provider "azurerm" {
  features {}
  # Uses Azure CLI authentication by default
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
