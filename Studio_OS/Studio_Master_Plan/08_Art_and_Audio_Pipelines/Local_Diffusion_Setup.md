---
title: Local Diffusion Setup
type: system
layer: execution
status: active
tags:
  - art
  - diffusion
  - local
  - stable-diffusion
  - flux
  - comfyui
depends_on:
  - "[Art_Pipeline_Overview]"
used_by:
  - "[Batch_Generation_Workflow]]"
  - "[[Prompt_Architecture_Templates]"
---

# Local Diffusion Setup

## Purpose

Configure local AI generation infrastructure to enable cost-effective, high-volume art production without paid API dependencies.

---

## Hardware Requirements

### Minimum Specs (Entry Level)

| Component | Specification | Performance |
|-----------|---------------|-------------|
| GPU | RTX 3060 (12GB) | ~4 images/min at 512x512 |
| RAM | 16 GB | Sufficient for most models |
| Storage | 100 GB SSD | For models and outputs |
| CPU | Any modern 4-core | Not critical for generation |

### Recommended Specs (Production)

| Component | Specification | Performance |
|-----------|---------------|-------------|
| GPU | RTX 4090 (24GB) | ~20 images/min at 512x512 |
| RAM | 32 GB | Headroom for large batches |
| Storage | 500 GB NVMe SSD | Fast model loading |
| CPU | 8-core modern | Batch processing |

### Multi-GPU Setup

For studio-scale production:
- 2-4x RTX 3090/4090
- Parallel generation across GPUs
- Shared network storage for models

---

## Software Stack

### Primary: ComfyUI

**Why ComfyUI**:
- Node-based workflow flexibility
- Excellent batch processing
- Memory-efficient
- Active development
- Free and open source

**Installation**:
```bash
# Clone repository
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

# Install dependencies
pip install -r requirements.txt

# Download models to models/ directory
# Start server
python main.py
```

**Access**: http://localhost:8188

### Alternative: Automatic1111

**When to use**: Quick prototyping, simpler workflows

**Installation**:
```bash
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd stable-diffusion-webui
./webui.sh  # Linux/Mac
webui.bat   # Windows
```

### Alternative: Fooocus

**When to use**: Beginner-friendly, minimal configuration

---

## Model Selection

### Base Models

| Model | Style | VRAM | Best For |
|-------|-------|------|----------|
| SDXL 1.0 | General | 8GB | All-purpose generation |
| Flux.1-dev | Photorealistic | 16GB | High-quality images |
| Flux.1-schnell | Fast | 12GB | Quick iterations |
| SD 1.5 | Legacy | 4GB | Low VRAM systems |
| Pony Diffusion | Anime/Toon | 8GB | Stylized characters |

### Recommended Model Combinations

**Pixel Art Games**:
- Base: SD 1.5 or SDXL
- LoRA: Pixel Art XL
- VAE: Built-in or sdxl-vae

**Realistic Games**:
- Base: Flux.1-dev
- LoRA: Game-specific styles
- VAE: Built-in

**Stylized/Anime**:
- Base: Pony Diffusion XL
- LoRA: Style-specific
- VAE: sdxl-vae

---

## Model Management

### Directory Structure

```
ComfyUI/
├── models/
│   ├── checkpoints/     # Base models (.safetensors)
│   ├── loras/           # LoRA adapters
│   ├── vae/             # VAE models
│   ├── controlnet/      # ControlNet models
│   └── upscale_models/  # Upscalers
├── output/              # Generated images
├── input/               # Input images
└── custom_nodes/        # Extensions
```

### Model Sources

| Source | URL | Content |
|--------|-----|---------|
| Civitai | civitai.com | Models, LoRAs, embeddings |
| HuggingFace | huggingface.co | Official models |
| GitHub | github.com | Custom nodes, tools |

### Essential Models to Download

```bash
# SDXL Base
cd models/checkpoints
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# Flux (if VRAM allows)
# Download from HuggingFace: black-forest-labs/FLUX.1-dev

# VAE
cd models/vae
wget https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors

# Upscaler
cd models/upscale_models
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.2.4/RealESRGAN_x4plus_anime_6B.pth
```

---

## Workflow Templates

### Basic Generation Workflow (ComfyUI)

```json
{
  "last_node_id": 9,
  "last_link_id": 9,
  "nodes": [
    {
      "id": 1,
      "type": "CheckpointLoaderSimple",
      "widgets_values": ["sdxl_base_1.0.safetensors"]
    },
    {
      "id": 2,
      "type": "CLIPTextEncode",
      "widgets_values": ["pixel art forest monster, 64x64, game asset"]
    },
    {
      "id": 3,
      "type": "CLIPTextEncode",
      "widgets_values": ["blurry, low quality, photorealistic"]
    },
    {
      "id": 4,
      "type": "EmptyLatentImage",
      "widgets_values": [512, 512, 1]
    },
    {
      "id": 5,
      "type": "KSampler",
      "widgets_values": [20, "randomize", 7, "euler", "normal", 1]
    },
    {
      "id": 6,
      "type": "VAEDecode"
    },
    {
      "id": 7,
      "type": "SaveImage",
      "widgets_values": ["output"]
    }
  ]
}
```

### Batch Generation Workflow

**Key Nodes**:
- `BatchPromptSchedule` - Vary prompts across batch
- `Seed Everywhere` - Control seed variation
- `SaveImage` with dynamic naming

---

## Performance Optimization

### Memory Optimization

```python
# ComfyUI launch flags
python main.py --lowvram        # For 4-6GB VRAM
python main.py --normalvram     # For 8GB VRAM
python main.py --highvram       # For 12GB+ VRAM
```

### Speed Optimization

| Technique | Speed Gain | Quality Impact |
|-----------|-----------|----------------|
| FP16 precision | 2x | Minimal |
| xFormers attention | 1.5x | None |
| TensorRT | 3-4x | None |
| Reduced steps (20→15) | 1.3x | Slight |

### Batch Size Tuning

```python
# Optimal batch sizes by VRAM
BATCH_SIZES = {
    '4GB': 1,
    '6GB': 2,
    '8GB': 4,
    '12GB': 8,
    '16GB': 12,
    '24GB': 16,
}
```

---

## Automation Integration

### API Access

ComfyUI provides a JSON API for automation:

```python
import requests
import json

def generate_image(prompt, negative_prompt, checkpoint):
    workflow = {
        "1": {
            "inputs": {"ckpt_name": checkpoint},
            "class_type": "CheckpointLoaderSimple"
        },
        "2": {
            "inputs": {"text": prompt, "clip": ["1", 1]},
            "class_type": "CLIPTextEncode"
        },
        # ... more nodes
    }
    
    response = requests.post(
        "http://localhost:8188/prompt",
        json={"prompt": workflow}
    )
    return response.json()
```

### Queue Management

```python
class GenerationQueue:
    def __init__(self):
        self.queue = []
    
    def add_job(self, prompt, count=1):
        for i in range(count):
            self.queue.append({
                'prompt': prompt,
                'seed': random.randint(0, 2**32),
                'id': f"job_{len(self.queue)}"
            })
    
    def process_queue(self):
        for job in self.queue:
            result = generate_image(job['prompt'], seed=job['seed'])
            save_result(result, job['id'])
```

---

## Maintenance

### Regular Tasks

| Task | Frequency | Command |
|------|-----------|---------|
| Update ComfyUI | Weekly | `git pull` |
| Clean output folder | Daily | `rm output/*.png` |
| Backup models | Monthly | Copy to external storage |
| Update custom nodes | Monthly | `git pull` in each node dir |

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Out of memory | Use --lowvram flag, reduce batch size |
| Slow generation | Enable xFormers, use FP16 |
| Model not loading | Check file integrity, re-download |
| Black images | Check VAE, try different sampler |

---

## Cost Comparison

| Approach | Setup Cost | Per 1000 Images | Time |
|----------|-----------|-----------------|------|
| Local RTX 4090 | $1,600 | $2 (electricity) | 50 min |
| Local RTX 3060 | $300 | $2 (electricity) | 4 hours |
| Midjourney API | $0 | $20-80 | 30 min |
| DALL-E API | $0 | $20-40 | 30 min |

**Break-even**: Local setup pays for itself after ~2,000 images vs paid APIs.

---

## Related Systems

- [[Art_Pipeline_Overview]] - Local-first philosophy
- [[Batch_Generation_Workflow]] - Uses local generation
- [[Prompt_Architecture_Templates]] - Prompts for local models
- [[Paid_Diffusion_Routing]] - When to use paid instead
