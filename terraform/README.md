# Terraform Deployment Guide

Complete infrastructure as code setup for Wine Emulator Platform.

## 🎯 Quick Start

```bash
# One command to deploy everything
./terraform-deploy.sh
```

This will:
1. ✅ Check prerequisites (Terraform, Azure CLI, GitHub CLI)
2. ✅ Initialize Terraform
3. ✅ Plan infrastructure
4. ✅ Create all Azure resources
5. ✅ Configure GitHub secrets automatically
6. ✅ Output deployment URLs

## 📦 Resources Created

- **Resource Group** - Container for all resources
- **Container Registry (ACR)** - Docker image storage
- **PostgreSQL Flexible Server** - Database (B_Standard_B1ms)
- **Redis Cache** - Session storage (Basic C0)
- **Storage Account** - File storage
- **Container Apps Environment** - Serverless container hosting
- **Log Analytics Workspace** - Centralized logging
- **Service Principal** - GitHub Actions authentication

## 🔧 Manual Steps

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Plan Infrastructure

```bash
terraform plan -out=tfplan
```

### 3. Apply Configuration

```bash
terraform apply tfplan
```

### 4. Extract Secrets

```bash
# View all secrets
terraform output -json github_secrets_json | jq

# Save to file
terraform output -json github_secrets_json > ../github-secrets.json
```

### 5. Set GitHub Secrets

```bash
cd ..
./scripts/apply-terraform-secrets.sh
```

## 📊 Terraform Outputs

```bash
# View all outputs
terraform output

# Specific outputs
terraform output resource_group_name
terraform output container_registry_login_server
terraform output database_host
terraform output redis_host

# Deployment summary
terraform output deployment_summary
```

## 🔐 GitHub Secrets Configuration

Terraform automatically outputs all required secrets:

- `AZURE_CREDENTIALS` - Service Principal JSON
- `ACR_LOGIN_SERVER`, `ACR_USERNAME`, `ACR_PASSWORD`
- `DATABASE_URL`, `POSTGRES_*` credentials
- `REDIS_URL`, `REDIS_HOST`, `REDIS_KEY`
- `AZURE_RESOURCE_GROUP`, `CONTAINER_ENV`
- `SECRET_KEY`, `JWT_SECRET` (auto-generated)

## 🏗️ Architecture

```
Terraform Configuration
├── provider.tf          # Provider configuration (azurerm, azuread, random)
├── variables.tf         # Input variables
├── main.tf             # Kubernetes resources (if using)
├── azure-resources.tf  # Azure Container Apps, PostgreSQL, Redis
├── github-secrets.tf   # Service Principal & secrets
└── outputs.tf          # All outputs including GitHub secrets
```

## 🔄 Update Infrastructure

```bash
# Modify variables in terraform.tfvars or variables.tf
# Then apply changes
cd terraform
terraform plan
terraform apply
```

## 🗑️ Cleanup

```bash
# Destroy all resources
cd terraform
terraform destroy

# Or delete resource group
az group delete --name wine-emulator-rg --yes
```

## 💰 Cost Estimate

| Resource | Tier | Monthly Cost (USD) |
|----------|------|-------------------|
| Container Registry | Basic | ~$5 |
| PostgreSQL | B_Standard_B1ms | ~$15 |
| Redis | Basic C0 | ~$16 |
| Container Apps | Consumption | ~$10-50 |
| Storage | Standard LRS | ~$2 |
| Log Analytics | Pay-as-you-go | ~$5 |
| **Total** | | **~$53-93/month** |

## 🔧 Troubleshooting

### Terraform Init Fails

```bash
# Clear cache
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
```

### Azure Authentication Issues

```bash
# Re-login to Azure
az logout
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_NAME"
```

### Service Principal Creation Fails

Ensure you have permissions to create service principals:

```bash
# Check your role
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

You need **Owner** or **User Access Administrator** role.

### GitHub Secrets Not Set

```bash
# Manual setup
cd scripts
./apply-terraform-secrets.sh

# Or set individually
gh secret set SECRET_NAME -b "value" -R kozuchowskihubert/azure-virt-kube
```

## 📚 Terraform State

State is stored locally by default. For team collaboration, configure remote state:

```hcl
# In provider.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatestorage"
    container_name       = "tfstate"
    key                  = "wine-emulator.tfstate"
  }
}
```

Then:

```bash
terraform init -migrate-state
```

## 🔐 Security Best Practices

- ✅ Store `.tfstate` securely (contains sensitive data)
- ✅ Use Azure Key Vault for production secrets
- ✅ Rotate Service Principal credentials every 90 days
- ✅ Enable managed identities where possible
- ✅ Use separate workspaces for staging/production

## 📖 Related Documentation

- [Azure Container Apps Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app)
- [Azure AD Terraform Provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
- [GitHub Secrets Management](../GITHUB_SECRETS.md)

---

**Ready to deploy?** Run `./terraform-deploy.sh` 🚀
