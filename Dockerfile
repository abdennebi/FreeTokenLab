# ==============================================================================
# FreeToken Multi-Stage / Layer-Cached Optimized Dockerfile
# ==============================================================================
FROM nvidia/cuda:13.3.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# ------------------------------------------------------------------------------
# Layer 1: System Packages & Build Toolchain (Cached permanently)
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    git \
    curl \
    wget \
    xz-utils \
    libopenblas-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /workspace

# ------------------------------------------------------------------------------
# Layer 2: Python 3.12 Virtual Environment & Core CUDA 13 Wheels (Heavy: ~10 GB, Cached permanently)
# ------------------------------------------------------------------------------
ENV VIRTUAL_ENV=/opt/venv
RUN uv venv --python 3.12 $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN uv pip install --upgrade pip setuptools wheel ninja cmake && \
    uv pip install torch==2.11.0+cu130 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 && \
    uv pip install cuda-toolkit nvidia-cuda-crt nvidia-cuda-nvcc nvidia-cuda-runtime && \
    uv pip install sglang-kernel==0.4.5

# ------------------------------------------------------------------------------
# Layer 3: Third-Party Dependencies (Heavy: ~2 GB, Cached permanently)
# ------------------------------------------------------------------------------
RUN uv pip install \
    "numpy>=2.0,<2.5" \
    "transformers>=5.5,<6" \
    "fastapi>=0.115,<1" \
    "uvicorn>=0.30,<1" \
    "pydantic>=2.9,<3" \
    "safetensors>=0.6,<1" \
    "huggingface_hub>=1.5,<2" \
    "modelscope>=1.37,<2" \
    "msgpack>=1.1,<2" \
    "pyzmq>=27,<28" \
    "prompt_toolkit>=3.0,<4" \
    "einops>=0.8,<1" \
    "gguf>=0.19,<1" \
    "flashlib==0.3.0" \
    "apache-tvm-ffi==0.1.13.post3" \
    "partial-json-parser>=0.2,<1" \
    "openai>=2.0,<3" \
    "tqdm>=4.66,<5" \
    "fire" \
    "rich" \
    "requests"

# ------------------------------------------------------------------------------
# Layer 4: CUDA Symlinks & Runtime Environment Variables (Cached permanently)
# ------------------------------------------------------------------------------
RUN python3 -c "import os, glob; [os.symlink(f, f.rsplit('.', 1)[0]) for f in glob.glob('/opt/venv/lib/python3.12/site-packages/nvidia/*/lib/*.so.13') if not os.path.exists(f.rsplit('.', 1)[0])]" && \
    find /opt/venv/lib/python3.12/site-packages/nvidia/ -name "libcudart.so*" -exec ln -sf {} /opt/venv/lib/python3.12/site-packages/nvidia/cu13/lib/libcudart.so \; -quit

ENV CUDA_HOME=/opt/venv/lib/python3.12/site-packages/nvidia/cu13
ENV PATH="$CUDA_HOME/bin:$PATH"
ENV LIBRARY_PATH="$CUDA_HOME/lib:$CUDA_HOME/lib64:/opt/venv/lib/python3.12/site-packages/nvidia/cuda_runtime/lib:${LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="$CUDA_HOME/lib:$CUDA_HOME/lib64:/opt/venv/lib/python3.12/site-packages/nvidia/cuda_runtime/lib:/usr/local/cuda/lib64"
ENV FREETOKEN_ALLOW_CUDA_MISMATCH=1
ENV HF_HOME=/mnt/storage/huggingface

# ------------------------------------------------------------------------------
# Layer 5 (TOP LAYER ONLY): FreeToken Source & Native C++ Compilation (~20 MB, rebuilds in <15s)
# ------------------------------------------------------------------------------
ARG FREETOKEN_REPO=https://github.com/FlashML-org/FreeToken.git
ARG FREETOKEN_REF=v0.1.2

RUN git clone --depth 1 --branch ${FREETOKEN_REF} ${FREETOKEN_REPO} /workspace/FreeToken || \
    git clone --depth 1 ${FREETOKEN_REPO} /workspace/FreeToken

WORKDIR /workspace/FreeToken

# Fast compile: dependencies are already resolved in Layer 2 & 3
RUN uv pip install -e . --no-build-isolation --no-deps

EXPOSE 1919

ENTRYPOINT ["ft", "serve"]
CMD ["--model", "ornith-ai/Ornith-1.5-35B-A3B-NVFP4", "--moe-backend", "auto", "--moe-cache-size", "800", "--num-tokens", "32768", "--max-prefill-length", "2048", "--memory-ratio", "0.85", "--host", "0.0.0.0", "--port", "1919"]
