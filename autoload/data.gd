extends Node
## Loads and caches the human-editable JSON files in res://data/.
## Every file is documented in docs/DATA_FORMAT.md.

const DATA_DIR := "res://data/"

var _cache: Dictionary = {}


## Returns the parsed contents of res://data/<name>.json (cached). Returns null (and logs an error) if missing/invalid.
func get_json(name: String) -> Variant:
	if _cache.has(name):
		return _cache[name]
	var value: Variant = load_json_file(DATA_DIR + name + ".json")
	_cache[name] = value
	return value


## Like get_json, but always returns a Dictionary (empty on error).
func get_dict(name: String) -> Dictionary:
	var value: Variant = get_json(name)
	if value is Dictionary:
		return value
	if value != null:
		push_error("Data file %s.json should contain an object {...}" % name)
	return {}


## Drops the cache (used by tests and after editing data at runtime).
func clear_cache() -> void:
	_cache.clear()


static func load_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Data file missing: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("Invalid JSON in %s (line %d): %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data
