# ⚡ FreeTokenLab

[![CI/CD & GHCR Release](https://github.com/abdennebi/FreeTokenLab/actions/workflows/build-publish-ghcr.yml/badge.svg)](https://github.com/abdennebi/FreeTokenLab/actions/workflows/build-publish-ghcr.yml)
[![Defense-in-Depth](https://img.shields.io/badge/Security-5--Layer%20Defense--in--Depth-red.svg)](README.md#-security-first-architecture)
[![Kernel Landlock LSM](https://img.shields.io/badge/nono-Landlock%20Kernel%20Sandbox-success.svg)](https://nono.sh)
[![Docker Multi-Arch](https://img.shields.io/badge/Architecture-AMD64%20%7C%20ARM64-blue.svg)](https://github.com/abdennebi/FreeTokenLab/pkgs/container/freetoken)
[![CUDA 13.0](https://img.shields.io/badge/NVIDIA-CUDA%2013.0-green.svg)](https://developer.nvidia.com/cuda-toolkit)
[![DeepSeek Harness](https://img.shields.io/badge/DSH-v0.1.1--rc.2-blueviolet.svg)](https://github.com/deepseek-ai/deepseek-harness)
[![Dependabot](https://img.shields.io/badge/Dependabot-Enabled-brightgreen.svg?logo=dependabot)](https://github.com/abdennebi/FreeTokenLab/security/dependabot)
[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](LICENSE)
[![French Documentation](https://img.shields.io/badge/Lang-Français-red.svg)](README_FR.md)

**FreeTokenLab** is a **security-first, zero-exfiltration local AI development platform**. It pairs high-performance **35-Billion parameter Mixture-of-Experts (MoE)** inference on consumer hardware (**8 GB VRAM GPUs**) with the **DeepSeek Harness (`dsh`)** autonomous coding agent, shielded by an automatic **5-layer defense-in-depth security architecture**.

> 🇫🇷 *Une documentation complète en français est disponible dans [README_FR.md](README_FR.md).*

---

## 🛡️ Security-First Architecture (5-Layer Defense-in-Depth)

FreeTokenLab is engineered specifically to run autonomous coding agents and LLM tools safely on developers' machines without risk of data exfiltration, secret leakage, or system corruption.

```mermaid
flowchart TD
    subgraph L5 ["🔒 Layer 5: Supply Chain & Image Integrity"]
        SC["Dependabot Security Auditing + Pinned GHCR Tags + Automated CI/CD Layer Caching"]
        subgraph L4 ["🔒 Layer 4: Hardware & Kernel Memory DMA Isolation"]
            MEM["Safe mlock / ulimits: memlock=-1 (High-speed PCIe DMA Pinned Memory Streaming)"]
            subgraph L3 ["🔒 Layer 3: Kernel Landlock LSM Confinement (nono)"]
                NONO["nono Sandboxing (Active by default in Docker & Host)\n• Strict Denial: ~/.ssh, ~/.aws, ~/.gnupg, /etc\n• Allowed r+w: /workspace/project & ~/.dsh only"]
                subgraph L2 ["🔒 Layer 2: Process & Namespace Sandboxing (Bubblewrap)"]
                    BWRAP["bwrap Unprivileged User Namespaces (Isolates Agent Shell Executions)"]
                    subgraph L1 ["🔒 Layer 1: Zero Data Exfiltration (100% Local Inference)"]
                        LLM["FreeToken Local GPU Engine\n(No Cloud Calls • Dummy API Keys • 100% On-Premise)"]
                    end
                end
            end
        end
    end

    classDef sec fill:#1a1d20,stroke:#e63946,stroke-width:2px,color:#fff;
    class L1,L2,L3,L4,L5 sec;
```

### 1. 🔒 Layer 1: Zero Data Exfiltration (100% Offline AI)
- **Zero External API Calls**: Inferences run entirely on local GPU and Host RAM. No code snippets, prompts, or workspace contents leave your physical machine.
- **Pre-provisioned Dummy Credentials**: Configured with local dummy keys (`dummy-key`) to prevent unintentional calls to public cloud APIs.

### 2. 🛡️ Layer 2: Kernel-Level Landlock LSM Confinement (`nono`)
- **Automatic Kernel Sandboxing**: Whenever you run `docker compose up`, DSH is automatically encapsulated in `nono` (Linux Landlock LSM).
- **Sensitive Path Blacklisting**: Read/write access to host credentials (`~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.bashrc`, `/etc`) is strictly denied at the kernel syscall level.
- **Principle of Least Privilege**: The agent is restricted solely to the active workspace (`/workspace/project`) and local configurations (`~/.dsh`).

### 3. 📦 Layer 3: Process & Namespace Isolation (`Bubblewrap`)
- DeepSeek Harness encapsulates every child shell command and tool execution inside unprivileged **Linux user and mount namespaces** (`bwrap`), preventing container escapes and privilege escalation.

### 4. ⚡ Layer 4: Hardware DMA Protection & Memory Control
- **`ulimits: memlock: -1`**: Dedicated to locking physical RAM buffers for high-speed PCIe Gen3/4 x16 Direct Memory Access (DMA) streaming of un-cached MoE experts, preventing page fault overhead while isolating process memory space.

### 5. 🔄 Layer 5: Automated Supply Chain & Version Pinning
- Pinned image digests, automated weekly Dependabot security scanning, and multi-stage container builds with minimal attack surfaces (Node 22 Bookworm Slim & CUDA Minimal Runtimes).

---

## 🌟 Key Highlights

- **🚀 Instant One-Click Experience**: Launch the inference server and the secured agent Web UI with a single command (`make up`).
- **🧠 35B Parameter MoE on 8 GB VRAM**: Runs **`Ornith-1.5-35B-A3B-NVFP4`** with **65,536 tokens context window** using intelligent MoE expert cache offloading (800 expert slots in VRAM, 256 dynamically streamed).
- **🌐 DeepSeek Harness Web UI**: Full-featured in-browser coding IDE (`http://127.0.0.1:8080`) with chat, session tree, workspace tree, and live diff visualizer.
- **📦 Pre-Built Multi-Arch Images**: No local compilation required; images for `linux/amd64` and `linux/arm64` are pulled directly from GHCR.io.

---

## 🏗️ System Architecture

```mermaid
flowchart LR
    subgraph Host ["Host Machine"]
        Browser["🌐 Web Browser\nhttp://127.0.0.1:8080"]
        ProjectDir["📁 Project Workspace\n(/workspace/project)"]
        HFCache["💾 Model Cache\n(/mnt/storage/huggingface)"]
    end

    subgraph DockerCompose ["Docker Compose Stack (One-Click)"]
        direction TB
        subgraph S1 ["1. Service: freetoken"]
            FT["FreeToken GPU Engine\n(Port 1919)\n64k Context • 800 MoE Cache"]
            HC["HTTP Healthcheck\n(GET /v1/models)"]
        end

        subgraph S2 ["2. Service: dsh"]
            DSH["DeepSeek Harness Web UI\n(Port 8080)"]
            NONO["nono Landlock Sandbox\n(Kernel Syscall Filtering)"]
            BWRAP["Bubblewrap Engine\n(Namespace Isolation)"]
        end

        FT --> HC
        HC -->|depends_on: service_healthy| DSH
        DSH -->|http://127.0.0.1:1919/v1| FT
        DSH -.-> NONO
        DSH -.-> BWRAP
    end

    Browser -->|HTTP 8080| DSH
    ProjectDir -->|Volume Mount| DSH
    HFCache -->|Volume Mount| FT
```

---

## ⚡ Quick Start (One-Click)

### Prerequisites
- **Linux OS** (x86_64 or ARM64)
- **Docker** & **Docker Compose v2**
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) (Driver >= 550)

### 1. Clone & Launch
```bash
git clone https://github.com/abdennebi/FreeTokenLab.git
cd FreeTokenLab

# Starts both FreeToken and DSH with automatic nono sandboxing
make up
```

### 2. Open Web UI
Open **[http://127.0.0.1:8080](http://127.0.0.1:8080)** in your browser.

### 3. Stop the Stack
```bash
make down
```

---

## 🛠️ Security CLI & Host Workflows

FreeTokenLab supports both Docker Compose and native Landlock host execution:

```bash
# 🔒 Launch native host DSH encapsulated in nono Landlock sandbox
make dsh-secure

# 🛡️ Execute a headless AI task securely on host
make dsh-headless-secure PROMPT="Audit the security of src/auth"

# 📜 Follow real-time logs of the stack
make logs

# 📊 Check container status and health
make ps

# 🔍 Ping the local OpenAI-compatible API
make healthcheck
```

---

## 📊 Security Feature Comparison

| Security Capability | FreeTokenLab (Default) | Standard Local LLM Tools | Cloud LLM Agents |
| :--- | :---: | :---: | :---: |
| **Kernel Landlock LSM (`nono`)** | ✅ **Enforced** | ❌ None | ❌ None |
| **Namespace Sandboxing (`bwrap`)** | ✅ **Enforced** | ❌ Rare | ❌ None |
| **Data Exfiltration Risk** | 🛡️ **Zero (100% Offline)** | ⚠️ Partial | 🚨 High (Cloud API) |
| **Credential Protection (`~/.ssh`)** | 🛡️ **Kernel Blocked** | ❌ Exposed | ⚠️ Risk of leak |
| **DMA Pinned Memory Isolation** | ✅ **Configured (`memlock`)** | ❌ Default unpinned | N/A |
| **Supply Chain Audits (Dependabot)** | ✅ **Automated Weekly** | ❌ Manual | ⚠️ Proprietary |

---

## 📜 License & Acknowledgements

- Licensed under [Apache 2.0](LICENSE).
- Powered by [FreeToken](https://github.com/FlashML-org/FreeToken), [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness), and [nono](https://nono.sh).
