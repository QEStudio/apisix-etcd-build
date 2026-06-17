.PHONY: all build build-apisix build-etcd build-all start stop restart logs clean test push pull status help

# Default versions - latest stable
APISIX_VERSION ?= 3.16.0
ETCD_VERSION ?= v3.6.12
OPENRESTY_VERSION ?= 1.31.1.1

# Docker compose file
COMPOSE_FILE ?= docker-compose.yml

all: build

# Build all images
build: build-all
	@echo "All images built successfully!"

# Build all images
build-all: build-etcd build-apisix
	@echo "All images built successfully!"

# Build etcd image
build-etcd:
	@echo "Building etcd image..."
	docker build \
		--build-arg ETCD_VERSION=$(ETCD_VERSION) \
		-t apisix-etcd:$(ETCD_VERSION) \
		-t apisix-etcd:latest \
		-f docker/etcd/Dockerfile \
		docker/etcd

# Build APISIX image
build-apisix:
	@echo "Building APISIX image..."
	docker build \
		--build-arg APISIX_VERSION=$(APISIX_VERSION) \
		--build-arg OPENRESTY_VERSION=$(OPENRESTY_VERSION) \
		-t apisix-gateway:$(APISIX_VERSION) \
		-t apisix-gateway:latest \
		-f docker/apisix/Dockerfile \
		docker/apisix

# Build for multiple architectures (requires Docker Buildx)
buildx:
	@echo "Building multi-arch images (amd64 + arm64)..."
	docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--build-arg APISIX_VERSION=$(APISIX_VERSION) \
		--build-arg ETCD_VERSION=$(ETCD_VERSION) \
		--build-arg OPENRESTY_VERSION=$(OPENRESTY_VERSION) \
		-t apisix-gateway:$(APISIX_VERSION) \
		-t apisix-gateway:latest \
		-f docker/apisix/Dockerfile \
		docker/apisix

# Start services
start:
	@echo "Starting services..."
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "Services started. Use 'make logs' to view logs."

# Stop services
stop:
	@echo "Stopping services..."
	docker compose -f $(COMPOSE_FILE) down

# Restart services
restart: stop start

# View logs
logs:
	docker compose -f $(COMPOSE_FILE) logs -f

# Clean up
clean:
	docker compose -f $(COMPOSE_FILE) down -v
	docker rmi apisix-etcd:$(ETCD_VERSION) apisix-etcd:latest 2>/dev/null || true
	docker rmi apisix-gateway:$(APISIX_VERSION) apisix-gateway:latest 2>/dev/null || true

# Run tests
test:
	@echo "Running tests..."
	@echo "Testing etcd..."
	docker exec apisix-etcd etcdctl endpoint health
	@echo "Testing APISIX..."
	curl -f http://127.0.0.1:9090/v1/health
	@echo "All tests passed!"

# Run integration tests (requires services running)
test-integration:
	@echo "Running integration tests..."
	./test-integration.sh

# Push images to registry
push:
	@echo "Pushing images to registry..."
	docker push apisix-etcd:$(ETCD_VERSION)
	docker push apisix-gateway:$(APISIX_VERSION)

# Pull images from registry
pull:
	docker pull apisix-etcd:$(ETCD_VERSION)
	docker pull apisix-gateway:$(APISIX_VERSION)

# Show status
status:
	@echo "Service Status:"
	docker compose -f $(COMPOSE_FILE) ps

# Show current versions
version:
	@echo "Current versions:"
	@echo "  APISIX:        $(APISIX_VERSION)"
	@echo "  etcd:          $(ETCD_VERSION)"
	@echo "  OpenResty:     $(OPENRESTY_VERSION)"

# Help
help:
	@echo "Available targets:"
	@echo "  make build          - Build all Docker images"
	@echo "  make build-apisix   - Build APISIX image only"
	@echo "  make build-etcd     - Build etcd image only"
	@echo "  make buildx         - Build multi-arch images (amd64+arm64)"
	@echo "  make start          - Start services"
	@echo "  make stop           - Stop services"
	@echo "  make restart        - Restart services"
	@echo "  make logs           - View service logs"
	@echo "  make test           - Run basic tests"
	@echo "  make test-integration - Run comprehensive integration tests"
	@echo "  make clean          - Remove containers, volumes, and images"
	@echo "  make status         - Show service status"
	@echo "  make version        - Show current component versions"
	@echo ""
	@echo "Variables:"
	@echo "  APISIX_VERSION=$(APISIX_VERSION)"
	@echo "  ETCD_VERSION=$(ETCD_VERSION)"
	@echo "  OPENRESTY_VERSION=$(OPENRESTY_VERSION)"
