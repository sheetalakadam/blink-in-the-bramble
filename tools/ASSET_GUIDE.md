# Art Asset Guide — Blink in the Bramble

## Dimensions

| Asset Type | Size | Format | Location |
|-----------|------|--------|----------|
| Character sprites | 32x32 per frame, 4 frames (128x32 sheet) | PNG, RGBA | `assets/sprites/characters/{name}.png` |
| Enemy sprites | 32x32 single frame | PNG, RGBA | `assets/sprites/enemies/{name}.png` |
| Portraits | 64x64 | PNG, RGBA | `assets/portraits/{name}.png` |
| Tiles | 16x16 per tile, 8-column sheet | PNG, RGBA | `assets/tilesets/world_tiles.png` |

## Character Sprite Sheet Layout (128x32)

```
[Frame 0: Idle] [Frame 1: Walk1] [Frame 2: Walk2] [Frame 3: Attack]
  32x32            32x32            32x32            32x32
```

## Palette

`assets/blink_palette.gpl` — load in Aseprite via Edit > Open Palette.

Dark fantasy palette: muted greens, deep purples, warm amber. Each character has body/accent/hair colors.

## How to Replace

1. Open the placeholder PNG in Aseprite
2. Draw over it at the same dimensions
3. Export as PNG to the same path
4. The game's SpriteLoader picks it up automatically

Or: create a new file at the same path and dimensions.

## Characters

- **zi.png** — Blue-grey tones. Military posture. Short dark hair.
- **caelan.png** — Purple tones. Uncertain stance. Faint glow on hands.
- **suri.png** — Warm brown/amber. Confident. Earring.
- **rynn.png** — Forest green. Practical clothes, heavy pack.
- **lex.png** — Grey/lavender. Glasses. Notebooks visible.
- **vyn.png** — Brown/grey. Wolf. Lower, wider silhouette.

## Regenerating Placeholders

```bash
python3 tools/generate_placeholders.py
```
