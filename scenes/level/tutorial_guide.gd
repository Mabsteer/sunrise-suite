class_name TutorialGuide
extends PanelContainer
## Shows step-by-step guide bubbles (data/tutorial.json) during the tutorial level, advancing on game events.

var level_scene: LevelScene
var _steps: Array = []
var _index := 0
var _label: RichTextLabel
var _sparkle_timer := 0.0


func setup(scene: LevelScene) -> void:
	level_scene = scene
	_steps = Data.get_dict("tutorial").get("steps", [])
	add_theme_stylebox_override("panel", UIKit.paper(26))
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -600
	offset_right = 600
	offset_top = 130
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	add_child(h)
	var icon := TextureRect.new()
	icon.texture = UIKit.texture("ui/hint.svg")
	icon.custom_minimum_size = Vector2(72, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(icon)
	_label = UIKit.handwriting("", 40)
	_label.custom_minimum_size.x = 1040
	h.add_child(_label)
	var s := scene.session
	s.clue_seen.connect(func(id: String) -> void: _event("clue_seen:" + id))
	s.lock_opened.connect(func(id: String) -> void: _event("lock_opened:" + id))
	s.item_picked.connect(func(id: String) -> void: _event("item_picked:" + id))
	s.items_combined.connect(func(_a: String, _b: String, _r: String) -> void: _event("combined"))
	s.completed.connect(func() -> void: _event("level_complete"))
	_show_step()


func _process(delta: float) -> void:
	visible = _index < _steps.size() and not level_scene.closeup.is_open() and not level_scene.session.finished
	# Re-sparkle the current target now and then, so it's easy to spot.
	_sparkle_timer -= delta
	if _sparkle_timer <= 0.0 and visible and _index < _steps.size():
		_sparkle_timer = 4.0
		var target := str((_steps[_index] as Dictionary).get("target", ""))
		if target != "" and level_scene.hotspots.has(target):
			level_scene.call("_sparkle_at", level_scene.call("_hotspot_center", target), 2)


func current_step() -> int:
	return _index


func _event(event: String) -> void:
	# Steps can be completed out of order (e.g. the flashlight picked up early): skip everything already done.
	var advanced := false
	while _index < _steps.size() and (str((_steps[_index] as Dictionary).get("done", "")) == event or _already_done(_index)):
		_index += 1
		advanced = true
	if advanced:
		AudioManager.play_sfx("hint", 0.0, -6.0)
		_show_step()


func _already_done(i: int) -> bool:
	var done := str((_steps[i] as Dictionary).get("done", ""))
	var s := level_scene.session
	var parts := done.split(":")
	match parts[0]:
		"clue_seen":
			return s.seen.has(parts[1])
		"lock_opened":
			return s.is_open(parts[1])
		"item_picked":
			return s.picked.has(parts[1])
		"combined":
			return not s.combined_recipes.is_empty()
	return false


func _show_step() -> void:
	if _index >= _steps.size():
		visible = false
		SaveManager.data["tutorial_done"] = true
		return
	_label.text = level_scene.text.rich(str((_steps[_index] as Dictionary).get("text", "")), 38)
	_sparkle_timer = 0.3
	UIKit.pop_in(self)
