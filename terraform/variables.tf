# Azure Configuration
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "wine-emulator-rg"
}

# Application Configuration
variable "app_name" {
  description = "Name of the Wine emulator application"
  type        = string
  default     = "wine-emulator-platform"
}

variable "app_version" {
  description = "Version of the Wine emulator application"
  type        = string
  default     = "1.0.0"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Deployment Configuration
variable "deployment_target" {
  description = "Deployment target: app-service, kubernetes, or both"
  type        = string
  default     = "both"
  validation {
    condition     = contains(["app-service", "kubernetes", "both"], var.deployment_target)
    error_message = "Deployment target must be one of: app-service, kubernetes, both."
  }
}

# Container Image Configuration
variable "wine_gaming_image" {
  description = "Container image for Wine gaming service"
  type        = string
  default     = ""
}

variable "backend_api_image" {
  description = "Container image for Backend API service"
  type        = string
  default     = ""
}

variable "frontend_web_image" {
  description = "Container image for Frontend Web service"
  type        = string
  default     = ""
}

variable "container_image" {
  description = "Fallback container image for Wine emulator"
  type        = string
  default     = "scottyhardy/docker-wine:latest"
}

# Kubernetes Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.28.0"
}

variable "aks_node_count" {
  description = "Initial number of nodes in AKS cluster"
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D4s_v3"  # 4 vCPU, 16 GB RAM - good for Wine gaming
}

variable "aks_min_nodes" {
  description = "Minimum number of nodes for AKS auto-scaling"
  type        = number
  default     = 1
}

variable "aks_max_nodes" {
  description = "Maximum number of nodes for AKS auto-scaling"
  type        = number
  default     = 5
}

variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "wine-emulator"
}

variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "LoadBalancer"
}

variable "service_port" {
  description = "Service port for Wine emulator web interface"
  type        = number
  default     = 8080
}

# Storage Configuration
variable "storage_size" {
  description = "Size of persistent volume for Wine prefix"
  type        = string
  default     = "10Gi"
}

# Azure Storage Account for Terraform State
variable "state_storage_account_name" {
  description = "Azure Storage Account name for Terraform state"
  type        = string
  default     = ""
}

variable "state_container_name" {
  description = "Azure Storage Container name for Terraform state"
  type        = string
  default     = "tfstate"
}

variable "state_key" {
  description = "Key for Terraform state file"
  type        = string
  default     = "wine-emulator.tfstate"
}

# Tags
variable "tags" {
  description = "Tags to apply to Azure resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "wine-emulator"
    ManagedBy   = "terraform"
  }
}
