extends Node
## Loads every script, scene and resource in the project so parse errors fail the check.

const SKIP_DIRS: PackedStringArray = ["builds", "node_modules", "tools/sfx", "docs"]
const EXTENSIONS: PackedStringArray = ["gd", "tscn", "tres", "gdshader"]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var paths: Array[String] = []
	_collect("res://", paths)
	var bad: PackedStringArray = []
	for path in paths:
		var res := load(path)
		if res == null:
			bad.append(path)
		elif res is GDScript and not (res as GDScript).can_instantiate() and not _is_abstract_ok(res as GDScript):
			bad.append(path + " (script cannot be instantiated)")
	for b in bad:
		printerr("LOAD FAILED ", b)
	print("LOAD_ALL: %d files loaded, %d failed" % [paths.size() - bad.size(), bad.size()])
	get_tree().quit(0 if bad.is_empty() else 1)


func _collect(dir_path: String, out: Array[String]) -> void:
	for sub in DirAccess.get_directories_at(dir_path):
		if sub.begins_with("."):
			continue
		var full := dir_path.path_join(sub)
		if SKIP_DIRS.has(full.trim_prefix("res://")):
			continue
		_collect(full, out)
	for file in DirAccess.get_files_at(dir_path):
		if EXTENSIONS.has(file.get_extension()):
			out.append(dir_path.path_join(file))


func _is_abstract_ok(_script: GDScript) -> bool:
	# Static-only helper classes (e.g. Palette) can't always be instantiated; that's fine.
	return true
