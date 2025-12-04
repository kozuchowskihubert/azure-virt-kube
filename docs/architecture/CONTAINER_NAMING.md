# 🐳 Container Naming & Configuration

**Wine Emulator Platform - Azure Container Apps**

---

## 📦 Container Applications

### 1. Backend API Container
**Name:** `wine-emulator-backend`  
**Image:** `wineemulatoracr.azurecr.io/backend:latest`  
**Platform:** `linux/amd64`  
**Port:** 8000  
**Resources:**
- CPU: 0.5 cores
- Memory: 1Gi
- Min Replicas: 1
- Max Replicas: 5

**Environment Variables:**
- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string  
- `SECRET_KEY` - Application secret key
- `JWT_SECRET` - JWT signing secret
- `WINE_SERVICE_URL` - Wine service endpoint

**Tags:**
- `latest` - Latest build
- `{sha}` - Git commit SHA
- `v1.0.{run_number}` - Semantic version

---

### 2. Frontend Web Container  
**Name:** `wine-emulator-frontend`  
**Image:** `wineemulatoracr.azurecr.io/frontend:latest`  
**Platform:** `linux/amd64`  
**Port:** 3000  
**Resources:**
- CPU: 0.5 cores
- Memory: 1Gi
- Min Replicas: 1
- Max Replicas: 3

**Environment Variables:**
- `NEXT_PUBLIC_API_URL` - Backend API URL
- `NEXT_PUBLIC_WINE_VNC_URL` - Wine VNC service URL

**Tags:**
- `latest` - Latest build
- `{sha}` - Git commit SHA
- `v1.0.{run_number}` - Semantic version

---

### 3. Wine Service Container (ARM64)
**Name:** `wine-emulator-wine`  
**Image:** `wineemulatoracr.azurecr.io/wine-service:latest`  
**Platform:** `linux/arm64` ⭐  
**Port:** 8080  
**Resources:**
- CPU: 2 cores
- Memory: 4Gi
- Min Replicas: 1
- Max Replicas: 2

**Environment Variables:**
- `WINE_VERSION` - Wine version (8.0)
- `WINEARCH` - Wine architecture (win64)
- `DISPLAY` - X11 display (:0)
- `BOX86_NOBANNER` - Disable Box86 banner (1)
- `BOX64_NOBANNER` - Disable Box64 banner (1)

**ARM64 Translation:**
- ✅ Box86 - x86 32-bit translation
- ✅ Box64 - x86_64 64-bit translation
- ✅ WINEARCH=win64 - Supports both x86 and x64 Windows apps

**Tags:**
- `latest` - Latest build
- `{sha}` - Git commit SHA
- `v1.0.{run_number}` - Semantic version

---

## 🏷️ Image Metadata & Labels

All container images include these OCI labels:

```yaml
org.opencontainers.image.source: https://github.com/kozuchowskihubert/azure-virt-kube
org.opencontainers.image.revision: {github.sha}
org.opencontainers.image.created: {build_timestamp}
org.opencontainers.image.title: wine-emulator-{service}
org.opencontainers.image.description: Wine Emulator Platform - {service}
service.name: {backend|frontend|wine-service}
platform: {linux/amd64|linux/arm64}
```

---

## 🔄 CI/CD Workflow

### Build Stage
```yaml
Matrix Strategy:
  - service: backend
    platform: linux/amd64
    image: backend
  
  - service: frontend
    platform: linux/amd64
    image: frontend
  
  - service: wine-service
    platform: linux/arm64
    image: wine-service
```

### Deployment Sequence
1. **Build & Push** - All images built in parallel
2. **Deploy Backend** - Backend container app updated
3. **Deploy Frontend** - Frontend container app updated (waits for backend)
4. **Deploy Wine Service** - Wine service container app updated
5. **Summary** - Generate deployment report with URLs

---

## �� Container Registry Structure

```
wineemulatoracr.azurecr.io/
├── backend:latest                    (linux/amd64)
│   ├── backend:main-{sha}
│   └── backend:v1.0.{run_number}
│
├── frontend:latest                   (linux/amd64)
│   ├── frontend:main-{sha}
│   └── frontend:v1.0.{run_number}
│
└── wine-service:latest               (linux/arm64)
    ├── wine-service:main-{sha}
    └── wine-service:v1.0.{run_number}
```

---

## 🚀 Deployment Commands

### Manual Deployment

**Backend:**
```bash
az containerapp update \
  --name wine-emulator-backend \
  --resource-group wine-emulator-rg \
  --image wineemulatoracr.azurecr.io/backend:latest \
  --set-env-vars \
    DATABASE_URL="postgresql://..." \
    REDIS_URL="rediss://..." \
    SECRET_KEY="..." \
    JWT_SECRET="..."
```

**Frontend:**
```bash
az containerapp update \
  --name wine-emulator-frontend \
  --resource-group wine-emulator-rg \
  --image wineemulatoracr.azurecr.io/frontend:latest \
  --set-env-vars \
    NEXT_PUBLIC_API_URL="https://wine-emulator-backend...." \
    NEXT_PUBLIC_WINE_VNC_URL="https://wine-emulator-wine...."
```

**Wine Service:**
```bash
az containerapp update \
  --name wine-emulator-wine \
  --resource-group wine-emulator-rg \
  --image wineemulatoracr.azurecr.io/wine-service:latest \
  --set-env-vars \
    WINE_VERSION="8.0" \
    WINEARCH="win64" \
    DISPLAY=":0" \
    BOX86_NOBANNER="1" \
    BOX64_NOBANNER="1"
```

---

## 🔍 Verify Deployments

**List all container apps:**
```bash
az containerapp list \
  --resource-group wine-emulator-rg \
  --output table
```

**Get container app URLs:**
```bash
# Backend
az containerapp show \
  --name wine-emulator-backend \
  --resource-group wine-emulator-rg \
  --query properties.configuration.ingress.fqdn \
  -o tsv

# Frontend  
az containerapp show \
  --name wine-emulator-frontend \
  --resource-group wine-emulator-rg \
  --query properties.configuration.ingress.fqdn \
  -o tsv

# Wine Service
az containerapp show \
  --name wine-emulator-wine \
  --resource-group wine-emulator-rg \
  --query properties.configuration.ingress.fqdn \
  -o tsv
```

**View logs:**
```bash
# Backend logs
az containerapp logs show \
  --name wine-emulator-backend \
  --resource-group wine-emulator-rg \
  --tail 100

# Wine Service logs
az containerapp logs show \
  --name wine-emulator-wine \
  --resource-group wine-emulator-rg \
  --tail 100
```

---

## 📊 Resource Summary

| Container | CPU | Memory | Replicas | Platform | Purpose |
|-----------|-----|--------|----------|----------|---------|
| backend | 0.5 | 1Gi | 1-5 | amd64 | FastAPI REST API |
| frontend | 0.5 | 1Gi | 1-3 | amd64 | Next.js Web UI |
| wine-service | 2.0 | 4Gi | 1-2 | arm64 | Wine + Box86/64 |

**Total Resources (Min):** 3 CPU cores, 6 Gi memory  
**Total Resources (Max):** 11 CPU cores, 18 Gi memory

---

## ✅ Configuration Checklist

- [x] Container names follow naming convention
- [x] All images tagged with version, SHA, and latest
- [x] Environment variables configured per service
- [x] Resource limits set appropriately
- [x] Ingress configured for all services
- [x] ACR authentication configured
- [x] ARM64 platform specified for Wine service
- [x] Box86/Box64 environment variables set
- [x] Auto-scaling configured (min/max replicas)
- [x] OCI labels and metadata applied

---

**Status:** ✅ All containers properly named and configured  
**Last Updated:** December 4, 2025
