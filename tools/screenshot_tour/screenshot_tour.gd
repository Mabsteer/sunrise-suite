extends Node
## Visits every screen and saves PNG screenshots to tests/screenshots/, then quits.
##   bash tools/godot.sh --path . -- --screenshot-tour [--shots=lounge,menu]
## Must run with a real window (not --headless) so things are rendered.

const OUT_DIR := "res://tests/screenshots"
## 16:9 and a phone-like 20:9 (kept small enough to fit on any monitor).
const SIZES: Array[Vector2i] = [Vector2i(1600, 900), Vector2i(1560, 720)]


func _ready() -> void:
	SaveManager.persist = false
	_run.call_deferred()


func _shots() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"name": "main_menu", "screen": "main_menu"},
	]
	for room in ["lounge", "kitchen", "study"]:
		if not ResourceLoader.exists("res://data/rooms/%s.json" % room):
			continue
		for t in [0.0, 0.5, 1.0]:
			list.append({"name": "room_%s_t%02d" % [room, int(t * 10)], "screen": "room_preview", "params": {"room": room, "t": t}})
	var tour_extra := "res://tools/screenshot_tour/extra_shots.gd"
	if ResourceLoader.exists(tour_extra):
		var extra: Object = (load(tour_extra) as GDScript).new()
		var more: Array = extra.call("shots")
		for s: Dictionary in more:
			list.append(s)
	return list


func _run() -> void:
	var filter: PackedStringArray = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			filter = arg.trim_prefix("--shots=").split(",", false)
	var out := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(out)
	var ignore := FileAccess.open(out.path_join(".gdignore"), FileAccess.WRITE)
	if ignore:
		ignore.close()
	var count := 0
	get_window().mode = Window.MODE_WINDOWED
	for size in SIZES:
		get_window().size = size
		await _frames(8)
		for shot in _shots():
			var shot_name: String = shot["name"]
			if not filter.is_empty() and not _matches(shot_name, filter):
				continue
			SaveManager.data = SaveManager.default_save()
			if shot.has("setup"):
				(shot["setup"] as Callable).call()
			var params: Variant = shot.get("params", {})
			if params is Callable:
				params = (params as Callable).call()
			var ok: bool = await Router.goto(str(shot["screen"]), params, false)
			if not ok:
				push_warning("Screenshot tour: could not open %s" % shot["screen"])
				continue
			await _frames(4)
			if shot.has("action"):
				var action: Callable = shot["action"]
				await action.call(get_tree().current_scene)
			await _frames(int(shot.get("frames", 20)))
			var img := get_viewport().get_texture().get_image()
			var file := out.path_join("%s_%dx%d.png" % [shot_name, size.x, size.y])
			img.save_png(file)
			count += 1
	print("SCREENSHOTS: %d saved to %s" % [count, out])
	get_tree().quit()


static func _matches(shot_name: String, filter: PackedStringArray) -> bool:
	for f in filter:
		if shot_name.contains(f):
			return true
	return false


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
