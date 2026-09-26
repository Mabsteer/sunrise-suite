# Sunrise Suite

A cozy 2D escape-room puzzle game. You're house-sitting for adventurous Grandma June in her beachside penthouse. Every morning she leaves a trail of riddles, and solving them opens the balcony door just as the sun comes up.

**Play it in your browser: https://mabsteer.github.io/sunrise-suite/** (works on phones too; hold the phone sideways).

Made with [Godot 4.7](https://godotengine.org). The Windows version is built automatically on every push (see *Automatic builds* below).

## What's in the game
- **30 sunrises** in Grandma's Sunrise Book: 3 rooms (Sunrise Lounge, Kitchen & Bar, Grandma's Study) × 10 difficulty tiers. Each room comes back harder.
- **8 kinds of locks**: number codes, symbol sequences (they play a little tune), keys, hidden spots, clocks, light switches, sliding-tile pictures and item combinations.
- **The sunrise is your progress bar**: every solved step brightens the sky.
- **Replay** any room with a fresh puzzle, and **Endless Sunrise** after the book is finished.
- **Daily Sunrise**: one puzzle a day (the same for everyone), a streak with a free weekly sleep-in, and a calendar that paints each finished day in its sky colours.
- **The penthouse**: earn seashells and decorate Grandma's home with 24 pieces of decor.
- **Grandma's postcards**: five hidden postcards tell her story. Find them all for a final letter.
- **Stars**: finish (★), use at most one hint (★★), beat the par time (★★★).

## How to play
Tap (or click) things in the room to look closer. Things you pick up go into your bag at the bottom.
- Tap an item in the bag to select it, then tap something in the room to use it.
- Tap the selected item again to look at it.
- With one item selected, tap another to combine them (or drag one onto the other).
- Stuck? Grandma's notepad (top right) gives hints that get more specific each time.
- Keyboard: Esc closes things or pauses.

---

## Recipes: changing the game
You can change almost everything by editing a file and pushing it. The game rebuilds itself (see below). File formats are described in [`docs/DATA_FORMAT.md`](docs/DATA_FORMAT.md).

### Replace a picture (sprite)
All art is SVG (vector) in `assets/sprites/`: `rooms/`, `props/`, `items/`, `props/decor/`, `postcards/`, `ui/`.
1. Open the SVG in **Inkscape** (free) and edit it, or draw a new one at the **same size**.
2. Save it with the **same file name** (in Inkscape: *Save As → Plain SVG*).
3. Follow the rules in [`docs/ART_STYLE.md`](docs/ART_STYLE.md): no blur/shadow filters, masks, clipping or text. Draw shadows as see-through shapes instead.

### Add a decor item for the penthouse
1. Draw `assets/sprites/props/decor/my_item.svg`.
2. Add an entry to `data/decor.json` under `items`:
   `"my_item": {"name": "My item", "sprite": "props/decor/my_item.svg", "size": [200, 300], "slot": "floor_small", "price": 60, "text": "A short description."}`
   - `slot` is where it can go: `floor_large`, `floor_small`, `wall`, `table` or `rug`.
   - `price` is in seashells. Use `null` for items you can only earn, and add them to `data/rewards.json`.

### Make levels easier or harder
Edit `data/tiers.json`. Each tier sets the number of steps, parallel puzzle chains, decoy notes, how cryptic clues are (`indirection` 0-3), which lock types appear, code length and `par_time` (seconds for the third star).
To change one specific main level, give it a different `seed` in `data/campaign.json`.

### Change a sound effect
Sounds are made with **jsfxr** from `tools/sfx/sfx.json`.
1. Open `tools/sfx/LINKS.md` and click a sound's **sfxr.me** link to hear it and tweak it in your browser.
2. Copy the new link, and paste the part after `#` into that sound's `"b58"` field in `sfx.json` (remove its `preset`, `seed` and `overrides`).
3. Run `npm run sfx` (needs Node.js). This rewrites the WAV files in `assets/audio/sfx/`.

### Add music (Suno)
Follow [`docs/SUNO_PROMPTS.md`](docs/SUNO_PROMPTS.md): make a track in Suno, name it exactly as listed (e.g. `menu_theme.mp3`) and put it in `assets/audio/music/`. Missing tracks are simply quiet.

### Edit story text
- Postcards and Grandma's final letter: `data/postcards.json` (`\n` starts a new line).
- Clue wording and decoy notes: `data/clues.json`.
- Tutorial guide bubbles: `data/tutorial.json`. The tutorial level itself: `data/levels/tutorial.json`.
- Menu and button text: `i18n/strings.csv` (the `en` column). Add a column to translate the game.

### Rooms
Each room is `data/rooms/<room>.json`: its pictures, where furniture stands, which furniture spots can hold locks or clues, and where props and items can be placed. Room pictures are 2400×1440 with the playable 1920×1080 in the middle. Windows are see-through holes, and the sunrise sky is drawn behind them.

---

## Running it yourself
- **Play in the editor:** install Godot 4.7.2 (`winget install GodotEngine.GodotEngine`), open `project.godot`, press **F5**.
- **Run all checks** (what the automatic build runs), from Git Bash in this folder: `bash tools/check.sh`
  - This imports assets, loads every script, runs the unit tests, opens every screen, generates and solves 6000 levels, lets a bot play 68 levels through the real UI, and exports the Web and Windows builds.
- **Screenshots of every screen:** `bash tools/tour.sh`, then look in `tests/screenshots/`.
- **Test the web build locally:** after `bash tools/check.sh`, run `node tools/serve_web.mjs` and open http://localhost:8060.

## Automatic builds
Every push to `main` runs `.github/workflows/build.yml` on GitHub:
1. It runs `tools/check.sh` in a Linux container with Godot 4.7.2.
2. It exports the **Web** and **Windows** builds. Both are downloadable from the run's *Artifacts* on the repository's **Actions** tab.
3. It publishes the web build to **GitHub Pages**: https://mabsteer.github.io/sunrise-suite/

If a check fails, the site keeps the last good version.

## Project layout
```
autoload/   game-wide systems: Events, Data, SaveManager, GameState, AudioManager, Daily, Router
scenes/     screens: main_menu, level_select, level (+ close-ups, inventory, tutorial), puzzles (lock widgets),
            hub, calendar, scrapbook, settings, room (RoomView + sky)
scripts/    level rules (LevelSession), generator + validator, solver, UI helpers
data/       all game content as JSON (rooms, tiers, clues, items, decor, postcards, campaign...)
assets/     sprites (SVG), audio, fonts, shaders, theme, palette
tests/      unit tests, level validator, autoplay bot, screen smoke test
tools/      check.sh, godot.sh, screenshot tour, sfx generator, art scripts
docs/       PROGRESS, DECISIONS, ART_STYLE, DATA_FORMAT, SUNO_PROMPTS
```

See [`CREDITS.md`](CREDITS.md) for fonts and tools.
