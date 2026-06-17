# APISIX + etcd 构建

[![构建状态](https://github.com/qingzhenzi/apisix-etcd-build/actions/workflows/build.yml/badge.svg)](https://github.com/qingzhenzi/apisix-etcd-build/actions/workflows/build.yml)

从源码构建 [Apache APISIX](https://apisix.apache.org/) API 网关和 [etcd](https://etcd.io/) 分布式键值存储。生成打包了动态库的便携式包。

## 功能特性

- 源码构建 - APISIX 和 etcd 从官方源码编译
- 多架构 - 支持 `linux/amd64` 和 `linux/arm64`
- ARM 原生 CI - 使用 GitHub 原生 ARM 运行器
- Docker Compose - 一键部署
- 便携合体包 - etcd + APISIX 整合包，附带启停脚本
- 需要 GLIBC >= 2.34 - 兼容 Ubuntu 22.04+、Debian 12+。**不兼容** Ubuntu 20.04、Debian 11、CentOS 7 及更老系统。

## 当前版本

| 组件 | 版本 |
|------|------|
| Apache APISIX | 3.16.0 |
| etcd | v3.6.12 |
| OpenResty | 1.31.1.1 |
| 基础镜像 | Debian Bookworm |

## 快速开始

### Docker Compose

```bash
git clone https://github.com/qingzhenzi/apisix-etcd-build.git
cd apisix-etcd-build

# 构建并启动
docker compose up -d

# 查看状态
docker compose ps
```

### 便携合体包

从 CI 产物下载或自行构建：

```bash
# 解压
tar -xzf apisix-etcd-3.16.0-3.6.12-linux-amd64.tar.gz
cd apisix-etcd-3.16.0-3.6.12-linux-amd64

# 启动所有服务
./start.sh

# 停止所有服务
./stop.sh

# 或单独管理
./etcd/start.sh
./apisix/start.sh
```

## 端口说明

| 服务 | 端点 | 说明 |
|------|------|------|
| APISIX HTTP | `http://localhost:9080` | API 网关 HTTP |
| APISIX HTTPS | `https://localhost:9443` | API 网关 HTTPS |
| APISIX Admin | `http://localhost:9090` | 管理 API |
| etcd 客户端 | `http://localhost:2379` | etcd 客户端端口 |

默认管理 API 密钥: `edd1c9f034335f136f87ad84b625c8f1`

## 使用方法

### 构建镜像

```bash
make build              # 构建所有镜像
make build-etcd         # 只构建 etcd
make build-apisix       # 只构建 APISIX
make buildx             # 多架构构建（需 Buildx）
```

### 管理服务

```bash
make start              # 启动服务
make stop               # 停止服务
make logs               # 查看日志
make clean              # 清理容器、数据卷、镜像
make status             # 查看服务状态
```

### 测试

```bash
make test               # 基础健康检查
./test.sh               # 基础健康检查（脚本）
```

## GitHub Actions CI

每次推送自动构建并打包 amd64 和 arm64 的便携包。

| 任务 | 说明 | 运行环境 |
|------|------|----------|
| `build-etcd` | 从源码构建 etcd | amd64 + arm64 |
| `build-apisix` | 编译 OpenResty + APISIX，打包动态库 | amd64 + arm64 |
| `test-etcd` | 验证 etcd 二进制 | amd64 |
| `test-apisix` | 验证 APISIX 包 | amd64 |
| `test-cross-distro` | Ubuntu 22.04 兼容性测试 | amd64 |
| `package-bundle` | 合并 etcd + APISIX + 启动脚本为单一压缩包 | amd64 + arm64 |
| `create-release` | 打标签时发布产物 | ubuntu-latest |

### 构建产物

每次 CI 运行会产生以下可下载的产物：

- `etcd-v3.6.12-linux-{amd64,arm64}.tar.gz` - etcd 独立二进制包
- `apisix-3.16.0-linux-{amd64,arm64}.tar.gz` - APISIX 独立包
- `apisix-etcd-bundle-3.16.0-linux-{amd64,arm64}.tar.gz` - 整合包（含启停脚本）

### 版本矩阵测试

手动触发以测试多个版本组合：
[`version-matrix.yml`](.github/workflows/version-matrix.yml)

## 项目结构

```
apisix-etcd-build/
├── .github/workflows/
│   ├── build.yml              # 主 CI 流水线
│   └── version-matrix.yml     # 多版本测试工作流
├── bundle/
│   ├── start.sh               # 整合启动脚本
│   ├── stop.sh                # 整合停止脚本
│   ├── restart.sh             # 整合重启脚本
│   ├── etcd/
│   │   ├── start.sh           # etcd 管理脚本
│   │   ├── stop.sh
│   │   └── restart.sh
│   └── apisix/
│       ├── start.sh           # APISIX 管理脚本
│       ├── stop.sh
│       └── restart.sh
├── config/apisix/
│   ├── config-default.yaml    # APISIX 默认配置
│   └── config.yaml            # APISIX 主配置
├── docker/
│   ├── apisix/Dockerfile      # APISIX 多阶段构建
│   └── etcd/Dockerfile        # etcd 构建
├── docker-compose.yml         # 构建 & 运行 compose
├── docker-compose.standalone.yml # 使用预构建镜像
├── Makefile                   # 构建自动化
├── build.sh                   # 构建脚本
├── start.sh                   # Docker 启动脚本
├── stop.sh                    # Docker 停止脚本
├── test.sh                    # 测试脚本
└── test-integration.sh        # 集成测试脚本
```

## 许可证

基于 Apache License, Version 2.0 许可。详见 [LICENSE](LICENSE)。
