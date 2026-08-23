FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
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

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /workspace

# Setup Python 3.12 environment
ENV VIRTUAL_ENV=/opt/venv
RUN uv venv --python 3.12 $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install PyTorch CUDA 13.0 + CUDA 13 pip toolkit + sglang-kernel 0.4.5
RUN uv pip install --upgrade pip setuptools wheel ninja cmake && \
    uv pip install torch==2.11.0+cu130 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 && \
    uv pip install cuda-toolkit nvidia-cuda-crt nvidia-cuda-nvcc nvidia-cuda-runtime && \
    uv pip install sglang-kernel==0.4.5

# Create unversioned .so symlinks for the linker
RUN python3 -c "import os, glob; [os.symlink(f, f.rsplit('.', 1)[0]) for f in glob.glob('/opt/venv/lib/python3.12/site-packages/nvidia/*/lib/*.so.13') if not os.path.exists(f.rsplit('.', 1)[0])]" && \
    find /opt/venv/lib/python3.12/site-packages/nvidia/ -name "libcudart.so*" -exec ln -sf {} /opt/venv/lib/python3.12/site-packages/nvidia/cu13/lib/libcudart.so \; -quit

# Configure CUDA 13 environment
ENV CUDA_HOME=/opt/venv/lib/python3.12/site-packages/nvidia/cu13
ENV PATH="$CUDA_HOME/bin:$PATH"
ENV LIBRARY_PATH="$CUDA_HOME/lib:$CUDA_HOME/lib64:/opt/venv/lib/python3.12/site-packages/nvidia/cuda_runtime/lib:${LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="$CUDA_HOME/lib:$CUDA_HOME/lib64:/opt/venv/lib/python3.12/site-packages/nvidia/cuda_runtime/lib:/usr/local/cuda/lib64"
ENV FREETOKEN_ALLOW_CUDA_MISMATCH=1

# Clone or copy FreeToken source code
ARG FREETOKEN_REPO=https://github.com/FlashML-org/FreeToken.git
ARG FREETOKEN_REF=main

RUN git clone --depth 1 --branch ${FREETOKEN_REF} ${FREETOKEN_REPO} /workspace/FreeToken || \
    git clone --depth 1 ${FREETOKEN_REPO} /workspace/FreeToken

WORKDIR /workspace/FreeToken

# Build FreeToken and install all project dependencies
RUN uv pip install -e . --no-build-isolation

# Default environment
ENV HF_HOME=/mnt/storage/huggingface
EXPOSE 1919

ENTRYPOINT ["ft", "serve"]
CMD ["--model", "ornith-ai/Ornith-1.5-35B-A3B-NVFP4", "--moe-backend", "auto", "--moe-cache-size", "800", "--num-tokens", "32768", "--max-prefill-length", "2048", "--memory-ratio", "0.85", "--host", "0.0.0.0", "--port", "1919"]
