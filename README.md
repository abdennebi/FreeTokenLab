# ⚡ FreeTokenLab

[![CI/CD & GHCR Release](https://github.com/abdennebi/FreeTokenLab/actions/workflows/build-publish-ghcr.yml/badge.svg)](https://github.com/abdennebi/FreeTokenLab/actions/workflows/build-publish-ghcr.yml)
[![Docker Multi-Arch](https://img.shields.io/badge/Architecture-AMD64%20%7C%20ARM64-blue.svg)](https://github.com/abdennebi/FreeTokenLab/pkgs/container/freetoken)
[![CUDA 13.0](https://img.shields.io/badge/NVIDIA-CUDA%2013.0-green.svg)](https://developer.nvidia.com/cuda-toolkit)
[![nono Sandbox](https://img.shields.io/badge/nono-Landlock%20LSM-success.svg)](https://nono.sh)
[![DeepSeek Harness](https://img.shields.io/badge/DSH-v0.1.1--rc.2-blueviolet.svg)](https://github.com/deepseek-ai/deepseek-harness)
[![Dependabot](https://img.shields.io/badge/Dependabot-Enabled-brightgreen.svg?logo=dependabot)](https://github.com/abdennebi/FreeTokenLab/security/dependabot)
[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](LICENSE)
[![French Documentation](https://img.shields.io/badge/Lang-Français-red.svg)](README_FR.md)

**FreeTokenLab** is a zero-setup, turnkey local AI development platform. It brings together high-performance **35-billion parameter Mixture-of-Experts (MoE)** inference on consumer-grade hardware (**8 GB VRAM GPUs**) and the **DeepSeek Harness (`dsh`)** Web UI and autonomous coding agent with **dual-layer kernel sandboxing (`nono` + `Bubblewrap`)**.

> 🇫🇷 *Une documentation complète en français est disponible dans [README_FR.md](README_FR.md).*

---

## 🌟 Highlights

- **🚀 Instant One-Click Experience**: Launch the entire stack (GPU inference engine + DeepSeek Harness Web UI) with a single command (`make up`).
- **🧠 35B Parameter Models on 8 GB VRAM**: Runs state-of-the-art quantized models (**`Ornith-1.5-35B-A3B-NVFP4`**) via hybrid CPU/GPU MoE offloading (800 expert slots pinned in VRAM, remaining streamed over PCIe).
- **🌐 DeepSeek Harness Web UI**: Full-featured in-browser interface (`http://127.0.0.1:8080`) with chat, live workspace explorer, git diff visualizer, and session management.
- **🛡️ Dual-Layer Kernel Sandboxing (`nono` + `bwrap`)**:
  - **`nono` (Landlock LSM)**: Kernel capability wrapper restricting system calls, protecting sensitive credentials (`~/.ssh`, `~/.aws`, `~/.gnupg`), and blocking destructive operations.
  - **`Bubblewrap`**: Linux user and mount namespace isolation for sub-processes and tool execution.
- **📦 Zero Compilation Needed (Pre-Built GHCR Images)**: Pre-compiled multi-architecture Docker images (`linux/amd64` and `linux/arm64`) are pulled automatically from **GHCR.io**.
- **🔄 Automated Version Pinning & Upstream Sync**: CI workflows monitor upstream FreeToken and DSH releases, automatically building, tagging, and pinning new versions in `docker-compose.yml`.

---


> [!TIP]
> **PCIe DMA & `memlock` ulimit**: FreeToken streams un-cached MoE expert weights (20+ GB) from Host CPU RAM to GPU over the PCIe bus. `docker-compose.yml` configures `ulimits.memlock: -1` (unlimited pinned memory) to enable direct memory access (DMA) without paging overhead, guaranteeing maximum PCIe throughput.

## 🏗️ Architecture

```mermaid
flowchart TD
    subgraph Host ["Host Machine (Browser & Project Files)"]
        Browser["🌐 Web Browser: http://127.0.0.1:8080"]
        Workspace["📁 Local Project Code (/workspace/project)"]
        HFCache["💾 Model Cache (/mnt/storage/huggingface)"]
    end

    subgraph ComposeStack ["Docker Compose Stack (One-Click)"]
        direction TB
        subgraph S1 ["1. Service: freetoken"]
            FT["FreeToken GPU Inference Engine\n(NVIDIA CUDA 13 | Port 1919)\nModel: Ornith-1.5-35B-A3B-NVFP4"]
            HC["HTTP Healthcheck: GET /v1/models\n(Waits for 200 OK after graph capture)"]
        end

        subgraph S2 ["2. Service: dsh"]
            DSH["DeepSeek Harness Web UI\n(Node.js 22 LTS | Port 8080)"]
            NONO["nono Security Wrapper\n(Landlock LSM Syscall Confinement)"]
            BWRAP["Bubblewrap Sandbox Engine\n(Kernel Namespace Isolation)"]
        end

        FT --> HC
        HC -->|depends_on: service_healthy| DSH
        DSH -->|http://127.0.0.1:1919/v1| FT
        DSH --- NONO
        DSH --- BWRAP
    end

    Browser -->|Port 8080| DSH
    Workspace -->|Volume Mount| DSH
    HFCache -->|Volume Mount| FT
```

---

## ⚡ Quick Start (One-Click)

### Prerequisites
- **Linux** (x86_64 or ARM64)
- **Docker** & **Docker Compose v2**
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (NVIDIA Driver >= 550)

### 1. Clone the Repository
```bash
git clone https://github.com/abdennebi/FreeTokenLab.git
cd FreeTokenLab
```

### 2. Launch the Stack
```bash
make up
```
*Docker will pull the pre-built pinned images from GHCR and start:*
1. **FreeToken GPU Server** on `http://127.0.0.1:1919` (waits for expert banks & CUDA graph capture).
2. **DeepSeek Harness Web UI** on `http://127.0.0.1:8080` once the model is healthy.

### 3. Open in Browser
```bash
make open
```
Or open **[http://127.0.0.1:8080](http://127.0.0.1:8080)** directly.

### 4. Stop the Stack
```bash
make down
```

---

## 🔒 Security & Sandboxing (`nono` + `bubblewrap`)

FreeTokenLab implements a **defense-in-depth** security architecture:

1. **`nono` (Landlock LSM Confinement)**:
   - Blocks unauthorized access to host credentials (`~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.bashrc`, `/etc`).
   - Irreversible privilege drop at the kernel syscall level.
   - Prevents command injection escapes and destructive operations (`rm -rf /`, `chmod 777`).
2. **`Bubblewrap` (`bwrap`)**:
   - Isolates filesystem mount namespaces inside the workspace.
   - Restricts agent writes strictly to `/workspace/project` and ephemeral `/tmp`.

### Running Native DSH with `nono` on Host:
```bash
# Launch DSH Web UI under nono Landlock protection
make dsh-secure

# Run a headless AI task safely
make dsh-headless-secure PROMPT="Audit the security of src/auth"
```

---

## 🛠️ Makefile Command Reference

| Command | Description |
| :--- | :--- |
| **`make up`** | 🚀 Launches the full stack (pulls pre-built GHCR images automatically). |
| **`make down`** | 🛑 Stops and removes all running stack containers. |
| **`make open`** | 🌐 Opens the DeepSeek Harness Web UI in your default browser. |
| **`make logs`** | 📜 Streams real-time logs from both `freetoken` and `dsh` containers. |
| **`make ps`** | 📊 Displays current container status and health. |
| **`make pull`** | ⬇️ Pulls the latest pinned images from GHCR.io. |
| **`make dsh-secure`** | 🔒 Starts native DSH Web encapsulated in `nono` (Landlock sandbox). |
| **`make dsh-headless-secure`** | 🛡️ Executes a sandboxed headless task with `nono`. |
| **`make healthcheck`** | 🔍 Pings the FreeToken `/v1/models` API endpoint. |
| **`make docker-build-all`** | 🐳 Compiles both Docker images locally from scratch. |
| **`make docker-multiarch`** | 🌍 Builds and pushes multi-architecture images (`amd64` + `arm64`) to GHCR. |
| **`make clean`** | 🧹 Cleans up temporary caches and build artifacts. |

---

## 🌍 Supported Architectures

| Image | Tag | Architectures | Target Platforms |
| :--- | :--- | :--- | :--- |
| `ghcr.io/abdennebi/freetoken` | `v0.1.2` | `linux/amd64`<br>`linux/arm64` | • Intel/AMD x86_64 with NVIDIA RTX GPUs<br>• NVIDIA Grace Hopper (GH200), Jetson Orin, AWS Graviton + GPU |
| `ghcr.io/abdennebi/freetoken-dsh` | `0.1.1-rc.2` | `linux/amd64`<br>`linux/arm64` | • Linux x86_64<br>• Apple Silicon (M1/M2/M3/M4)<br>• Linux ARM64 servers |

---

## 💻 Native Host Installation (Optional without Docker)

If you wish to run directly on the host machine:

```bash
# 1. Install system dependencies, Node.js LTS, nono, and Python venv
./scripts/01_setup_host.sh

# 2. Compile native C++ extensions (_pinned_tensor and _cpu_moe)
./scripts/02_build_freetoken.sh

# 3. Install DeepSeek Harness
npm install -g @deepseek-ai/dsh@0.1.1-rc.2

# 4. Start the inference engine
./scripts/start_server.sh "ornith-ai/Ornith-1.5-35B-A3B-NVFP4" 127.0.0.1 1919

# 5. Start DeepSeek Harness Web UI securely under nono
./scripts/dsh_secure.sh web --port 8080
```

---

## 📄 License & Acknowledgments

- **FreeToken Engine**: Developed by [FlashML-org](https://github.com/FlashML-org/FreeToken).
- **DeepSeek Harness**: Developed by [DeepSeek AI](https://github.com/deepseek-ai/deepseek-harness).
- **nono Sandbox**: Developed by [nolabs](https://nono.sh).
- **FreeTokenLab Suite**: Packaged and automated by [abdennebi](https://github.com/abdennebi).
- Licensed under the **Apache License, Version 2.0**.
