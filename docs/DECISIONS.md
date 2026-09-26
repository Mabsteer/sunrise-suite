# Decisions

One line per decision: what, and why.

- Godot 4.7.2 standard build + GDScript, Compatibility renderer: best web support; everything is text so it can be built unattended.
- Quality gate is a bash script (`tools/check.sh`), not PowerShell: PowerShell scripts are blocked by default on the dev PC, and the same script runs in Linux CI.
- The check runs a warm-up import on fresh checkouts: the first import always logs errors for files that haven't been imported yet (theme, fonts, translations).
- Custom tiny test runner (`tests/test_runner.tscn` + `TestCase`) instead of GUT: no third-party download, runs as a scene so autoloads are available.
- Tests run as scenes (`res://tests/*.tscn`), not `--script`, so autoloads behave exactly like in the game.
- Windows export embeds the .pck (single SunriseSuite.exe). `application/modify_resources=false` because CI runs on Linux without rcedit.
- Web export: single-threaded (no COOP/COEP headers on GitHub Pages).
- Exports include `*.json` explicitly so the data files are always packed.
- Audio buses are created at runtime by AudioManager (no bus layout file to keep in sync).
- Music crossfades a track's end into its own start (Suno tracks don't loop seamlessly), so native loop flags are turned off.
- Daily Sunrise uses UTC dates. The weekly sleep-in is keyed by weeks since 1970 starting on Monday.
- Fonts: Nunito (UI) and Caveat (Grandma's handwriting), both OFL from Google Fonts' GitHub.
- Room backgrounds are 2400x1440 with the 1920x1080 stage in the middle, so wide phones and tall tablets never see empty edges. Windows and doors are transparent holes, with the sky shader and silhouette layers behind them.
- One parameter (sunrise_t) drives sky, sun, sea, room tint, silhouettes, gulls and sunbeams, so the sunrise can be tweened as the level's progress bar.
- Outside silhouettes (palms, headland) are drawn white and tinted in code, so they follow the sunrise colours.
- Screenshot tour sizes are 1600x900 and 1560x720 (16:9 and ~20:9) instead of full 1920/2340 widths, so the window always fits on the monitor.
- tools/tour.sh re-imports before the tour, because running the game directly uses stale imported textures after an SVG edit.
