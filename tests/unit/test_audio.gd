extends TestCase
## Every sound effect the code asks for must exist (generated from tools/sfx/sfx.json).

const CODE_DIRS: PackedStringArray = ["res://autoload", "res://scenes", "res://scripts"]


func test_every_played_sound_exists() -> void:
	var re := RegEx.new()
	re.compile("play_sfx\\(\"([a-z0-9_]+)\"\\s*[,)]")
	var names := {}
	for dir in CODE_DIRS:
		for path in _scripts(dir):
			for m in re.search_all(FileAccess.get_file_as_string(path)):
				names[m.get_string(1)] = path
	assert_true(names.size() > 20, "found the sound names used in code")
	for sfx_name: String in names.keys():
		assert_true(AudioManager.has_sfx(sfx_name), "sound '%s' (used in %s) exists" % [sfx_name, names[sfx_name]])


func test_star_and_note_sounds_exist() -> void:
	for i in [1, 2, 3]:
		assert_true(AudioManager.has_sfx("star_%d" % i))
	for symbol: String in Data.get_dict("symbols").keys():
		if not symbol.begins_with("_"):
			assert_true(AudioManager.has_sfx("note_" + symbol), "note for %s" % symbol)


func test_music_tracks_are_listed_in_suno_doc() -> void:
	var doc := FileAccess.get_file_as_string("res://docs/SUNO_PROMPTS.md")
	for track in ["menu_theme", "hub_penthouse", "level_kitchen", "level_hall", "level_bedroom", "level_lounge", "level_garden", "level_shed", "level_front_garden", "daily_sunrise", "sunrise_stinger", "ambience_ocean"]:
		assert_true(doc.contains("`%s`" % track), "%s is documented for the owner" % track)


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(sub)))
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	return out


func test_audio_status_reports_buses_and_recent_sounds() -> void:
	AudioManager.play_sfx("ui_click")
	var st := AudioManager.audio_status()
	for key in ["enabled", "buses", "recent", "web_audio"]:
		assert_true(st.has(key), "audio status has %s" % key)
	assert_true((st["buses"] as Dictionary).has("SFX"), "the SFX bus is listed")
	assert_eq((st["recent"] as Array).back(), "ui_click", "the last sound is remembered")


func test_settings_have_a_test_sound_button() -> void:
	var panel := SettingsPanel.new()
	tree.root.add_child(panel)
	var found := false
	for b in panel.find_children("*", "Button", true, false):
		if (b as Button).tooltip_text == tr("SETTINGS_TEST_SOUND"):
			found = true
	panel.free()
	assert_true(found, "a test-sound button sits next to the sound effects slider")
