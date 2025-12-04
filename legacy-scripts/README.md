# Legacy Scripts

This directory contains legacy shell scripts that were previously in the root directory. These scripts are kept for reference and local development but are not tracked in version control.

## 📜 Scripts Reference

### Build & Local Development
- `build-arm.sh` - Build ARM64 Docker images
- `start-local.sh` - Start local development environment
- `setup-docker-path.sh` - Configure Docker path

### Deployment (Legacy)
- `deploy.sh` - Legacy deployment script
- `deploy-azure.sh` - Legacy Azure deployment
- `first-deploy.sh` - First-time deployment wizard
- `terraform-deploy.sh` - Terraform deployment automation

### Setup (Legacy)
- `init.sh` - Project initialization
- `setup-azure-resources.sh` - Azure resource setup
- `setup-github-secrets.sh` - GitHub secrets configuration
- `verify-secrets.sh` - Verify secrets configuration

## ⚠️ Important Notes

- **These scripts are not tracked in git** (excluded via `.gitignore`)
- **For new automation**, use the organized `scripts/` directory:
  - `scripts/setup/` - Setup and configuration
  - `scripts/deployment/` - Deployment automation

## 🔄 Migration Status

Most functionality has been migrated to the organized `scripts/` directory:

| Legacy Script | New Location | Status |
|--------------|--------------|--------|
| setup-github-secrets.sh | scripts/setup/generate-and-set-secrets.sh | ✅ Migrated |
| (Terraform integration) | scripts/deployment/apply-terraform-secrets.sh | ✅ Migrated |
| - | scripts/setup/configure-container-names.sh | ✅ New |

## 📚 Recommended Approach

For new deployments, use:
1. `scripts/setup/configure-container-names.sh` - Configure names
2. `scripts/setup/generate-and-set-secrets.sh` - Setup secrets
3. Terraform via VS Code or command line
4. GitHub Actions for deployment

---

**Note:** These legacy scripts remain available for local development and troubleshooting but are not the recommended deployment method.
