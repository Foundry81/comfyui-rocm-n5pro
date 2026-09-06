# -----------------------------------------------------------------------------
# ComfyUI + ROCm 10.0 + PyTorch 2.13
# Target: AMD Ryzen AI 9 HX PRO 370 / gfx1151
# Tested on: Minisforum N5 Pro, compatible with AI X1 Pro and similar AMD setups
# Purpose: Run ComfyUI with ROCm support and persistent model directories
# -----------------------------------------------------------------------------

FROM rocm/pytorch:rocm10.0_ubuntu24.04_py3.13_pytorch_release_2.13.0

WORKDIR /workspace

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        wget \
        curl \
        vim \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Python dependencies
# -----------------------------------------------------------------------------

RUN /opt/venv/bin/pip install --no-cache-dir --upgrade \
        pip \
        gitpython \
        requests

# -----------------------------------------------------------------------------
# uv
# -----------------------------------------------------------------------------

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# ------------------------------------------------------------
# Clone ComfyUI Repository
#
# Intentionally uses the current main branch.
# Pin a known-good release after establishing the ROCm 10 baseline if you want.
# ------------------------------------------------------------

RUN git clone https://github.com/comfyanonymous/ComfyUI.git \
    /workspace/ComfyUI

WORKDIR /workspace/ComfyUI

# -----------------------------------------------------------------------------
# Create required directories for models, outputs, and custom nodes
# These are also mounted from the host by Compose.
# -----------------------------------------------------------------------------

RUN mkdir -p \
    models/checkpoints \
    models/vae \
    models/loras \
    models/embeddings \
    models/upscale_models \
    models/controlnet \
    output \
    input \
    custom_nodes

# -----------------------------------------------------------------------------
# Install ComfyUI Python dependencies
# -----------------------------------------------------------------------------

RUN /opt/venv/bin/pip install --no-cache-dir \
    -r requirements.txt

RUN if [ -f manager_requirements.txt ]; then \
        /opt/venv/bin/pip install --no-cache-dir \
        -r manager_requirements.txt; \
    fi

# -----------------------------------------------------------------------------
# Environment variables
# -----------------------------------------------------------------------------

ENV MODEL_DOWNLOAD=none

# -----------------------------------------------------------------------------
# Expose ComfyUI port
# -----------------------------------------------------------------------------

EXPOSE 8188

# -----------------------------------------------------------------------------
# Healthcheck to verify the web UI is responding
# -----------------------------------------------------------------------------

HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=30s \
    --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# -----------------------------------------------------------------------------
# Start ComfyUI
# -----------------------------------------------------------------------------

CMD ["/opt/venv/bin/python", "main.py", \
     "--listen", "0.0.0.0", \
     "--port", "8188", \
     "--enable-manager", \
     "--gpu-only", \
     "--force-fp16"]
	 