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
	for track in ["menu_theme", "hub_penthouse", "level_lounge", "level_kitchen", "level_study", "daily_sunrise", "sunrise_stinger", "ambience_ocean"]:
		assert_true(doc.contains("`%s`" % track), "%s is documented for the owner" % track)


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(sub)))
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	return out
