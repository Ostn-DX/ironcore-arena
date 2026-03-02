---
title: Asset Integration Routing
type: decision
layer: execution
status: active
tags:
  - routing
  - asset
  - integration
  - pipeline
  - 2d
  - 3d
  - ui
depends_on:
  - "[Task_Routing_Overview]]"
  - "[[Vision_Art_Direction]]"
  - "[[Image_Diffusion_Local]]"
  - "[[Image_Diffusion_API]]"
  - "[[Model_3D_Generation]"
used_by: []
---

# Asset Integration Routing

## Asset Pipeline Classification and Routing

Asset integration involves generating, processing, and integrating visual assets into the game. Routing depends on asset type, quality requirements, and production stage.

### Asset Type Classification

| Type | Description | Generation | Routing |
|------|-------------|------------|---------|
| 2D Concept | Concept art, sketches | Local/API | Vision + Image Gen |
| 2D UI | Icons, buttons, panels | Local | Image Gen |
| 2D Sprite | Characters, items | Local/API | Image Gen |
| 2D Background | Environments, scenes | Local/API | Image Gen |
| 3D Model | Meshes, characters | Limited | See 3D warning |
| Texture | Diffuse, normal, etc. | Local | Image Gen |
| Animation | Skeletal, vertex | Manual | Human required |
| VFX | Particle effects | Hybrid | Specialized tools |

### Routing Decision Tree

```
Asset Request
│
├── Type = 2D Concept Art
│   └── Route: Image Diffusion API (Midjourney/DALL-E)
│       └── Generate concepts
│       └── Curate best options
│       └── Deliver to art director
│
├── Type = 2D UI Element
│   └── Route: Image Diffusion Local (SDXL/Flux)
│       └── Generate from design spec
│       └── Process (resize, optimize)
│       └── Export to game format
│
├── Type = 2D Sprite (character, item)
│   └── Route: Image Diffusion Local + API
│       └── Local: Generate variations
│       └── API: Final polish (if needed)
│       └── Process for game engine
│
├── Type = 2D Background
│   └── Route: Image Diffusion API
│       └── High quality generation
│       └── Upscale if needed
│       └── Optimize for game
│
├── Type = 3D Model
│   └── Route: See [[Model_3D_Generation]] WARNING
│       └── Currently NOT recommended for production
│       └── Use manual modeling or kitbash
│
├── Type = Texture
│   └── Route: Image Diffusion Local
│       └── Generate seamless textures
│       └── Create texture sets
│       └── Export with proper compression
│
├── Type = Animation
│   └── Route: Human Required
│       └── AI assistance for keyframes only
│       └── Human animators for production
│
└── Type = VFX
    └── Route: Specialized Tools
        └── Houdini, Unity VFX Graph, etc.
        └── AI for texture/element generation
```

### Owner Agent: Asset Agent

The Asset Agent owns asset pipeline coordination.

**Responsibilities:**
- Classify asset type and requirements
- Select generation approach
- Coordinate with art direction
- Process generated assets
- Validate asset quality
- Integrate into game

### Permitted Models by Asset Type

| Asset Type | Primary | Polish | Processing |
|------------|---------|--------|------------|
| 2D Concept | API (Midjourney) | API | Manual |
| 2D UI | Local (SDXL) | Local | Automated |
| 2D Sprite | Local | API* | Automated |
| 2D Background | API | API | Automated |
| 3D Model | Manual | Manual | Manual |
| Texture | Local (SDXL) | Local | Automated |
| Animation | Human | Human | Human |
| VFX | Hybrid | Hybrid | Hybrid |

*If quality insufficient

### Context Pack Contents

**2D Asset Generation:**
```yaml
context_pack:
  # Art direction
  art_direction_doc: 1  # Style guide
  reference_images: 3  # Style references
  
  # Technical specs
  resolution: "1024x1024"
  format: "PNG"
  color_space: "sRGB"
  
  # Game requirements
  usage: "ui|sprite|background"
  transparency: true|false
  
  # Generation parameters
  model: "flux1-dev"
  lora_weights: ["style_lora"]
```

### Asset Processing Pipeline

```
1. Generate asset (local or API)
2. Review and select best
3. Process for game:
   a. Resize to target resolution
   b. Optimize compression
   c. Generate mipmaps (if needed)
   d. Create variants (if needed)
4. Validate in engine
5. Integrate into build
```

### Gates Required

**Pre-Generation Gates:**
1. **Art Direction**: Style defined
2. **Technical Specs**: Resolution, format specified
3. **Usage Defined**: How asset will be used

**Post-Generation Gates:**
1. **Quality Check**: Meets visual standards
2. **Technical Validation**: Correct format, size
3. **Engine Test**: Works in game
4. **Performance Check**: Memory budget OK
5. **Art Director Approval**: For key assets

### Quality Thresholds

| Asset Type | Min Quality | Review Required |
|------------|-------------|-----------------|
| Concept | 7/10 | Art director |
| UI | 8/10 | Automated |
| Sprite | 8/10 | Spot-check |
| Background | 9/10 | Art director |
| Texture | 7/10 | Automated |

### Cost Estimates

| Asset Type | Generation | Processing | Total/Asset |
|------------|------------|------------|-------------|
| 2D Concept | $0.10 | $0 | $0.10 |
| 2D UI | $0.001 | $0 | $0.001 |
| 2D Sprite | $0.01 | $0 | $0.01 |
| 2D Background | $0.10 | $0.01 | $0.11 |
| 3D Model | $50-500* | $10 | $60-510 |
| Texture | $0.001 | $0 | $0.001 |
| Animation | $200-2000 | $0 | $200-2000 |

*Manual modeling cost

### Best Practices

1. Use local generation for iteration
2. Reserve API for final assets
3. Maintain consistent style across assets
4. Optimize for target platform
5. Version control all assets
6. Document generation parameters
7. Have art director review key assets

### Asset Budget Management

```yaml
asset_budget:
  monthly_generation:
    local: unlimited
    api: $100
  
  per_asset_type:
    concepts: $0.10
    ui: $0.001
    sprites: $0.01
    backgrounds: $0.10
```

### Integration

Uses:
- [[Vision_Art_Direction]]: For style extraction
- [[Image_Diffusion_Local]]: For local generation
- [[Image_Diffusion_API]]: For API generation
- [[Model_3D_Generation]]: For 3D (with warnings)
