# Art style

**Mood:** a cozy old house by the sea at dawn (see docs/STORY.md). Flat vector, soft rounded shapes, gentle gradients, warm light.

## Palette
All colours come from `assets/palette.json` (scripts read them via `Palette.color("coral")`). Use these hex values in SVGs:

| Name | Hex | Use |
|---|---|---|
| indigo_deep / indigo | `#2b2350` / `#3e3570` | night sky, silhouettes, deep shadows |
| lavender / lavender_light | `#9c8ac4` / `#c9bde3` | dawn sky, cool accents |
| peach / peach_light | `#f9b98a` / `#fcd9b8` | sunrise glow, cushions, highlights |
| coral / coral_dark | `#ee7b6b` / `#c95b52` | accents, buttons, books |
| gold / gold_light | `#f6c453` / `#fbe3a0` | sun, brass highlights, stars |
| sand / cream / white_warm | `#f3ddb3` / `#fff4e2` / `#fffbf5` | walls, paper, frames |
| sea_teal / sea_deep / sea_light | `#2e8c8c` / `#1f5f6b` / `#6cc2be` | sea, ceramics, accents |
| terracotta / terracotta_light | `#c8674a` / `#e08e6d` | pots, tiles, rugs |
| sage / sage_dark | `#8faf8a` / `#5e7f5e` | plants |
| wood_light / wood / wood_dark | `#c99a6b` / `#a8744a` / `#7a5134` | furniture, floors |
| brass / brass_dark | `#d4a24c` / `#a87a2e` | handles, locks, frames |
| ink / ink_soft | `#3b2e3a` / `#6b5a66` | text, darkest details |

## Shapes and shading
- **No outlines.** Edges come from 2–3 value steps: base colour, a darker side/underside band, and a light highlight strip.
- Round corners generously (`rx` 6–24 on furniture, 3–6 on small items).
- Shadows are separate shapes in `#3b2e3a` at 12–25% opacity (ellipse under furniture, band under shelves). Never use SVG filters.
- Highlights are `#fffbf5` at 30–60% opacity.
- Gradients: at most 2–3 stops, subtle (e.g. wall cream → sand). Prefer linear.

## Technical rules (Godot's ThorVG importer)
- Allowed: `path`, `rect`, `circle`, `ellipse`, `polygon`, `polyline`, `line`, `g`, `linearGradient`, `radialGradient`, `opacity`, `fill-opacity`, `stroke` (for simple lines), `transform` (translate/rotate/scale).
- **Not allowed:** filters (blur, drop-shadow), masks, clip-paths, `<text>`, `<style>`/CSS classes, `<use>` referencing other files, embedded bitmaps.
- Always set `viewBox` and matching `width`/`height`. Gradient ids must be unique inside a file.

## Scale and placement
- The game stage is **1920 × 1080**. Sprites are drawn **at stage size** (1 SVG unit = 1 stage pixel), imported at scale 1.0.
- **Room backgrounds** use `viewBox="-240 -180 2400 1440"`. The central 1920 × 1080 is the safe area where all interactive things go. The margins cover wider phones and taller tablets.
  - Windows and the balcony door are **transparent holes** in the background, so the sky shader and view layers show through.
  - Floor line (where the wall meets the floor) is at y = 760.
- **Props / furniture**: the viewBox starts at `0 0`. Its size is the sprite's size on stage. Room JSON gives each prop's top-left `pos`.
- **Items** (inventory objects) are 128 × 128. **Close-up art** is up to 900 × 700.
- File names are `snake_case.svg`. The name is the id used in data files.

## Replacing art
Overwrite the SVG with a new one of the **same name and size** (Inkscape works well; save as *Plain SVG*). Keep to the technical rules above, then run the game or `bash tools/check.sh`.
