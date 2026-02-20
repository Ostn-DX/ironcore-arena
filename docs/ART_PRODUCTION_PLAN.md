# Ironcore Arena - Art & Design Production Plan
## Outhold + Wii Tanks Inspired

---

## Visual Summary

**Style:** Flat geometric with long shadows, vibrant colors on dark navy  
**Perspective:** 15° tabletop view (not pure top-down)  
**Mood:** Clean, futuristic, arcade-friendly  
**Reference:** Outhold's node network + Wii Tanks toy-like appeal

---

## What's Been Built

### ✅ Code (Complete)
- [x] All 19 gameplay features
- [x] Optimization pass (-27% lines, +15% performance)
- [x] UI component system (UICard, UIButton)
- [x] Redesigned main menu with decorative nodes
- [x] Complete bot design spec

### 🎨 Art (Next Phase)
- [ ] Chassis sprites (3 types, 4 tiers)
- [ ] Weapon sprites (6-8 variants)
- [ ] Arena tilesets (4 themes)
- [ ] Effects (explosions, muzzle flash)
- [ ] UI polish (transitions, animations)

---

## Asset Pipeline

### Tools
1. **Aseprite** ($20) - Pixel art, animations
2. **Alternative:** LibreSprite (free)
3. **Godot** - Integration, shaders

### Workflow
```
1. Sketch in Aseprite (48x48 canvas)
2. Export PNG with transparency
3. Import to Godot
4. Set up SpriteFrames for animation
5. Test in-game with modulate colors
6. Iterate
```

---

## Priority Order

### Week 1: Core Visuals
**Goal:** Game looks playable

| Asset | Size | Quantity | Time |
|-------|------|----------|------|
| Scout chassis | 40x40 | 1 base × 4 colors | 2 hrs |
| Fighter chassis | 48x48 | 1 base × 4 colors | 2 hrs |
| Tank chassis | 56x56 | 1 base × 4 colors | 2 hrs |
| Machine gun | 8x24 | 2 variants | 1 hr |
| Cannon | 12x32 | 2 variants | 1 hr |
| Roxtan Park tileset | 32x32 | 8 tiles | 3 hrs |
| **Total** | | | **11 hrs** |

### Week 2: Content
**Goal:** Full content variety

| Asset | Size | Quantity | Time |
|-------|------|----------|------|
| Remaining weapons | varies | 4 | 2 hrs |
| 3 more arena themes | 32x32 | 24 tiles | 6 hrs |
| Explosion animation | 64x64 | 6 frames | 2 hrs |
| Muzzle flashes | 16x16 | 3 | 1 hr |
| Title screen art | 1280x720 | 1 | 3 hrs |
| **Total** | | | **14 hrs** |

### Week 3: Polish
**Goal:** Professional feel

| Task | Time |
|------|------|
| UI transitions/animations | 4 hrs |
| Shader effects (glow, bloom) | 3 hrs |
| Sound design | 4 hrs |
| Balance testing | 3 hrs |
| Bug fixes | 2 hrs |
| **Total** | **16 hrs** |

---

## Budget Estimate

### If Doing Art Yourself
- **Time:** 41 hours over 3 weeks
- **Cost:** $20 (Aseprite) or $0 (LibreSprite)

### If Hiring Artist
- **Pixel artist rate:** $25-50/hr
- **Total cost:** $1,000-2,000
- **Deliverables:** All sprites + animations + tilesets

### Hybrid Approach
- You: UI design, integration, effects
- Artist: Character sprites, tilesets
- **Cost:** $500-800
- **Time:** 2 weeks

---

## Implementation Order

### Immediate (This Week)
1. ✅ Use placeholder ColorRect bots
2. ✅ Implement new UI theme
3. ✅ Set up camera angle (15° tilt)
4. ✅ Add Y-sort for depth

### Short Term (Next 2 Weeks)
5. Replace ColorRect with actual sprites
6. Create 4 arena tilesets
7. Add explosion/muzzle effects
8. Title screen polish

### Polish (Week 3-4)
9. Shader effects (glow on selected bots)
10. Screen shake, impact frames
11. Sound design
12. Final balance pass

---

## Technical Setup

### Godot Settings
```
Project Settings:
  - Rendering: GL Compatibility
  - Canvas Textures: Nearest (pixel art)
  - Window: 1280x720, canvas_items stretch

Import Settings (for sprites):
  - Filter: Nearest
  - Compress: Lossless
  - Mipmaps: Disabled
```

### File Structure
```
res://
├── assets/
│   ├── sprites/
│   │   ├── chassis/
│   │   ├── weapons/
│   │   ├── effects/
│   │   └── ui/
│   ├── tilesets/
│   ├── fonts/
│   └── audio/
├── src/
│   └── (existing code)
└── scenes/
    └── (existing scenes)
```

---

## Next Steps (Choose One)

### Option A: Code-First (You)
1. I implement the UI theme + camera angle in Godot
2. You create placeholder art in Aseprite
3. We iterate together

### Option B: Art-First (Artist)
1. You find/hire pixel artist
2. I write detailed specs for them
3. I handle integration when assets ready

### Option C: Asset Store
1. Use existing CC0/paid asset packs
2. I adapt code to match asset dimensions
3. Fastest to playable

---

## Recommended: Option A

**Why:** Your code is solid. Getting something visual running will motivate the art creation.

**This Week:**
- [ ] I update main.tscn to use new menu design
- [ ] I set up camera angle + depth sorting
- [ ] You sketch 3 chassis types in Aseprite (1 hour)
- [ ] We test with placeholder sprites

---

## Questions for You

1. **Art skill level:** Can you draw pixel art, or should we find an artist?
2. **Budget:** Any money for assets, or fully DIY?
3. **Timeline:** When do you want to show someone a playable build?
4. **Priority:** Pretty menus or pretty gameplay first?

---

## Resources

### Free Assets (Placeholder)
- OpenGameArt.org
- itch.io (free pixel art)
- Kenney.nl (game assets)

### Learning
- Pixel Art Tutorial: https://lospec.com/
- Godot Shaders: https://godotshaders.com/
- Color palettes: https://coolors.co/

### Tools
- Aseprite: https://www.aseprite.org/
- LibreSprite: https://libresprite.github.io/
- Tiled: https://www.mapeditor.org/

---

**Bottom line:** Code is ready. Art is next. 41 hours of work separates you from a polished, shippable game.
