class_name LockWidget
extends VBoxContainer
## Base for the interactive part of a lock's close-up. Widgets emit `submitted(answer)`; the level decides.
## Key/tool widgets emit `use_requested()` instead (the level uses the selected inventory item).

signal submitted(answer: String)
signal use_requested()

var lock: Dictionary
var text: LevelText
var rng_seed: int = 0


func _init() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 22)


## Called once before the widget is shown.
func setup(lock_data: Dictionary, level_text: LevelText, seed_value: int = 0) -> void:
	lock = lock_data
	text = level_text
	rng_seed = seed_value
	_build()


## Override: build the controls.
func _build() -> void:
	pass


## Called by the level after a wrong answer.
func show_wrong() -> void:
	AudioManager.play_sfx("lock_wrong")
	UIKit.wiggle(self)


func config() -> Dictionary:
	return lock.get("config", {})


static func make_button(caption: String, min_width: float = 260.0) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(min_width, 96)
	b.focus_mode = Control.FOCUS_NONE
	return b


static func brass_plate(margin: float = 26.0) -> StyleBoxFlat:
	var sb := UIKit.box(Palette.color("brass"), 34, Palette.color("brass_dark"), 5, margin)
	sb.shadow_color = Color(0.231, 0.18, 0.227, 0.25)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 6)
	return sb
