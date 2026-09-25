class_name Palette
extends RefCounted
## Named colours from res://assets/palette.json, shared by scripts, shaders and SVG art.

const PALETTE_PATH := "res://assets/palette.json"

static var _colors: Dictionary = {}


## Returns the palette colour called `name` (magenta if unknown, so mistakes are visible).
static func color(name: String, alpha: float = -1.0) -> Color:
	if _colors.is_empty():
		_load()
	var c: Color = _colors.get(name, Color.MAGENTA)
	if not _colors.has(name):
		push_warning("Palette has no colour named '%s'" % name)
	if alpha >= 0.0:
		c.a = alpha
	return c


static func has(name: String) -> bool:
	if _colors.is_empty():
		_load()
	return _colors.has(name)


static func _load() -> void:
	var raw: Variant = null
	if FileAccess.file_exists(PALETTE_PATH):
		raw = JSON.parse_string(FileAccess.get_file_as_string(PALETTE_PATH))
	if not raw is Dictionary:
		push_error("Could not read %s" % PALETTE_PATH)
		return
	var dict: Dictionary = raw
	for key: String in dict.keys():
		if key.begins_with("_"):
			continue
		_colors[key] = Color.from_string(str(dict[key]), Color.MAGENTA)
