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
