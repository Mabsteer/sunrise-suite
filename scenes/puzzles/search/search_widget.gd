extends LockWidget
## A hidden spot that just needs a good look: press "Search".


func _build() -> void:
	var host: Dictionary = lock.get("host", {})
	var tex: Texture2D = null
	if str(host.get("kind", "")) == "prop":
		tex = UIKit.texture(str((Data.get_dict("props").get(str(host.get("prop", "")), {}) as Dictionary).get("sprite", "")))
	elif text:
		tex = UIKit.texture(str(text.furniture(str(host.get("furniture", ""))).get("sprite", "")))
	if tex:
		var art := TextureRect.new()
		art.texture = tex
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(420, 280)
		add_child(art)
	var l := UIKit.label(tr("SEARCH_TEXT"), 34, Palette.color("ink"))
	l.custom_minimum_size.x = 700
	add_child(l)
	var b := make_button(tr("SEARCH"))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void: submitted.emit("search"))
	add_child(b)
