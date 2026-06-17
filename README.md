# APISIX + etcd Build

[![Build Status](https://github.com/qingzhenzi/apisix-etcd-build/actions/workflows/build.yml/badge.svg)](https://github.com/qingzhenzi/apisix-etcd-build/actions/workflows/build.yml)

Build and run [Apache APISIX](https://apisix.apache.org/) API Gateway with [etcd](https://etcd.io/) distributed key-value store. Produces portable packages with bundled shared libraries.

## Features

- Build from source - APISIX and etcd compiled from official source code
- Multi-architecture - Supports `linux/amd64` and `linux/arm64`
- ARM native CI - Built on GitHub's native ARM runners
- Docker Compose - One-command deployment
- Portable bundle - Combined etcd + APISIX package with start/stop scripts
- GLIBC >= 2.34 required - Compatible with Ubuntu 22.04+, Debian 12+. **Not** compatible with Ubuntu 20.04, Debian 11, CentOS 7, or older systems.

## Current Versions

| Component | Version |
|-----------|---------|
| Apache APISIX | 3.16.0 |
| etcd | v3.6.12 |
| OpenResty | 1.31.1.1 |
| Base Image | Debian Bookworm |

## Quick Start

### Docker Compose

```bash
git clone https://github.com/qingzhenzi/apisix-etcd-build.git
cd apisix-etcd-build

# Build and start
docker compose up -d

# Check status
docker compose ps
```

### Portable Bundle

Download the bundle artifact from CI or build it:

```bash
# Extract
tar -xzf apisix-etcd-3.16.0-3.6.12-linux-amd64.tar.gz
cd apisix-etcd-3.16.0-3.6.12-linux-amd64

# Start both services
./start.sh

# Stop both services
./stop.sh

# Or manage individually
./etcd/start.sh
./apisix/start.sh
```

## Endpoints

| Service | Endpoint | Description |
|---------|----------|-------------|
| APISIX HTTP | `http://localhost:9080` | API Gateway HTTP |
| APISIX HTTPS | `https://localhost:9443` | API Gateway HTTPS |
| APISIX Admin | `http://localhost:9090` | Admin API |
| etcd Client | `http://localhost:2379` | etcd client endpoint |

Default Admin API Key: `edd1c9f034335f136f87ad84b625c8f1`

## Usage

### Build Images

```bash
make build              # Build both images
make build-etcd         # Build etcd only
make build-apisix       # Build APISIX only
make buildx             # Multi-arch build (requires Buildx)
```

### Manage Services

```bash
make start              # Start services
make stop               # Stop services
make logs               # View logs
make clean              # Remove containers, volumes, images
make status             # Show service status
```

### Testing

```bash
make test               # Basic health checks
./test.sh               # Basic health checks (script)
```

## GitHub Actions CI

The CI pipeline produces portable packages for both amd64 and arm64 on every push.

| Job | Description | Runner |
|-----|-------------|--------|
| `build-etcd` | Build etcd from source | amd64 + arm64 |
| `build-apisix` | Build APISIX + OpenResty, bundle libs | amd64 + arm64 |
| `test-etcd` | Test etcd binary health | amd64 |
| `test-apisix` | Test APISIX package | amd64 |
| `test-cross-distro` | Compatibility on Ubuntu 22.04 | amd64 |
| `package-bundle` | Combine etcd + APISIX + scripts into single tarball | amd64 + arm64 |
| `create-release` | Release assets on tag push | ubuntu-latest |

### Artifacts

Each run produces these downloadable artifacts:

- `etcd-v3.6.12-linux-{amd64,arm64}.tar.gz` - Standalone etcd binaries
- `apisix-3.16.0-linux-{amd64,arm64}.tar.gz` - Standalone APISIX package
- `apisix-etcd-bundle-3.16.0-linux-{amd64,arm64}.tar.gz` - Combined bundle with management scripts

### Version Matrix

Trigger manually to test multiple versions:
[`version-matrix.yml`](.github/workflows/version-matrix.yml)

## Project Structure

```
apisix-etcd-build/
├── .github/workflows/
│   ├── build.yml              # Main CI pipeline
│   └── version-matrix.yml     # Multi-version test workflow
├── bundle/
│   ├── start.sh               # Combined start script
│   ├── stop.sh                # Combined stop script
│   ├── restart.sh             # Combined restart script
│   ├── etcd/
│   │   ├── start.sh           # etcd management scripts
│   │   ├── stop.sh
│   │   └── restart.sh
│   └── apisix/
│       ├── start.sh           # APISIX management scripts
│       ├── stop.sh
│       └── restart.sh
├── config/apisix/
│   ├── config-default.yaml    # Default APISIX config
│   └── config.yaml            # Main APISIX config
├── docker/
│   ├── apisix/Dockerfile      # APISIX multi-stage build
│   └── etcd/Dockerfile        # etcd build recipe
├── docker-compose.yml         # Build & run compose
├── docker-compose.standalone.yml # Pre-built images compose
├── Makefile                   # Build automation
├── build.sh                   # Build script
├── start.sh                   # Docker start script
├── stop.sh                    # Docker stop script
├── test.sh                    # Test script
└── test-integration.sh        # Integration test script
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
