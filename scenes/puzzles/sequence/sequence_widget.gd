extends LockWidget
## Symbol sequence lock: tap symbols in the right order. Every symbol has its own shape and colour.

const SYMBOL_ORDER: PackedStringArray = ["sun", "shell", "wave", "star", "leaf", "heart"]

var _length := 3
var _chosen: PackedStringArray = []
var _sockets: Array[TextureRect] = []


func _build() -> void:
	_length = int(config().get("length", str(lock.get("answer", "")).split(",").size()))
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", brass_plate(22))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(plate)
	var sockets := HBoxContainer.new()
	sockets.alignment = BoxContainer.ALIGNMENT_CENTER
	sockets.add_theme_constant_override("separation", 16)
	plate.add_child(sockets)
	for i in _length:
		var socket := PanelContainer.new()
		socket.add_theme_stylebox_override("panel", UIKit.box(Palette.color("wood_dark"), 50, Palette.color("brass_dark"), 4, 10))
		socket.custom_minimum_size = Vector2(104, 104)
		sockets.add_child(socket)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		socket.add_child(icon)
		_sockets.append(icon)
	var buttons := GridContainer.new()
	buttons.columns = 6
	buttons.add_theme_constant_override("h_separation", 12)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(buttons)
	var symbols := Data.get_dict("symbols")
	for key in SYMBOL_ORDER:
		var b := UIKit.icon_button(str((symbols.get(key, {}) as Dictionary).get("sprite", "")), 104, text.symbol_name(key) if text else key)
		b.pressed.connect(_add.bind(key))
		buttons.add_child(b)
	var clear := make_button(tr("LOCK_CLEAR"), 220)
	clear.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	clear.pressed.connect(_clear)
	add_child(clear)


func _add(symbol: String) -> void:
	if _chosen.size() >= _length:
		return
	_chosen.append(symbol)
	_sockets[_chosen.size() - 1].texture = UIKit.texture(str((Data.get_dict("symbols").get(symbol, {}) as Dictionary).get("sprite", "")))
	AudioManager.play_sfx("lock_digit", 0.1)
	if _chosen.size() == _length:
		submitted.emit(",".join(_chosen))


func show_wrong() -> void:
	super.show_wrong()
	_clear()


func _clear() -> void:
	_chosen.clear()
	for s in _sockets:
		s.texture = null
