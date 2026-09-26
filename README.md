# Sunrise Suite

A cozy 2D escape-room puzzle game. Juliette inherits the house by the sea of her grandmother Céline ("Mamie"), who loved sunrises, the market around the corner, and riddles. Mamie left one last treasure hunt: room by room through the house and back through her life, until the garden gate opens just as the sun comes up. The whole story is in [`docs/STORY.md`](docs/STORY.md).

**Play it in your browser: https://mabsteer.github.io/sunrise-suite/** (works on phones too; hold the phone sideways).

Made with [Godot 4.7](https://godotengine.org). The Windows version is built automatically on every push (see *Automatic builds* below).

## What's in the game
- **One route through the whole house**: kitchen → hall → bedroom → living room → garden → shed → front garden. Each room's door leads to the next, and each room is one period of Céline's life, going back in time from her last years to her childhood. The sun rises over the whole walk and clears the sea as you open the front garden gate.
- **Chloé**, Mamie's little white Maltese: she hides in the hall, and once Juliette finds her she follows her into every room. She fetches things from under furniture, digs in soft soil, follows a scent you give her, and barks at what matters. Some things she only does when she's happy: breakfast, water, her leash, her brush, Gaston the squeaky seagull.
- **Three walks**: Mamie's last treasure hunt (the story, seven hand-made rooms whose notes are her memories and riddles at once), then two harder walks with her old treasure hunts from the shoebox. Every room comes back harder.
- **Puzzles that make you think**: number codes, symbol tunes, clocks, lamps, things to put in order, little 4×4 number squares, "what comes next?" patterns, turning-tile and sliding-tile pictures, keys, tools and item combinations. From level 2 on no code is written out: Mamie's notes are riddles (count the shells in the jar, sums, patterns, logic), and one puzzle often gives the answer to the next. Keys are always the reward for a solved puzzle.
- **The sunrise is your progress bar**: every solved step brightens the sky.
- **Replay** any room with a fresh puzzle, and **Endless Sunrise** (round and round the house) after the three walks.
- **Daily Sunrise**: one puzzle a day (the same for everyone), a streak with a free weekly sleep-in, and a calendar that paints each finished day in its sky colours.
- **The sunroom**: earn seashells and make the house yours with 24 pieces of decor from the Saturday market.
- **Céline's scrapbook**: one page per chapter of her life, with the postcards and memories you found; her last letter at the end.
- **Stars**: finish (★), use at most one hint (★★), beat the par time (★★★).

## How to play
Tap (or click) things in the room to look closer. Things you pick up go into your bag at the bottom.
- Tap an item in the bag to select it, then tap something in the room to use it.
- Tap the selected item again to look at it.
- With one item selected, tap another to combine them (or drag one onto the other).
- Chloé: tap her to see what she needs, or she trots over and barks at what matters now. Select something in the bag and tap her to give it to her. In a spot with a paw badge, ask her to fetch or dig.
- Look closer: pinch (or use the mouse wheel, or the + and - buttons bottom left) to zoom in, drag to look around, and double-tap an empty spot to zoom in there or back out.
- Stuck? Mamie's notebook (top right) gives hints that get more specific each time.
- Keyboard: Esc closes things or pauses.

---

## Recipes: changing the game
You can change almost everything by editing a file and pushing it. The game rebuilds itself (see below). File formats are described in [`docs/DATA_FORMAT.md`](docs/DATA_FORMAT.md).

### Replace a picture (sprite)
All art is SVG (vector) in `assets/sprites/`: `rooms/`, `props/`, `items/`, `props/decor/`, `postcards/`, `ui/`.
1. Open the SVG in **Inkscape** (free) and edit it, or draw a new one at the **same size**.
2. Save it with the **same file name** (in Inkscape: *Save As → Plain SVG*).
3. Follow the rules in [`docs/ART_STYLE.md`](docs/ART_STYLE.md): no blur/shadow filters, masks, clipping or text. Draw shadows as see-through shapes instead.

### Add a decor item for the sunroom
1. Draw `assets/sprites/props/decor/my_item.svg`.
2. Add an entry to `data/decor.json` under `items`:
   `"my_item": {"name": "My item", "sprite": "props/decor/my_item.svg", "size": [200, 300], "slot": "floor_small", "price": 60, "text": "A short description."}`
   - `slot` is where it can go: `floor_large`, `floor_small`, `wall`, `table` or `rug`.
   - `price` is in seashells. Use `null` for items you can only earn, and add them to `data/rewards.json`.

### Make levels easier or harder
Edit `data/tiers.json`. Difficulty comes from thinking, not from searching. Each tier sets the number of steps, parallel puzzle chains, how deep the riddles go (`riddle` 0-4), how often one puzzle gives the code for the next (`chain`), which lock types appear, puzzle sizes and `par_time` (seconds for the third star). There's at most one search spot per level at every tier (`max_hidden`).
Riddle wording lives in `data/clues.json`. To read what the generator makes, print a level: `bash tools/godot.sh --headless --path . res://tests/validate_levels.tscn -- --print=kitchen:6:123`.
To change one specific main level, give it a different `seed` in `data/campaign.json`.
The checks print a time estimate per tier (how long a careful player needs without hints) and fail if a `par_time` is set below it, so the third star always stays within reach.

### Change a sound effect
Sounds are made with **jsfxr** from `tools/sfx/sfx.json`.
1. Open `tools/sfx/LINKS.md` and click a sound's **sfxr.me** link to hear it and tweak it in your browser.
2. Copy the new link, and paste the part after `#` into that sound's `"b58"` field in `sfx.json` (remove its `preset`, `seed` and `overrides`).
3. Run `npm run sfx` (needs Node.js). This rewrites the WAV files in `assets/audio/sfx/`.

### Add music (Suno)
Follow [`docs/SUNO_PROMPTS.md`](docs/SUNO_PROMPTS.md): make a track in Suno, name it exactly as listed (e.g. `menu_theme.mp3`) and put it in `assets/audio/music/`. Missing tracks are simply quiet.

### Edit story text
- Postcards and Mamie's last letter: `data/postcards.json` (`\n` starts a new line).
- Mamie's memories (the story notes in walk 1): `data/story.json`, under each chapter's `memories`. The story levels themselves are `data/levels/story_<room>.json`; if you change a riddle's answer there, change the memory text too. The whole story is in `docs/STORY.md`.
- Clue wording and decoy notes of the generated levels: `data/clues.json`.
- Tutorial guide bubbles: `data/tutorial.json`. The tutorial level itself: `data/levels/tutorial.json`.
- Menu and button text: `i18n/strings.csv` (the `en` column). Add a column to translate the game.

### Rooms
Each room is `data/rooms/<room>.json`: its pictures, where furniture stands, which furniture spots can hold locks or clues, and where props and items can be placed. Room pictures are 2400×1440 with the playable 1920×1080 in the middle. Windows are see-through holes, and the sunrise sky is drawn behind them (outdoors: the whole sky). The drawings were first made by the scripts in `tools/art/` (one per room: `kitchen.mjs`, `hall.mjs`, `bedroom.mjs`, `garden.mjs`, `shed.mjs`, `front_garden.mjs`); after that the SVG files are the real art, so edit them in Inkscape.
The order of the rooms, the walks and which postcard sits where are in `data/campaign.json`; the chapter titles and lines of Céline's life in `data/story.json`.

---

## Running it yourself
- **Play in the editor:** install Godot 4.7.2 (`winget install GodotEngine.GodotEngine`), open `project.godot`, press **F5**.
- **Run all checks** (what the automatic build runs), from Git Bash in this folder: `bash tools/check.sh`. It checks 2,100 generated puzzles locally; the automatic build checks 14,000 (`VALIDATE_SEEDS=200`).
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
