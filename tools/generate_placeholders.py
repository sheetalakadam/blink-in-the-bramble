#!/usr/bin/env python3
"""Generate placeholder pixel art for Blink in the Bramble.
All sprites use the correct dimensions so real art can drop in directly.
"""

from PIL import Image, ImageDraw, ImageFont
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Dark fantasy palette
PALETTE = {
    "bg_dark": (15, 12, 20),
    "bg_mid": (30, 25, 40),
    "grass": (35, 55, 35),
    "grass_light": (50, 75, 45),
    "stone": (60, 55, 65),
    "stone_light": (85, 80, 90),
    "water": (25, 40, 70),
    "water_light": (40, 60, 95),
    "sand": (75, 65, 45),
    "wood": (55, 35, 25),
    "corruption": (50, 15, 35),
    "threshold": (80, 70, 120),
}

# Character colors - distinct and readable
CHARS = {
    "zi":     {"body": (70, 85, 110), "accent": (120, 140, 170), "hair": (40, 35, 50)},
    "caelan": {"body": (90, 75, 120), "accent": (140, 120, 180), "hair": (60, 50, 80)},
    "suri":   {"body": (110, 80, 55), "accent": (160, 120, 80),  "hair": (45, 30, 20)},
    "rynn":   {"body": (55, 80, 55),  "accent": (85, 120, 75),   "hair": (35, 50, 30)},
    "lex":    {"body": (80, 80, 95),  "accent": (120, 115, 140), "hair": (55, 55, 65)},
    "vyn":    {"body": (70, 65, 60),  "accent": (100, 95, 85),   "hair": (50, 45, 40)},
}

ENEMIES = {
    "green_slime":       {"body": (45, 90, 40),  "accent": (65, 120, 55)},
    "valdrihn_soldier":  {"body": (80, 70, 60),  "accent": (110, 95, 80)},
    "valdrihn_scout":    {"body": (70, 75, 65),  "accent": (100, 105, 90)},
    "valdrihn_captain":  {"body": (95, 75, 55),  "accent": (130, 100, 70)},
    "solenne_scout":     {"body": (85, 70, 90),  "accent": (120, 100, 130)},
    "solenne_pickpocket": {"body": (75, 65, 85), "accent": (105, 90, 120)},
    "solenne_enforcer":  {"body": (90, 80, 70),  "accent": (125, 110, 95)},
    "ereivyn_wisp":      {"body": (60, 100, 90), "accent": (90, 140, 130)},
    "ereivyn_shade":     {"body": (50, 45, 70),  "accent": (75, 65, 100)},
    "ereivyn_thorn_beast": {"body": (55, 70, 40),"accent": (80, 100, 55)},
    "velundrath_guardian": {"body": (60, 75, 95), "accent": (85, 105, 135)},
    "velundrath_tide_caller": {"body": (45, 65, 90), "accent": (65, 90, 125)},
    "corrupted_husk":    {"body": (65, 30, 45),  "accent": (95, 45, 65)},
    "corrupted_fragment": {"body": (55, 25, 55), "accent": (80, 40, 80)},
    "corrupted_sentinel": {"body": (75, 35, 50), "accent": (105, 50, 70)},
}


def make_dirs():
    for d in [
        "assets/sprites/characters",
        "assets/sprites/enemies",
        "assets/portraits",
        "assets/tilesets",
    ]:
        os.makedirs(os.path.join(BASE, d), exist_ok=True)


def draw_character_sprite(name, colors, size=32):
    """32x32 character sprite sheet: 4 frames (idle, walk1, walk2, attack)"""
    sheet = Image.new("RGBA", (size * 4, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    for frame in range(4):
        x = frame * size
        body = colors["body"]
        accent = colors["accent"]
        hair = colors["hair"]

        if name == "vyn":
            # Wolf shape - lower, wider
            # Body
            draw.rectangle([x+8, y:=16, x+24, 26], fill=body)
            # Head
            draw.rectangle([x+4, 14, x+12, 20], fill=body)
            # Ears
            draw.point((x+5, 13), fill=accent)
            draw.point((x+10, 13), fill=accent)
            # Legs
            draw.rectangle([x+9, 26, x+12, 30], fill=accent)
            draw.rectangle([x+20, 26, x+23, 30], fill=accent)
            # Tail
            if frame % 2 == 0:
                draw.rectangle([x+24, 14, x+27, 17], fill=accent)
            else:
                draw.rectangle([x+24, 16, x+27, 19], fill=accent)
            # Eye
            draw.point((x+6, 16), fill=(200, 180, 100))
        else:
            # Humanoid shape
            bob = 1 if frame % 2 == 1 else 0

            # Head
            draw.rectangle([x+12, 4+bob, x+20, 12+bob], fill=body)
            # Hair
            draw.rectangle([x+11, 3+bob, x+21, 7+bob], fill=hair)
            # Eyes
            draw.point((x+14, 8+bob), fill=(200, 200, 200))
            draw.point((x+18, 8+bob), fill=(200, 200, 200))
            # Body
            draw.rectangle([x+11, 12+bob, x+21, 22+bob], fill=body)
            # Accent (belt/sash)
            draw.rectangle([x+11, 18+bob, x+21, 19+bob], fill=accent)

            # Legs - walking animation
            if frame == 0:  # idle
                draw.rectangle([x+12, 22+bob, x+15, 28+bob], fill=accent)
                draw.rectangle([x+17, 22+bob, x+20, 28+bob], fill=accent)
            elif frame == 1:  # walk1
                draw.rectangle([x+11, 22+bob, x+14, 28+bob], fill=accent)
                draw.rectangle([x+18, 22+bob, x+21, 28+bob], fill=accent)
            elif frame == 2:  # walk2
                draw.rectangle([x+13, 22+bob, x+16, 28+bob], fill=accent)
                draw.rectangle([x+16, 22+bob, x+19, 28+bob], fill=accent)
            else:  # attack - arm extended
                draw.rectangle([x+12, 22+bob, x+15, 28+bob], fill=accent)
                draw.rectangle([x+17, 22+bob, x+20, 28+bob], fill=accent)
                # Weapon/arm
                draw.rectangle([x+21, 10+bob, x+26, 13+bob], fill=accent)

            # Feet
            draw.rectangle([x+11, 28+bob, x+15, 30], fill=hair)
            draw.rectangle([x+17, 28+bob, x+21, 30], fill=hair)

    return sheet


def draw_enemy_sprite(name, colors, size=32):
    """32x32 enemy sprite - single frame"""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = colors["body"]
    accent = colors["accent"]

    if "slime" in name:
        # Blob shape
        draw.ellipse([6, 12, 26, 28], fill=body)
        draw.ellipse([8, 10, 24, 24], fill=accent)
        draw.point((12, 16), fill=(200, 200, 200))
        draw.point((20, 16), fill=(200, 200, 200))
    elif "wisp" in name or "fragment" in name:
        # Floating orb
        draw.ellipse([8, 8, 24, 24], fill=body)
        draw.ellipse([11, 11, 21, 21], fill=accent)
        # Glow dots
        for px, py in [(10, 6), (22, 6), (7, 15), (25, 15)]:
            draw.point((px, py), fill=(*accent, 128))
    elif "shade" in name:
        # Tall, thin, ghostly
        draw.polygon([(16, 4), (8, 28), (24, 28)], fill=body)
        draw.ellipse([11, 6, 21, 14], fill=accent)
        draw.point((13, 9), fill=(180, 180, 220))
        draw.point((19, 9), fill=(180, 180, 220))
    elif "captain" in name or "commander" in name or "sentinel" in name:
        # Large armored
        draw.rectangle([8, 4, 24, 12], fill=body)  # head
        draw.rectangle([6, 12, 26, 24], fill=body)  # body
        draw.rectangle([4, 14, 8, 22], fill=accent)  # shield
        draw.rectangle([24, 10, 28, 18], fill=accent)  # weapon
        draw.rectangle([8, 24, 14, 30], fill=accent)
        draw.rectangle([18, 24, 24, 30], fill=accent)
        draw.point((12, 8), fill=(200, 200, 200))
        draw.point((20, 8), fill=(200, 200, 200))
    elif "beast" in name:
        # Four-legged
        draw.rectangle([4, 12, 20, 20], fill=body)
        draw.rectangle([2, 8, 10, 14], fill=body)
        draw.rectangle([4, 20, 8, 28], fill=accent)
        draw.rectangle([16, 20, 20, 28], fill=accent)
        draw.point((4, 10), fill=(200, 180, 100))
        # Thorns
        for tx in [8, 12, 16]:
            draw.point((tx, 11), fill=accent)
    else:
        # Generic humanoid enemy
        draw.rectangle([11, 4, 21, 12], fill=body)
        draw.rectangle([9, 12, 23, 24], fill=body)
        draw.rectangle([10, 24, 14, 30], fill=accent)
        draw.rectangle([18, 24, 22, 30], fill=accent)
        draw.point((13, 7), fill=(200, 200, 200))
        draw.point((19, 7), fill=(200, 200, 200))
        # Weapon
        draw.rectangle([23, 8, 27, 20], fill=accent)

    return img


def draw_portrait(name, colors, size=64):
    """64x64 character portrait"""
    img = Image.new("RGBA", (size, size), PALETTE["bg_dark"])
    draw = ImageDraw.Draw(img)
    body = colors["body"]
    accent = colors["accent"]
    hair = colors["hair"]

    if name == "vyn":
        # Wolf face
        draw.polygon([(32, 8), (12, 48), (52, 48)], fill=body)
        draw.ellipse([18, 20, 30, 32], fill=accent)  # left eye area
        draw.ellipse([34, 20, 46, 32], fill=accent)  # right eye area
        draw.point((24, 26), fill=(200, 180, 100))
        draw.point((40, 26), fill=(200, 180, 100))
        draw.polygon([(22, 8), (16, 4), (20, 16)], fill=accent)  # ear
        draw.polygon([(42, 8), (48, 4), (44, 16)], fill=accent)  # ear
        draw.rectangle([28, 38, 36, 42], fill=hair)  # nose
    else:
        # Human face
        # Hair background
        draw.rectangle([14, 4, 50, 20], fill=hair)
        draw.rectangle([12, 8, 52, 16], fill=hair)
        # Face
        draw.rectangle([16, 14, 48, 50], fill=body)
        # Eyes
        draw.rectangle([20, 24, 28, 30], fill=(200, 200, 210))
        draw.rectangle([36, 24, 44, 30], fill=(200, 200, 210))
        draw.rectangle([22, 26, 26, 28], fill=PALETTE["bg_dark"])
        draw.rectangle([38, 26, 42, 28], fill=PALETTE["bg_dark"])
        # Mouth
        draw.rectangle([26, 38, 38, 40], fill=hair)
        # Collar/clothing hint
        draw.rectangle([14, 48, 50, 60], fill=accent)

        # Character-specific details
        if name == "zi":
            # Scar or military detail
            draw.line([(44, 18), (48, 26)], fill=accent, width=1)
        elif name == "caelan":
            # Faint glow on hands (threshold)
            draw.rectangle([10, 52, 18, 58], fill=(accent[0], accent[1], accent[2], 180))
        elif name == "suri":
            # Earring
            draw.point((14, 30), fill=(180, 150, 80))
        elif name == "lex":
            # Glasses hint
            draw.rectangle([19, 23, 29, 31], fill=None, outline=accent)
            draw.rectangle([35, 23, 45, 31], fill=None, outline=accent)
            draw.line([(29, 27), (35, 27)], fill=accent)

    # Border
    draw.rectangle([0, 0, 63, 63], outline=accent)

    return img


def draw_tileset():
    """16x16 tiles, arranged in a sheet"""
    tile_size = 16
    cols = 8
    tiles = []

    def make_tile(base_color, detail_color=None, pattern="solid"):
        t = Image.new("RGBA", (tile_size, tile_size), base_color)
        d = ImageDraw.Draw(t)
        if pattern == "grass":
            for px in range(0, 16, 3):
                for py in range(0, 16, 4):
                    if (px + py) % 5 != 0:
                        d.point((px, py), fill=detail_color)
        elif pattern == "stone":
            d.rectangle([0, 0, 15, 7], fill=base_color)
            d.rectangle([0, 8, 15, 15], fill=detail_color)
            d.line([(0, 7), (15, 7)], fill=PALETTE["bg_dark"])
            d.line([(8, 0), (8, 7)], fill=PALETTE["bg_dark"])
            d.line([(4, 8), (4, 15)], fill=PALETTE["bg_dark"])
            d.line([(12, 8), (12, 15)], fill=PALETTE["bg_dark"])
        elif pattern == "water":
            for py in range(0, 16, 3):
                d.line([(0, py), (15, py)], fill=detail_color)
        elif pattern == "sand":
            for px in range(0, 16, 4):
                for py in range(0, 16, 4):
                    d.point((px + (py % 2), py), fill=detail_color)
        elif pattern == "wood":
            for py in range(0, 16, 2):
                d.line([(0, py), (15, py)], fill=detail_color)
        elif pattern == "corrupt":
            d.rectangle([0, 0, 15, 15], fill=base_color)
            for px in range(0, 16, 2):
                for py in range(0, 16, 2):
                    if (px * py) % 7 == 0:
                        d.point((px, py), fill=detail_color)
        elif pattern == "path":
            d.rectangle([0, 0, 15, 15], fill=base_color)
            d.rectangle([2, 0, 13, 15], fill=detail_color)
        return t

    # Row 1: Ground types
    tiles.append(make_tile(PALETTE["grass"], PALETTE["grass_light"], "grass"))
    tiles.append(make_tile(PALETTE["grass_light"], PALETTE["grass"], "grass"))
    tiles.append(make_tile(PALETTE["stone"], PALETTE["stone_light"], "stone"))
    tiles.append(make_tile(PALETTE["stone_light"], PALETTE["stone"], "stone"))
    tiles.append(make_tile(PALETTE["water"], PALETTE["water_light"], "water"))
    tiles.append(make_tile(PALETTE["sand"], PALETTE["wood"], "sand"))
    tiles.append(make_tile(PALETTE["wood"], PALETTE["sand"], "wood"))
    tiles.append(make_tile(PALETTE["corruption"], PALETTE["threshold"], "corrupt"))

    # Row 2: Paths and edges
    tiles.append(make_tile(PALETTE["grass"], PALETTE["sand"], "path"))
    tiles.append(make_tile(PALETTE["stone"], PALETTE["stone_light"], "solid"))
    tiles.append(make_tile(PALETTE["bg_dark"], PALETTE["bg_mid"], "solid"))  # void/wall
    tiles.append(make_tile(PALETTE["bg_mid"], PALETTE["bg_dark"], "solid"))
    tiles.append(make_tile(PALETTE["threshold"], PALETTE["corruption"], "corrupt"))
    tiles.append(make_tile(PALETTE["grass"], PALETTE["corruption"], "corrupt"))  # corrupted grass
    tiles.append(make_tile(PALETTE["stone"], PALETTE["corruption"], "corrupt"))  # corrupted stone
    tiles.append(make_tile((0, 0, 0, 0),))  # transparent/empty

    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * tile_size, rows * tile_size), (0, 0, 0, 0))
    for i, tile in enumerate(tiles):
        x = (i % cols) * tile_size
        y = (i // cols) * tile_size
        sheet.paste(tile, (x, y))

    return sheet


def main():
    make_dirs()

    # Character sprites (32x32, 4-frame sheets)
    for name, colors in CHARS.items():
        sheet = draw_character_sprite(name, colors)
        path = os.path.join(BASE, f"assets/sprites/characters/{name}.png")
        sheet.save(path)
        print(f"  Created {path}")

    # Enemy sprites (32x32, single frame)
    for name, colors in ENEMIES.items():
        img = draw_enemy_sprite(name, colors)
        path = os.path.join(BASE, f"assets/sprites/enemies/{name}.png")
        img.save(path)
        print(f"  Created {path}")

    # Portraits (64x64)
    for name, colors in CHARS.items():
        img = draw_portrait(name, colors)
        path = os.path.join(BASE, f"assets/portraits/{name}.png")
        img.save(path)
        print(f"  Created {path}")

    # Tileset
    tileset = draw_tileset()
    path = os.path.join(BASE, "assets/tilesets/world_tiles.png")
    tileset.save(path)
    print(f"  Created {path}")

    # Palette file for Aseprite (.gpl format)
    gpl_path = os.path.join(BASE, "assets/blink_palette.gpl")
    with open(gpl_path, "w") as f:
        f.write("GIMP Palette\nName: Blink in the Bramble\nColumns: 4\n#\n")
        # Add all palette colors
        for name, (r, g, b) in PALETTE.items():
            f.write(f"{r:3d} {g:3d} {b:3d}\t{name}\n")
        # Add character colors
        for char_name, colors in CHARS.items():
            for part, (r, g, b) in colors.items():
                f.write(f"{r:3d} {g:3d} {b:3d}\t{char_name}_{part}\n")
    print(f"  Created {gpl_path}")

    print(f"\nDone! Generated:")
    print(f"  {len(CHARS)} character sprite sheets (32x32 x4 frames)")
    print(f"  {len(ENEMIES)} enemy sprites (32x32)")
    print(f"  {len(CHARS)} portraits (64x64)")
    print(f"  1 tileset (16x16 tiles, 8-column sheet)")
    print(f"  1 Aseprite palette (.gpl)")


if __name__ == "__main__":
    main()
