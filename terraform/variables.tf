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
  default     = "wine-emulator"
}

variable "app_version" {
  description = "Version of the Wine emulator application"
  type        = string
  default     = "1.0.0"
}

variable "replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

# Container Image Configuration
variable "container_image" {
  description = "Container image for Wine emulator (e.g., wine-staging or custom image)"
  type        = string
  default     = "scottyhardy/docker-wine:latest"
}

# Kubernetes Configuration
variable "namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "wine-emulator"
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
