extends Node
## Reads and writes the player's progress (user://save.json) and settings (user://settings.json).
## Both files are versioned; older saves are migrated and missing keys are filled from defaults.

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.json"
const SAVE_VERSION := 2
const SETTINGS_VERSION := 1

var data: Dictionary = {}
var settings: Dictionary = {}
## When false nothing is written to disk (used by tests).
var persist := true


func _ready() -> void:
	load_all()


func load_all() -> void:
	data = _read_json(SAVE_PATH, default_save())
	data = migrate_save(data)
	settings = _merge_defaults(_read_json(SETTINGS_PATH, {}), default_settings())
	settings["version"] = SETTINGS_VERSION


func default_save() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		## level_id -> { "stars": int, "best_time": float, "completions": int, "fewest_hints": int }
		"levels": {},
		"seashells": 0,
		"seashells_earned": 0,
		## decor_id -> count owned
		"decor_owned": {},
		## hub slot id -> { "id": decor_id, "flipped": bool }
		"decor_placed": {},
		"postcards": [],
		## memory ids from data/story.json the player has read
		"memories": [],
		## Chloé was found in the hall and follows Juliette
		"chloe_found": false,
		"final_letter_read": false,
		"daily": {
			## "YYYY-MM-DD" -> { "stars": int, "time": float }
			"completed": {},
			"streak": 0,
			"best_streak": 0,
			"last_day": "",
			## ISO week key "YYYY-Www" -> true when that week's free sleep-in was used
			"sleep_ins": {},
		},
		"endless": {"cleared": 0, "best_tier": 0},
		"replays": 0,
		"tutorial_done": false,
		"rewards_claimed": [],
	}


func default_settings() -> Dictionary:
	return {
		"version": SETTINGS_VERSION,
		"volume_master": 0.9,
		"volume_music": 0.55,
		"volume_sfx": 0.8,
		"volume_ambience": 0.6,
		"fullscreen": false,
		"text_scale": 1.0,
		"reduce_motion": false,
		"show_timer": false,
	}


## Brings any older save up to SAVE_VERSION and fills missing keys.
func migrate_save(save: Dictionary) -> Dictionary:
	var version := int(save.get("version", 0))
	if version < 2 and save.has("levels"):
		# v2: the 30 "main_XX" levels became walks through Céline's house (new ids, new rooms).
		# Level progress and Endless start over; seashells, decor, postcards and the daily streak stay.
		save["levels"] = {}
		save["endless"] = {}
		save["final_letter_read"] = false
		version = 2
	if version > SAVE_VERSION:
		push_warning("Save file is from a newer version (%d); loading what we can." % version)
	var merged := _merge_defaults(save, default_save())
	merged["version"] = SAVE_VERSION
	return merged


## Applies window settings (fullscreen). On the web this only works from a button press.
func apply_display() -> void:
	var want := bool(settings.get("fullscreen", false))
	var mode := DisplayServer.window_get_mode()
	var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if want != is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if want else DisplayServer.WINDOW_MODE_WINDOWED)


func save_game() -> void:
	_write_json(SAVE_PATH, data)


func save_settings() -> void:
	_write_json(SETTINGS_PATH, settings)
	Events.settings_changed.emit()


func reset_progress() -> void:
	data = default_save()
	save_game()


func _read_json(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_warning("Could not read %s, starting fresh." % path)
	return fallback.duplicate(true)


func _write_json(path: String, value: Dictionary) -> void:
	if not persist:
		return
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s (error %d)" % [tmp, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(value, "\t"))
	file.close()
	var dir := DirAccess.open("user://")
	if dir == null or dir.rename(tmp.trim_prefix("user://"), path.trim_prefix("user://")) != OK:
		# Fall back to writing the file directly.
		var direct := FileAccess.open(path, FileAccess.WRITE)
		if direct != null:
			direct.store_string(JSON.stringify(value, "\t"))
			direct.close()


## Recursively adds keys from `defaults` that are missing in `value`. Existing values win.
static func _merge_defaults(value: Dictionary, defaults: Dictionary) -> Dictionary:
	var result := value.duplicate(true)
	for key: Variant in defaults.keys():
		if not result.has(key):
			result[key] = defaults[key].duplicate(true) if defaults[key] is Dictionary or defaults[key] is Array else defaults[key]
		elif result[key] is Dictionary and defaults[key] is Dictionary and not (defaults[key] as Dictionary).is_empty():
			result[key] = _merge_defaults(result[key], defaults[key])
	return result
