extends LockWidget
## Chloé's locks. "dog": ask her to fetch or dig (a button). "care": she wants something (or she's
## hiding and wants Gaston): tap here with the item selected. "sniff": a hidden smell; give her a
## scent in your bag and she finds it.

const CARE_TEXT := {
	"kibble": "DOG_NEEDS_FOOD",
	"water_jug": "DOG_NEEDS_WATER",
	"leash": "DOG_NEEDS_LEASH",
	"dog_brush": "DOG_NEEDS_BRUSH",
	"gaston": "DOG_NEEDS_TOY",
}


func _build() -> void:
	var t := str(lock.get("type", ""))
	var session: LevelSession = text.session if text else null
	var present := session != null and session.dog_present
	var hiding := bool(lock.get("finds_dog", false))
	var art := TextureRect.new()
	art.texture = UIKit.texture("props/chloe/chloe_peek.svg" if hiding or not present else "props/chloe/chloe_portrait.svg")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(300, 240)
	var message := ""
	match t:
		"dog":
			var action := str(lock.get("action", "fetch"))
			if not present:
				message = tr("DOG_NOT_HERE")
			else:
				message = tr("DOG_DIG_TEXT") if action == "dig" else tr("DOG_FETCH_TEXT")
			add_child(art)
			_add_text(message)
			if present:
				var b := UIKit.primary(make_button(tr("DOG_DIG") if action == "dig" else tr("DOG_FETCH"), 360))
				b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				b.pressed.connect(func() -> void: submitted.emit("dog"))
				add_child(b)
		"care":
			var wanted := ""
			if session:
				wanted = str(session.items.get(session.lock_item(str(lock["id"])), {}).get("type", ""))
			var target := Button.new()
			target.focus_mode = Control.FOCUS_NONE
			target.custom_minimum_size = Vector2(320, 260)
			target.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			target.icon = art.texture
			art.free()
			target.expand_icon = true
			target.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			target.pressed.connect(func() -> void: use_requested.emit())
			add_child(target)
			_add_text(tr("DOG_HIDING") if hiding else tr(CARE_TEXT.get(wanted, "DOG_NEEDS_TOY")))
			_add_text(tr("USE_ITEM_HELP") if hiding else tr("DOG_GIVE_HELP"), 28, Palette.color("ink_soft"))
		_:
			art.texture = UIKit.texture("props/chloe/chloe_sniff.svg")
			add_child(art)
			_add_text(tr("DOG_SNIFF_TEXT") if present else tr("DOG_NOT_HERE"))


func _add_text(message: String, size: int = 34, color: Color = Palette.color("ink")) -> void:
	var l := UIKit.label(message, size, color)
	l.custom_minimum_size.x = 780
	add_child(l)


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("item") and str(lock.get("type", "")) == "care"


func _drop_data(_at: Vector2, _data: Variant) -> void:
	use_requested.emit()
