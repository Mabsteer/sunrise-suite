extends TestCase
## Every text key the code asks for must exist in i18n/strings.csv, and keys that are
## formatted with % must have a placeholder (otherwise the raw key or a script error shows up in game).

const CODE_DIRS: PackedStringArray = ["res://autoload", "res://scenes", "res://scripts"]


func test_every_used_key_exists() -> void:
	var strings := _strings()
	assert_true(strings.size() > 100, "read the strings file")
	var used := _used_keys()
	assert_true(used.size() > 100, "found the keys used in code")
	for key: String in used.keys():
		assert_true(strings.has(key), "text key '%s' (used in %s) is in i18n/strings.csv" % [key, used[key]["path"]])


func test_formatted_keys_have_placeholders() -> void:
	var strings := _strings()
	var used := _used_keys()
	for key: String in used.keys():
		if bool(used[key]["formatted"]) and strings.has(key):
			var text: String = strings[key]
			assert_true(text.contains("%s") or text.contains("%d"), "'%s' is formatted with %% in %s, so its text needs a %%s or %%d" % [key, used[key]["path"]])


## { key: text } from the English column.
func _strings() -> Dictionary:
	var out := {}
	var f := FileAccess.open("res://i18n/strings.csv", FileAccess.READ)
	if f == null:
		return out
	f.get_csv_line()  # header
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 2 and row[0] != "":
			out[row[0]] = row[1]
	return out


## { key: {"path": first file using it, "formatted": true if any use is followed by %} }
func _used_keys() -> Dictionary:
	var re := RegEx.new()
	re.compile("(?:\\btr|TranslationServer\\.translate)\\(\"([A-Z][A-Z0-9_]+)\"\\)(\\s*%)?")
	var out := {}
	for dir in CODE_DIRS:
		for path in _scripts(dir):
			for m in re.search_all(FileAccess.get_file_as_string(path)):
				var key := m.get_string(1)
				var entry: Dictionary = out.get(key, {"path": path, "formatted": false})
				if m.get_string(2) != "":
					entry["formatted"] = true
				out[key] = entry
	return out


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(sub)))
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	return out
