# 🔧 Scripts

Automation scripts for deployment and setup of the Wine Emulator Platform.

## 📁 Directory Structure

```
scripts/
├── setup/               # Initial setup and configuration scripts
│   └── generate-and-set-secrets.sh    # Generate and configure GitHub secrets
├── deployment/          # Deployment automation scripts
│   └── apply-terraform-secrets.sh     # Apply Terraform outputs to GitHub
└── README.md           # This file
```

## 📜 Script Reference

### Setup Scripts

#### `setup/generate-and-set-secrets.sh`
**Purpose:** Generate and configure all GitHub secrets  
**Usage:** `./scripts/setup/generate-and-set-secrets.sh`

**What it does:**
- Creates Azure Service Principal for GitHub Actions
- Generates secure random secrets (SECRET_KEY, JWT_SECRET, passwords)
- Sets all 29 GitHub secrets in the repository
- Configures ARM64-specific Wine emulator settings

**Prerequisites:**
- Azure CLI (`az`) installed and logged in
- GitHub CLI (`gh`) installed and authenticated
- Permissions to create Service Principals

### Deployment Scripts

#### `deployment/apply-terraform-secrets.sh`
**Purpose:** Extract Terraform outputs and update GitHub secrets  
**Usage:** `./scripts/deployment/apply-terraform-secrets.sh`

**What it does:**
- Extracts secrets from Terraform output
- Updates GitHub secrets with actual Azure resource values
- Sets ACR password, Redis keys, Storage connection strings

**Prerequisites:**
- Terraform applied successfully
- GitHub CLI authenticated
- Run from repository root

## 🚀 Quick Start

### Initial Setup
```bash
# 1. Generate and set all GitHub secrets
./scripts/setup/generate-and-set-secrets.sh

# 2. Deploy infrastructure with Terraform
./terraform-deploy.sh

# 3. Update secrets with Terraform outputs (done automatically by terraform-deploy.sh)
./scripts/deployment/apply-terraform-secrets.sh
```

## 📝 Notes

- All scripts are idempotent (safe to run multiple times)
- Scripts validate prerequisites before execution
- Secrets are never logged or printed to console
- Azure credentials are saved to `/tmp` (not committed to git)

---

**Last Updated:** December 4, 2025
