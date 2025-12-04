# =============================================================================
# GitHub Secrets Configuration for Wine Emulator Platform
# =============================================================================
#
# This document lists all required GitHub Secrets for the deployment pipeline.
# Add these secrets in GitHub repository settings:
# Settings → Secrets and variables → Actions → New repository secret
#
# =============================================================================

## 🔐 Azure Credentials

### AZURE_CREDENTIALS
**Description:** Service Principal credentials for Azure authentication  
**Format:** JSON  
**Example:**
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "your-client-secret",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

**How to create:**
```bash
az ad sp create-for-rbac \
  --name "wine-emulator-github-actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/wine-emulator-rg \
  --sdk-auth
```

**Usage:** Used by `azure/login@v1` action for authenticating all Azure operations

---

## 🐳 Azure Container Registry (ACR)

### ACR_LOGIN_SERVER
**Description:** Container Registry login server URL  
**Format:** String  
**Example:** `wineemulatoracr123.azurecr.io`  
**How to get:** `az acr show --name YOUR_ACR_NAME --query loginServer -o tsv`

### ACR_USERNAME
**Description:** Container Registry username (admin username)  
**Format:** String  
**Example:** `wineemulatoracr123`  
**How to get:** `az acr credential show --name YOUR_ACR_NAME --query username -o tsv`

### ACR_PASSWORD
**Description:** Container Registry password (admin password)  
**Format:** String (sensitive)  
**How to get:** `az acr credential show --name YOUR_ACR_NAME --query passwords[0].value -o tsv`

### REGISTRY_NAME
**Description:** Container Registry name (without .azurecr.io)  
**Format:** String  
**Example:** `wineemulatoracr123`

---

## 🗄️ Database Credentials

### DATABASE_URL
**Description:** PostgreSQL connection string  
**Format:** PostgreSQL URI  
**Example:** `postgresql://wineadmin:PASSWORD@server.postgres.database.azure.com:5432/wine_emulator`  
**Security:** Full connection string with embedded password

### POSTGRES_HOST
**Description:** PostgreSQL server hostname  
**Format:** String  
**Example:** `wine-emulator-db.postgres.database.azure.com`

### POSTGRES_USER
**Description:** PostgreSQL admin username  
**Format:** String  
**Default:** `wineadmin`

### POSTGRES_PASSWORD
**Description:** PostgreSQL admin password  
**Format:** String (minimum 8 characters, complex)  
**Security:** Must include uppercase, lowercase, numbers, and special characters

### POSTGRES_DB
**Description:** Database name  
**Format:** String  
**Default:** `wine_emulator`

---

## 🔴 Redis Cache

### REDIS_URL
**Description:** Redis connection string with SSL  
**Format:** Redis URI with SSL  
**Example:** `rediss://:PASSWORD@wine-emulator-cache.redis.cache.windows.net:6380`  
**Security:** Uses SSL/TLS (rediss://) with access key

### REDIS_HOST
**Description:** Redis server hostname  
**Format:** String  
**Example:** `wine-emulator-cache.redis.cache.windows.net`

### REDIS_KEY
**Description:** Redis access key (primary)  
**Format:** String (base64 encoded)  
**How to get:** `az redis list-keys --name YOUR_REDIS_NAME --resource-group YOUR_RG --query primaryKey -o tsv`

---

## ☁️ Azure Resources

### AZURE_RESOURCE_GROUP
**Description:** Azure Resource Group name  
**Format:** String  
**Default:** `wine-emulator-rg`

### AZURE_SUBSCRIPTION_ID
**Description:** Azure subscription identifier  
**Format:** GUID  
**Example:** `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`  
**How to get:** `az account show --query id -o tsv`

### AZURE_LOCATION
**Description:** Azure region for resources  
**Format:** String  
**Default:** `eastus`  
**Options:** `eastus`, `westeurope`, `westus2`, etc.

### CONTAINER_ENV
**Description:** Container Apps Environment name  
**Format:** String  
**Default:** `wine-emulator-env`

---

## 💾 Storage

### STORAGE_ACCOUNT_NAME
**Description:** Azure Storage Account name  
**Format:** String (lowercase, alphanumeric only)  
**Example:** `wineemulatorstg123`

### STORAGE_CONNECTION_STRING
**Description:** Storage Account connection string  
**Format:** Connection string  
**Example:** `DefaultEndpointsProtocol=https;AccountName=...;AccountKey=...;EndpointSuffix=core.windows.net`

---

## 📊 Monitoring

### LOG_ANALYTICS_WORKSPACE_ID
**Description:** Log Analytics workspace customer ID  
**Format:** GUID  
**Usage:** Container Apps logging and monitoring

### LOG_ANALYTICS_KEY
**Description:** Log Analytics workspace shared key  
**Format:** Base64 string  
**Usage:** Authenticate log ingestion

---

## 🔑 Application Secrets

### SECRET_KEY
**Description:** Application secret key for session encryption  
**Format:** String (32+ characters, random)  
**Example:** `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6`  
**How to generate:** `openssl rand -hex 32`

### JWT_SECRET
**Description:** JWT token signing secret  
**Format:** String (32+ characters, random)  
**Example:** `z6y5x4w3v2u1t0s9r8q7p6o5n4m3l2k1j0i9h8g7f6e5d4c3b2a1`  
**How to generate:** `openssl rand -hex 32`

---

## 🌐 API Configuration

### NEXT_PUBLIC_API_URL
**Description:** Frontend API endpoint URL  
**Format:** HTTPS URL  
**Example:** `https://wine-emulator-backend.azurecontainerapps.io`  
**Note:** Must be NEXT_PUBLIC_* for Next.js client-side access

### API_URL
**Description:** Internal backend API URL (server-side)  
**Format:** HTTP/HTTPS URL  
**Default:** `http://backend:8000`  
**Usage:** Internal service-to-service communication

---

## 🍷 Wine Emulator Configuration

### WINE_VERSION
**Description:** Wine version to use  
**Format:** Version string  
**Default:** `8.0`

### WINEARCH
**Description:** Wine architecture  
**Format:** String  
**Default:** `win64`  
**Options:** `win32`, `win64`

### DISPLAY
**Description:** X11 display number  
**Format:** String  
**Default:** `:0`

---

# =============================================================================
# Quick Setup Commands
# =============================================================================

## Automated Setup (Recommended)

```bash
# 1. Create all Azure resources
./setup-azure-resources.sh

# 2. Configure GitHub secrets automatically
./setup-github-secrets.sh

# 3. Verify configuration
./verify-secrets.sh
```

## Manual Setup

```bash
# Set a single secret
gh secret set SECRET_NAME -b "secret-value" -R kozuchowskihubert/azure-virt-kube

# Set from file
gh secret set AZURE_CREDENTIALS < azure-credentials.json

# Set all secrets from file
while IFS='=' read -r key value; do
  gh secret set "$key" -b "$value" -R kozuchowskihubert/azure-virt-kube
done < azure-secrets.env
```

## Verification

```bash
# List all secrets
gh secret list -R kozuchowskihubert/azure-virt-kube

# Check secret exists
gh secret list -R kozuchowskihubert/azure-virt-kube | grep SECRET_NAME
```

---

# =============================================================================
# Environment Variables (Public - can be in repository)
# =============================================================================

These are non-sensitive and can be in version control or workflow files:

- `WINE_VERSION=8.0`
- `WINEARCH=win64`
- `DISPLAY=:0`
- `PYTHON_VERSION=3.11`
- `NODE_VERSION=18`
- `AZURE_LOCATION=eastus`

---

# =============================================================================
# Security Best Practices
# =============================================================================

✅ **DO:**
- Rotate secrets regularly (every 90 days)
- Use strong, randomly generated passwords
- Enable Azure Key Vault for production
- Use managed identities when possible
- Audit secret access regularly
- Use different secrets for staging/production

❌ **DON'T:**
- Commit secrets to git
- Share secrets in plain text
- Use weak or predictable passwords
- Reuse secrets across environments
- Log secret values
- Expose secrets in error messages

---

# =============================================================================
# Troubleshooting
# =============================================================================

## Secret Not Working

```bash
# 1. Verify secret is set
gh secret list -R kozuchowskihubert/azure-virt-kube

# 2. Check secret value (redacted)
# Secrets are always masked in logs

# 3. Re-create secret
gh secret delete SECRET_NAME -R kozuchowskihubert/azure-virt-kube
gh secret set SECRET_NAME -b "new-value" -R kozuchowskihubert/azure-virt-kube
```

## Azure Login Fails

```bash
# Test AZURE_CREDENTIALS locally
az login --service-principal \
  --username CLIENT_ID \
  --password CLIENT_SECRET \
  --tenant TENANT_ID

# Verify service principal has correct permissions
az role assignment list --assignee CLIENT_ID
```

## Database Connection Fails

```bash
# Test DATABASE_URL
psql "$DATABASE_URL" -c "SELECT 1;"

# Check firewall rules
az postgres flexible-server firewall-rule list \
  --resource-group wine-emulator-rg \
  --name YOUR_POSTGRES_SERVER
```

---

**Last Updated:** December 4, 2025  
**Repository:** https://github.com/kozuchowskihubert/azure-virt-kube
