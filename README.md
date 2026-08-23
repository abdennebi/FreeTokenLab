# ⚡ FreeTokenLab

[![CI/CD & GHCR Release](https://github.com/abdennebi/FreeTokenLab/actions/workflows/build-publish-ghcr.yml/badge.svg)](https://github.com/abdennebi/FreeTokenLab/actions/workflows/build-publish-ghcr.yml)
[![Docker Multi-Arch](https://img.shields.io/badge/Architecture-AMD64%20%7C%20ARM64-blue.svg)](https://github.com/abdennebi/FreeTokenLab/pkgs/container/freetoken)
[![CUDA 13.0](https://img.shields.io/badge/NVIDIA-CUDA%2013.0-green.svg)](https://developer.nvidia.com/cuda-toolkit)
[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](LICENSE)
[![French Doc](https://img.shields.io/badge/Lang-Français-red.svg)](README_FR.md)

**FreeTokenLab** is a turnkey, production-ready environment for running massive Mixture-of-Experts (MoE) LLMs (such as **Ornith-1.5-35B-A3B-NVFP4** and **Qwen3.6-35B-A3B-NVFP4**) on consumer-grade hardware (**8 GB VRAM NVIDIA GPUs**) paired with autonomous AI coding agents (**DeepSeek Harness**, **OpenCode**, **Pi Coding Agent**, and **Hermes Agent**).

> 🇫🇷 *Une documentation complète en français est disponible dans [README_FR.md](README_FR.md).*

---

## 🌟 Key Features

- **🚀 One-Click Multi-Container Stack**: Spin up both the GPU inference engine and the **DeepSeek Harness Web UI** with a single command (`make up`).
- **🧠 35B Parameter Models on 8GB VRAM**: Leverages hybrid CPU/GPU MoE offloading with NVFP4 quantization, pinning 800 expert slots in VRAM and streaming others via PCIe.
- **🔒 Secure Sandboxing with Bubblewrap**: Native Linux kernel namespace isolation for safe AI agent tool and bash execution.
- **🤖 4 Pre-Configured AI Coding Agents**:
  - **DeepSeek Harness (`dsh`)**: Modern browser GUI & headless CLI agent.
  - **OpenCode (`opencode`)**: Fast TUI terminal pair programmer.
  - **Pi Coding Agent (`pi`)**: Lightweight code reviewer and CLI agent.
  - **Hermes Agent (`hermes`)**: Nous Research autonomous agent.
- **🌍 Multi-Architecture Support**: Official Docker images for both `linux/amd64` (x86_64) and `linux/arm64` (Apple Silicon, NVIDIA Jetson/Grace Hopper, AWS Graviton).
- **🔄 Automated CI/CD & Upstream Sync**: Automatic rebuilds and pushes to **GHCR.io** whenever new upstream releases of FreeToken or DSH are detected.

---

## 🏗️ Architecture Overview

```mermaid
flowchart TD
    subgraph Host ["Host Machine (Browser & Workspace)"]
        Browser["🌐 Web Browser: http://127.0.0.1:8080"]
        Workspace["📁 Local Project Workspace (/workspace/project)"]
        HFCache["💾 Model Cache: /mnt/storage/huggingface"]
    end

    subgraph Stack ["Docker Compose Stack (One-Click)"]
        direction TB
        subgraph S1 ["1. Service: freetoken"]
            FT["FreeToken GPU Inference Engine\n(NVIDIA CUDA 13 | Port 1919)\nModel: Ornith-1.5-35B-A3B-NVFP4"]
            HC["HTTP Healthcheck: GET /v1/models\n(Waits for 200 OK after graph capture)"]
        end

        subgraph S2 ["2. Service: dsh-web"]
            DSH["DeepSeek Harness Web UI\n(Node.js 22 LTS | Port 8080)"]
            BWRAP["Bubblewrap Sandbox Engine\n(Isolated Linux Namespaces)"]
        end

        FT --> HC
        HC -->|depends_on: service_healthy| DSH
        DSH -->|http://127.0.0.1:1919/v1| FT
        DSH --- BWRAP
    end

    Browser -->|Port 8080| DSH
    Workspace -->|Volume Mount| DSH
    HFCache -->|Volume Mount| FT
```

---

## ⚡ Quick Start (Zero-Build One-Click Experience)

No need to install CUDA, Python, or Node.js on your host machine. Pre-built multi-architecture images are automatically pulled from **GitHub Container Registry (`ghcr.io`)**.

### Prerequisites
- Linux (x86_64 or ARM64)
- Docker & Docker Compose v2
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (with NVIDIA Driver >= 550)

### 1. Clone the Repository
```bash
git clone https://github.com/abdennebi/FreeTokenLab.git
cd FreeTokenLab
```

### 2. Launch the Stack (Instant Pull & Start)
```bash
make up
```
> 💡 *Docker will automatically pull `ghcr.io/abdennebi/freetoken:latest` and `ghcr.io/abdennebi/freetoken-dsh:latest` directly from GHCR.*

### 3. Open in Browser
```bash
make open
```
Or navigate directly to **[http://127.0.0.1:8080](http://127.0.0.1:8080)**.

### 4. Update to the Latest Releases
Whenever a new release of FreeToken or DeepSeek Harness is published, simply run:
```bash
make pull && make up
```

### 5. Stop the Stack
```bash
make down
```

---

## 🛠️ Makefile Command Reference

Run `make help` to see all available targets:

| Command | Description |
| :--- | :--- |
| **`make up`** | 🚀 Starts the complete Docker Compose stack (GPU server + DSH Web UI). |
| **`make down`** | 🛑 Stops and cleans up all running containers. |
| **`make open`** | 🌐 Opens the DeepSeek Harness Web UI in your default browser. |
| **`make logs`** | 📜 Streams real-time logs from all stack containers. |
| **`make healthcheck`** | 🔍 Checks the FreeToken OpenAI-compatible `/v1/models` endpoint. |
| **`make test`** | 🧪 Runs validation tests across all 4 AI agents. |
| **`make docker-build-all`** | 🐳 Builds both local Docker images (`freetoken` & `freetoken-dsh`). |
| **`make docker-multiarch`** | 🌍 Builds and pushes multi-architecture images (`amd64` + `arm64`) to GHCR. |
| **`make init-all`** | 💻 Fully bootstraps and compiles the environment natively on the host. |
| **`make clean`** | 🧹 Cleans up build artifacts, caches, and temporary files. |

---

## 🤖 Using the 4 AI Agents

All agent configurations are pre-tuned for optimal context windows and reasoning capabilities:

### 1. DeepSeek Harness (`dsh`)
- **Web UI**: `dsh web` (or via Docker on port 8080)
- **Headless Mode**:
  ```bash
  dsh --profile headless "Analyze the code in src/ and list all endpoints"
  ```

### 2. Pi Coding Agent (`pi`)
- **Interactive TUI**: `pi`
- **Headless Mode**:
  ```bash
  pi -p "Review this Python module and suggest performance improvements"
  ```

### 3. OpenCode (`opencode`)
- **Interactive Terminal**: `opencode`

### 4. Hermes Agent (`hermes`)
- **Interactive REPL**: `hermes`
- **Single-turn Query**:
  ```bash
  hermes -z "Explain the hybrid MoE offloading strategy"
  ```

---

## 🐳 Docker Images & Registry (GHCR)

Pre-built multi-architecture images are published to **GitHub Container Registry**:

```bash
# Pull FreeToken GPU Engine
docker pull ghcr.io/abdennebi/freetoken:latest

# Pull DeepSeek Harness Web UI
docker pull ghcr.io/abdennebi/freetoken-dsh:latest
```

---

## 💻 Native Host Installation (Alternative to Docker)

If you prefer running directly on the host without Docker:

```bash
# 1. Setup system dependencies, Node.js LTS, and Python venv
./scripts/01_setup_host.sh

# 2. Compile native C++ extensions (_pinned_tensor and _cpu_moe)
./scripts/02_build_freetoken.sh

# 3. Install all 4 AI agents
./scripts/03_install_agents.sh

# 4. Apply tuned configurations
./scripts/04_apply_configs.sh

# 5. Start the FreeToken Server
./scripts/start_server.sh "ornith-ai/Ornith-1.5-35B-A3B-NVFP4" 127.0.0.1 1919
```

---

## 📄 License & Credits

- FreeToken Inference Engine by [FlashML-org](https://github.com/FlashML-org/FreeToken).
- DeepSeek Harness by [DeepSeek AI](https://github.com/deepseek-ai/deepseek-harness).
- FreeTokenLab Automation & Integration Suite by [abdennebi](https://github.com/abdennebi).
- Licensed under the Apache License, Version 2.0.
