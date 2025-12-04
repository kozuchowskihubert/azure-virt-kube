# 🍷 Wine Emulator Platform

> **A comprehensive low-code/no-code platform for running Windows x86/x64 applications through Wine emulator with ARM64 support, featuring web-based access, workflow builder, and full Azure cloud deployment.**

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-blue)](https://kubernetes.io/)
[![Azure](https://img.shields.io/badge/Azure-Compatible-0078D4)](https://azure.microsoft.com/)
[![ARM64](https://img.shields.io/badge/ARM64-Supported-green)](https://www.arm.com/)
[![Next.js](https://img.shields.io/badge/Next.js-14-black)](https://nextjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Latest-009688)](https://fastapi.tiangolo.com/)

## ✨ Features

- 🍷 **Wine Emulation** - Run Windows x86/x64 applications seamlessly
- 💻 **ARM64 Support** - Native ARM64 builds with x86 to ARM64 translation via Wine
- 🌐 **x86 to x64 Translation** - Automatic architecture translation for legacy apps
- 🖥️ **Web-based VNC** - Access applications through your browser via noVNC
- 🎨 **Low-Code Builder** - Visual workflow creator with drag-and-drop interface
- 📦 **Application Management** - Easy upload, configure, and launch Windows apps
- 🔄 **Session Management** - Multi-user support with isolated sessions
- 📊 **Real-time Monitoring** - Live status updates and health checks
- ☁️ **Cloud-Ready** - Deploy to Azure with one command
- 🚀 **CI/CD Pipeline** - Automated testing and deployment via GitHub Actions

## 🏗️ Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Next.js 14    │────▶│   FastAPI API    │────▶│  Wine Service   │
│   Frontend      │     │   Backend        │     │  (x86/x64)      │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        │                        │                         │
        │                        ▼                         ▼
        │               ┌──────────────────┐     ┌─────────────────┐
        │               │   PostgreSQL     │     │   Xvfb + VNC    │
        │               │   Database       │     │   Display       │
        │               └──────────────────┘     └─────────────────┘
        │                        │
        ▼                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Docker / Kubernetes / Azure                   │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

#### For Local Development (x64):
```bash
# macOS
brew install docker docker-compose kubectl helm terraform

# Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y docker.io docker-compose kubectl
```

#### For ARM64 Systems (Apple Silicon, Raspberry Pi, etc.):
```bash
# macOS (Apple Silicon)
brew install docker docker-compose kubectl helm terraform

# The platform automatically detects ARM64 and uses optimized builds
```

### 1. Clone and Initialize

```bash
# Clone the repository
git clone https://github.com/kozuchowskihubert/azure-moto.git
cd azure-virt-kube

# Make scripts executable
chmod +x init.sh build-arm.sh deploy.sh deploy-azure.sh start-local.sh

# Initialize the project (creates .env files, directories)
./init.sh
```

### 2. Start Local Development

#### Option A: Docker Compose (Recommended)
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

#### Option B: Using Make
```bash
# Start development environment
make dev

# Build and start
make dev-build

# Stop services
make stop

# Clean up (removes volumes too)
make clean
```

#### Option C: Quick Start Script
```bash
./start-local.sh
```

### 3. Access the Application

Once services are running:

- **Frontend UI**: http://localhost:3000
- **Backend API**: http://localhost:8000/docs (Swagger UI)
- **Wine VNC**: http://localhost:8080/vnc.html (noVNC web interface)
- **PostgreSQL**: localhost:5432 (admin/changeme123)
- **Redis**: localhost:6379

## 🍎 ARM64 Support (Apple Silicon / ARM Devices)

### Building for ARM64

```bash
# Build ARM64 optimized images
./build-arm.sh

# Or build specific service for ARM64
docker buildx build --platform linux/arm64 \
  -f wine-service/Dockerfile.arm64 \
  -t wine-emulator-arm64:latest .
```

### Multi-Architecture Support

The platform automatically detects your architecture:

- **x86_64**: Uses standard Wine with x86 to x64 translation
- **ARM64**: Uses Wine ARM64 builds with box86/box64 for x86 translation
- **Multi-arch**: Docker Buildx creates images for both platforms

### ARM64 Features

- Native ARM64 performance
- x86 Windows apps via box86/box64 emulation
- Optimized Wine builds for ARM
- Full VNC support on ARM devices

## ☁️ Azure Deployment

### Prerequisites for Azure

1. **Azure CLI**:
```bash
# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login
```

2. **Terraform** (already installed in quick start)

3. **Azure Subscription** with permissions to create:
   - Azure Container Apps
   - Azure Database for PostgreSQL
   - Azure Container Registry
   - Virtual Networks

### Deploy to Azure

#### Option 1: Automated Deployment Script

```bash
# Configure your Azure settings
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy everything to Azure
./deploy-azure.sh
```

#### Option 2: Manual Terraform Deployment

```bash
cd terraform

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy to Azure
terraform apply

# Get outputs (URLs, connection strings)
terraform output
```

### Azure Architecture

The deployment creates:

1. **Azure Container Apps Environment** - Serverless container hosting
2. **PostgreSQL Flexible Server** - Managed database
3. **Azure Container Registry** - Private Docker registry
4. **Virtual Network** - Isolated networking
5. **Application Gateway** (optional) - Load balancing and SSL

### Azure x86 to x64 Translation

Azure Container Apps support both x86 and x64 containers:

- **x64 Workloads**: Run natively on Azure infrastructure
- **x86 Applications**: Automatically translated to x64 via Wine
- **ARM64 Support**: Available in select Azure regions with ARM-based nodes

## 🎯 x86 to x64 Translation Details

### How It Works

1. **Wine Translation Layer**:
   - Wine provides Windows API compatibility
   - Automatically handles x86 to x64 architecture translation
   - Supports both 32-bit (x86) and 64-bit (x64) Windows applications

2. **Architecture Detection**:
   ```python
   # Wine automatically detects application architecture
   WINEARCH=win64  # Supports both x86 and x64
   WINEARCH=win32  # Only x86 (32-bit)
   ```

3. **Supported Scenarios**:
   - ✅ x86 (32-bit) apps on x64 systems
   - ✅ x64 (64-bit) apps on x64 systems
   - ✅ Mixed x86/x64 applications
   - ✅ Legacy Windows applications (Windows XP, 7, 10, 11)

### Configuration

Set Wine architecture in application settings:

```bash
# For x86 (32-bit) only applications
WINEARCH=win32 wine application.exe

# For x64 or mixed applications (default)
WINEARCH=win64 wine application.exe
```

## 🎨 Using the Platform

### 1. Emulator View

- View Wine emulator status and health
- Access remote desktop via VNC in browser
- Execute Windows applications
- Take screenshots
- Restart Wine environment

### 2. Application Management

- Upload Windows executables (.exe, .msi)
- Configure Wine settings per application
- Save application profiles
- Launch applications with one click

### 3. Low-Code Builder

- Drag-and-drop workflow designer
- UI Components: Buttons, inputs, forms
- Logic Components: Conditionals, loops, API calls
- Wine Actions: Execute apps, install software, configure Wine

### Workflow Example

```javascript
// Create a workflow that:
// 1. Uploads a file
// 2. Executes Windows application with the file
// 3. Downloads the result

{
  "components": [
    { "type": "file_upload", "name": "Upload Input" },
    { "type": "wine_execute", "name": "Run App", "config": { "exe": "converter.exe" } },
    { "type": "file_download", "name": "Download Result" }
  ]
}
```

## 🐳 Docker Services

### Service Overview

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 3000 | Next.js React application |
| Backend | 8000 | FastAPI Python API |
| Wine Emulator | 8080, 5900 | Wine + VNC service |
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache and sessions |
| Nginx | 80, 443 | Reverse proxy |

### Environment Variables

#### Backend (.env)
```bash
DATABASE_URL=postgresql://admin:changeme123@postgres:5432/wine_emulator
REDIS_URL=redis://redis:6379
WINE_SERVICE_URL=http://wine-emulator:8080
SECRET_KEY=your-secret-key-change-in-production
DEBUG=false
```

#### Frontend (.env.local)
```bash
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_WINE_VNC_URL=http://localhost:8080
```

## ☸️ Kubernetes Deployment

### Local Kubernetes (k3d)

```bash
# Create k3d cluster
k3d cluster create wine-emulator \
  --api-port 6550 \
  --port 8080:80@loadbalancer

# Deploy with kubectl
kubectl apply -f k8s/

# Check status
kubectl get pods -n wine-emulator
```

### Using Helm

```bash
# Install with Helm
helm install wine-emulator ./helm/wine-emulator \
  --namespace wine-emulator \
  --create-namespace

# Upgrade
helm upgrade wine-emulator ./helm/wine-emulator

# Uninstall
helm uninstall wine-emulator --namespace wine-emulator
```

### Production Kubernetes

```bash
# For production (AKS, EKS, GKE)
# 1. Update values in helm/wine-emulator/values.yaml
# 2. Configure ingress with your domain
# 3. Deploy

helm install wine-emulator ./helm/wine-emulator \
  --namespace wine-emulator \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=wine.yourdomain.com
```

## 🔧 Development

### Backend Development

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Development

```bash
cd frontend

# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Run production build
npm start
```

### Database Migrations

```bash
cd backend

# Create migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

## 📊 Monitoring and Logs

### Docker Compose Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f wine-emulator

# Last 100 lines
docker-compose logs --tail=100
```

### Kubernetes Logs

```bash
# Get pod logs
kubectl logs -f deployment/backend -n wine-emulator

# Multiple pods
kubectl logs -f -l app=backend -n wine-emulator

# Previous container logs
kubectl logs deployment/backend --previous -n wine-emulator
```

## 🔒 Security

### Production Checklist

- [ ] Change default database password
- [ ] Generate strong SECRET_KEY
- [ ] Enable HTTPS/SSL
- [ ] Configure firewall rules
- [ ] Set up authentication (OAuth2, JWT)
- [ ] Enable CORS only for trusted domains
- [ ] Use Azure Key Vault for secrets
- [ ] Enable network policies in Kubernetes
- [ ] Set resource limits
- [ ] Enable logging and monitoring

### Environment Security

```bash
# Generate secure secret key
openssl rand -hex 32

# Update .env files with production values
# Never commit .env files to git!
```

## 🧪 Testing

### Run Backend Tests

```bash
cd backend
pytest --cov=. --cov-report=html
```

### Run Frontend Tests

```bash
cd frontend
npm run test
npm run test:coverage
```

### Integration Tests

```bash
# Test full stack
docker-compose up -d
npm run test:e2e
```

## 📚 Documentation

- [Project Overview](PROJECT_OVERVIEW.md) - Detailed project documentation
- [System Documentation](DOCUMENTATION.md) - Architecture and technical details
- [Quick Start Guide](QUICKSTART.md) - Step-by-step setup
- [API Documentation](http://localhost:8000/docs) - Interactive Swagger UI
- [Wine Documentation](https://www.winehq.org/documentation) - Wine official docs

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Wine Project](https://www.winehq.org/) - Windows compatibility layer
- [noVNC](https://novnc.com/) - VNC client for web browsers
- [FastAPI](https://fastapi.tiangolo.com/) - Modern Python web framework
- [Next.js](https://nextjs.org/) - React framework
- [Azure](https://azure.microsoft.com/) - Cloud platform

## 🐛 Troubleshooting

### Common Issues

**Issue: Services won't start**
```bash
# Check Docker is running
docker ps

# Rebuild containers
docker-compose down -v
docker-compose up --build
```

**Issue: VNC not connecting**
```bash
# Check wine-emulator service
docker-compose logs wine-emulator

# Verify port is open
curl http://localhost:8080/health
```

**Issue: Database connection error**
```bash
# Wait for PostgreSQL to be ready
docker-compose up -d postgres
docker-compose logs postgres

# Check DATABASE_URL in backend/.env
```

**Issue: ARM64 build fails**
```bash
# Ensure buildx is enabled
docker buildx version

# Create builder
docker buildx create --use

# Try build again
./build-arm.sh
```

## 📞 Support

- GitHub Issues: [Create an issue](https://github.com/kozuchowskihubert/azure-moto/issues)
- Discussions: [GitHub Discussions](https://github.com/kozuchowskihubert/azure-moto/discussions)

## 🗺️ Roadmap

- [x] Basic Wine emulation
- [x] Web-based VNC access
- [x] Low-code workflow builder
- [x] Docker Compose deployment
- [x] Kubernetes support
- [x] ARM64 support
- [x] Azure deployment
- [ ] Multi-tenancy support
- [ ] Advanced workflow automation
- [ ] GPU acceleration support
- [ ] Mobile app
- [ ] Marketplace for workflows

---

**Made with ❤️ by Hubert Kozuchowski**

*Deploy Windows applications anywhere, on any architecture!*
