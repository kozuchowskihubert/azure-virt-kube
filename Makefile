.PHONY: help dev build deploy clean

# Default target
help:
	@echo "Wine Emulator Platform - Available Commands"
	@echo "==========================================="
	@echo "Local Development:"
	@echo "  make dev              - Start all services with Docker Compose"
	@echo "  make dev-build        - Build and start all services"
	@echo "  make logs             - View logs from all services"
	@echo "  make stop             - Stop all services"
	@echo "  make clean            - Stop and remove all containers and volumes"
	@echo ""
	@echo "Kubernetes (Local):"
	@echo "  make k8s-deploy       - Deploy to local Kubernetes cluster"
	@echo "  make k8s-delete       - Delete from Kubernetes cluster"
	@echo "  make k8s-status       - Check deployment status"
	@echo ""
	@echo "Helm:"
	@echo "  make helm-install     - Install with Helm"
	@echo "  make helm-upgrade     - Upgrade Helm release"
	@echo "  make helm-uninstall   - Uninstall Helm release"
	@echo ""
	@echo "Azure Deployment:"
	@echo "  make azure-init       - Initialize Terraform"
	@echo "  make azure-plan       - Plan Azure infrastructure"
	@echo "  make azure-deploy     - Deploy to Azure"
	@echo "  make azure-destroy    - Destroy Azure infrastructure"
	@echo ""
	@echo "Testing:"
	@echo "  make test-backend     - Run backend tests"
	@echo "  make test-frontend    - Run frontend tests"

# Local Development
dev:
	docker-compose up

dev-build:
	docker-compose up --build

logs:
	docker-compose logs -f

stop:
	docker-compose down

clean:
	docker-compose down -v
	rm -rf backend/__pycache__
	rm -rf frontend/.next
	rm -rf frontend/node_modules

# Kubernetes
k8s-deploy:
	kubectl apply -f k8s/

k8s-delete:
	kubectl delete -f k8s/

k8s-status:
	kubectl get all -n wine-emulator

# Helm
helm-install:
	helm install wine-emulator ./helm/wine-emulator \
		--namespace wine-emulator \
		--create-namespace

helm-upgrade:
	helm upgrade wine-emulator ./helm/wine-emulator \
		--namespace wine-emulator

helm-uninstall:
	helm uninstall wine-emulator --namespace wine-emulator

# Azure
azure-init:
	cd terraform && terraform init

azure-plan:
	cd terraform && terraform plan

azure-deploy:
	cd terraform && terraform apply

azure-destroy:
	cd terraform && terraform destroy

# Testing
test-backend:
	cd backend && python -m pytest

test-frontend:
	cd frontend && npm test

# Build Docker images
build-backend:
	docker build -t wine-emulator-backend:latest -f backend/Dockerfile .

build-frontend:
	docker build -t wine-emulator-frontend:latest -f frontend/Dockerfile .

build-wine:
	docker build -t wine-emulator-wine:latest -f wine-service/Dockerfile .

build-all: build-backend build-frontend build-wine
	@echo "All images built successfully"
