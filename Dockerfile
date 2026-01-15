# -----------------------------------------------------------------------------
# ROCm ComfyUI Dockerfile - persistent image with test model
# Tested on: Minisforum N5 Pro, compatible with AI X1 Pro and similar AMD setups
# Purpose: Run ComfyUI with ROCm support and persistent model directories
# -----------------------------------------------------------------------------

# Base ROCm PyTorch image
FROM rocm/pytorch:rocm7.1.1_ubuntu24.04_py3.12_pytorch_release_2.9.1

# Set working directory inside container
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
RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip gitpython requests

# -----------------------------------------------------------------------------
# Clone ComfyUI repository
# -----------------------------------------------------------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git \
    && cd ComfyUI \
    && git checkout v0.9.1

WORKDIR /workspace/ComfyUI

# -----------------------------------------------------------------------------
# Create required directories for models, outputs, and custom nodes
# -----------------------------------------------------------------------------
RUN mkdir -p models/checkpoints \
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
RUN /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# -----------------------------------------------------------------------------
# Download a small test SD model (Stable Diffusion 1.5)
# -----------------------------------------------------------------------------
RUN python - <<'EOF'
import os, requests

model_url = "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
dest = "/workspace/ComfyUI/models/checkpoints/v1-5-pruned-emaonly.safetensors"

os.makedirs(os.path.dirname(dest), exist_ok=True)

r = requests.get(model_url, stream=True)
with open(dest, "wb") as f:
    for chunk in r.iter_content(chunk_size=8192):
        f.write(chunk)
EOF

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
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8188/ || exit 1

# -----------------------------------------------------------------------------
# Start ComfyUI
# -----------------------------------------------------------------------------
CMD ["/opt/venv/bin/python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
