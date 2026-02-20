#!/usr/bin/env python3
"""
Standalone PNG Generator for Ironcore Arena
Generates sprite assets without running Godot

Usage:
    python3 png_generator.py

Output:
    assets/sprites/v2/ - Chassis and weapon sprites
    assets/tilesets/training_grounds/ - Arena tiles
"""

from PIL import Image, ImageDraw
import os

# Color Palette (from DESIGN_SYSTEM.md)
PALETTE = {
    "navy_dark": (15, 20, 25),
    "navy": (26, 31, 46),
    "navy_light": (37, 43, 61),
    "slate": (61, 69, 84),
    "cyan": (0, 212, 255),
    "cyan_glow": (128, 234, 255),
    "orange": (255, 107, 53),
    "green": (46, 204, 113),
    "red": (231, 76, 60),
    "yellow": (241, 196, 15),
    "purple": (155, 89, 182),
    "white": (255, 255, 255),
    "black": (5, 5, 5),
    "grey": (128, 128, 128),
}

# Team colors
def get_team_color(team):
    if team == "player":
        return PALETTE["green"]
    elif team == "enemy":
        return PALETTE["yellow"]
    return PALETTE["grey"]

def darken(color, factor=0.2):
    """Darken a color"""
    return tuple(int(c * (1 - factor)) for c in color)

def lighten(color, factor=0.2):
    """Lighten a color"""
    return tuple(min(255, int(c + (255 - c) * factor)) for c in color)

def blend_colors(color1, color2, alpha):
    """Blend two colors with alpha"""
    return tuple(int(c1 * (1 - alpha) + c2 * alpha) for c1, c2 in zip(color1, color2))

def draw_circle(draw, center, radius, color):
    """Draw a filled circle"""
    x, y = center
    draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=color)

def draw_rounded_rect(draw, bbox, radius, color):
    """Draw a rounded rectangle"""
    x1, y1, x2, y2 = bbox
    # Main rectangle
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=color)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=color)
    # Corners
    draw.pieslice([x1, y1, x1 + radius * 2, y1 + radius * 2], 180, 270, fill=color)
    draw.pieslice([x2 - radius * 2, y1, x2, y1 + radius * 2], 270, 360, fill=color)
    draw.pieslice([x1, y2 - radius * 2, x1 + radius * 2, y2], 90, 180, fill=color)
    draw.pieslice([x2 - radius * 2, y2 - radius * 2, x2, y2], 0, 90, fill=color)

def create_chassis_sprite(chassis_type, team, size=64):
    """Generate a chassis sprite"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    base_color = get_team_color(team)
    center = size // 2
    
    # Determine shape and size based on chassis type
    if chassis_type == "scout":
        radius = size * 0.35
        shape = "diamond"
    elif chassis_type == "fighter":
        radius = size * 0.4
        shape = "circle"
    else:  # tank
        radius = size * 0.45
        shape = "square"
    
    # Draw shadow (offset down-right)
    shadow_offset = 4
    shadow_color = (0, 0, 0, 64)  # 25% alpha
    
    if shape == "circle":
        draw_circle(draw, (center + shadow_offset, center + shadow_offset), radius, shadow_color)
    elif shape == "square":
        draw_rounded_rect(draw, 
            (center - radius + shadow_offset, center - radius + shadow_offset,
             center + radius + shadow_offset, center + radius + shadow_offset),
            6, shadow_color)
    else:  # diamond
        points = [
            (center + shadow_offset, center - radius + shadow_offset),
            (center + radius + shadow_offset, center + shadow_offset),
            (center + shadow_offset, center + radius + shadow_offset),
            (center - radius + shadow_offset, center + shadow_offset)
        ]
        draw.polygon(points, fill=shadow_color)
    
    # Draw base shape
    if shape == "circle":
        draw_circle(draw, (center, center), radius, base_color)
    elif shape == "square":
        draw_rounded_rect(draw, 
            (center - radius, center - radius, center + radius, center + radius),
            6, base_color)
    else:  # diamond
        points = [
            (center, center - radius),
            (center + radius, center),
            (center, center + radius),
            (center - radius, center)
        ]
        draw.polygon(points, fill=base_color)
    
    # Add highlight (upper left)
    highlight_color = lighten(base_color, 0.3)
    highlight_radius = radius * 0.4
    highlight_center = (center - radius * 0.3, center - radius * 0.3)
    
    if shape == "circle":
        # Soft radial highlight
        for r in range(int(highlight_radius), 0, -1):
            alpha = 0.4 * (r / highlight_radius)
            col = blend_colors(base_color, highlight_color, alpha)
            draw_circle(draw, highlight_center, r, col)
    
    # Add center detail (sensor)
    detail_radius = radius * 0.25
    detail_color = lighten(base_color, 0.5)
    draw_circle(draw, (center, center), detail_radius, detail_color)
    
    # Add panel lines
    line_color = darken(base_color, 0.2)
    if shape == "circle":
        # Simple ring detail
        draw.ellipse([center - radius * 0.7, center - radius * 0.7,
                      center + radius * 0.7, center + radius * 0.7],
                     outline=line_color, width=1)
    elif shape == "square":
        # Corner details
        for dx, dy in [(-1, -1), (1, -1), (-1, 1), (1, 1)]:
            x = center + dx * radius * 0.6
            y = center + dy * radius * 0.6
            draw.rectangle([x - 2, y - 2, x + 2, y + 2], fill=line_color)
    
    return img

def create_weapon_sprite(weapon_type, size=32):
    """Generate a weapon sprite"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    base_color = PALETTE["slate"]
    accent_color = PALETTE["orange"]
    
    center_x, center_y = size // 2, size // 2
    
    if weapon_type == "machine_gun":
        # Body
        draw.rectangle([8, 12, 16, 20], fill=darken(base_color, 0.1))
        # Barrel
        draw.rectangle([16, 15, 28, 17], fill=base_color)
        # Muzzle
        draw.rectangle([28, 14, 30, 18], fill=accent_color)
        
    elif weapon_type == "cannon":
        # Thick barrel
        draw.rectangle([4, 12, 24, 20], fill=base_color)
        # Muzzle brake
        draw.rectangle([22, 10, 28, 22], fill=darken(base_color, 0.2))
        # Glow tip
        draw.rectangle([26, 13, 30, 19], fill=darken(accent_color, 0.3))
        
    elif weapon_type == "launcher":
        # Tube
        draw.rectangle([6, 10, 22, 22], fill=darken(base_color, 0.1))
        # Rim
        draw.rectangle([20, 8, 26, 24], fill=base_color)
        # Inner
        draw.rectangle([22, 12, 24, 20], fill=darken(accent_color, 0.3))
        
    elif weapon_type == "beam":
        # Emitter
        draw.rectangle([4, 12, 12, 20], fill=base_color)
        # Beam path
        for x in range(12, 30):
            alpha = int(255 * (1 - (x - 12) / 18))
            draw.line([(x, 15), (x, 17)], fill=(*accent_color, alpha))
        # Core
        draw.line([(14, 16), (28, 16)], fill=PALETTE["white"])
        
    elif weapon_type == "sniper":
        # Long barrel
        draw.rectangle([2, 15, 28, 17], fill=base_color)
        # Scope
        draw.rectangle([10, 10, 16, 14], fill=darken(base_color, 0.2))
        # Stock
        draw.rectangle([2, 13, 10, 19], fill=darken(base_color, 0.15))
        
    elif weapon_type == "shotgun":
        # Double barrel
        draw.rectangle([12, 10, 24, 13], fill=base_color)
        draw.rectangle([12, 19, 24, 22], fill=base_color)
        # Body
        draw.rectangle([4, 10, 12, 22], fill=darken(base_color, 0.2))
    
    return img

def create_tile(color, size=32, pattern=None):
    """Generate a tile"""
    img = Image.new('RGBA', (size, size), color)
    draw = ImageDraw.Draw(img)
    
    if pattern == "grid":
        # Grid lines
        line_color = darken(color, 0.1)
        for i in range(0, size, 8):
            draw.line([(i, 0), (i, size)], fill=line_color, width=1)
            draw.line([(0, i), (size, i)], fill=line_color, width=1)
    
    elif pattern == "dots":
        # Dots
        dot_color = darken(color, 0.15)
        for x in range(4, size, 8):
            for y in range(4, size, 8):
                draw.ellipse([x-1, y-1, x+1, y+1], fill=dot_color)
    
    return img

def create_spawn_marker(team, size=32):
    """Generate spawn marker"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    color = get_team_color(team)
    center = size // 2
    
    # Circle marker
    draw.ellipse([4, 4, size-4, size-4], outline=color, width=3)
    
    # Inner symbol
    if team == "player":
        # Triangle pointing up
        draw.polygon([(center, 8), (size-8, size-8), (8, size-8)], fill=color)
    else:
        # X shape
        draw.line([(8, 8), (size-8, size-8)], fill=color, width=3)
        draw.line([(size-8, 8), (8, size-8)], fill=color, width=3)
    
    return img

def main():
    """Generate all MVP assets"""
    print("=" * 50)
    print("IRONCORE ARENA - PNG Generator")
    print("=" * 50)
    
    # Create directories
    os.makedirs("assets/sprites/v2", exist_ok=True)
    os.makedirs("assets/tilesets/training_grounds", exist_ok=True)
    
    # Generate chassis sprites
    print("\n[1/3] Generating chassis sprites...")
    for chassis_type in ["scout", "fighter", "tank"]:
        for team in ["player", "enemy"]:
            size = 40 if chassis_type == "scout" else (48 if chassis_type == "fighter" else 56)
            img = create_chassis_sprite(chassis_type, team, size=size)
            path = f"assets/sprites/v2/chassis_{chassis_type}_{team}.png"
            img.save(path)
            print(f"  ✓ {path}")
    
    # Generate weapon sprites
    print("\n[2/3] Generating weapon sprites...")
    for weapon_type in ["machine_gun", "cannon", "launcher", "beam", "sniper", "shotgun"]:
        img = create_weapon_sprite(weapon_type, size=32)
        path = f"assets/sprites/v2/weapon_{weapon_type}.png"
        img.save(path)
        print(f"  ✓ {path}")
    
    # Generate tiles
    print("\n[3/3] Generating tileset...")
    
    # Training Grounds theme colors
    floor_base = (38, 46, 38)  # Greenish gray
    wall_color = (102, 115, 102)  # Gray
    
    tiles = {
        "floor_0.png": create_tile(floor_base, pattern=None),
        "floor_1.png": create_tile(lighten(floor_base, 0.05), pattern=None),
        "floor_2.png": create_tile(darken(floor_base, 0.05), pattern=None),
        "floor_grid.png": create_tile(floor_base, pattern="grid"),
        "floor_dots.png": create_tile(floor_base, pattern="dots"),
        "wall_top.png": create_tile(wall_color),
        "wall_bottom.png": create_tile(darken(wall_color, 0.1)),
        "wall_left.png": create_tile(darken(wall_color, 0.05)),
        "wall_right.png": create_tile(darken(wall_color, 0.05)),
        "spawn_player.png": create_spawn_marker("player"),
        "spawn_enemy.png": create_spawn_marker("enemy"),
    }
    
    for filename, img in tiles.items():
        path = f"assets/tilesets/training_grounds/{filename}"
        img.save(path)
        print(f"  ✓ {path}")
    
    print("\n" + "=" * 50)
    print("COMPLETE! Generated assets:")
    print(f"  - 6 chassis sprites")
    print(f"  - 6 weapon sprites")
    print(f"  - {len(tiles)} tiles")
    print("=" * 50)
    print("\nAssets location:")
    print("  project/assets/sprites/v2/")
    print("  project/assets/tilesets/training_grounds/")

if __name__ == "__main__":
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("ERROR: Pillow not installed.")
        print("Install with: pip3 install Pillow")
        exit(1)
    
    main()
