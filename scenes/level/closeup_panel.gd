class_name CloseupPanel
extends Control
## The card that opens when you tap something: a lock's widget, what's inside it, a clue, an item or flavour text.

signal closed()
signal answer_submitted(lock_id: String, answer: String)
signal use_requested(lock_id: String)
signal take_requested(kind: String, id: String, from_global: Vector2)
signal lock_requested(lock_id: String)

const WIDGETS := {
	"combo": "res://scenes/puzzles/combo/combo_widget.gd",
	"sequence": "res://scenes/puzzles/sequence/sequence_widget.gd",
	"clock": "res://scenes/puzzles/clock/clock_widget.gd",
	"switches": "res://scenes/puzzles/switches/switches_widget.gd",
	"slider": "res://scenes/puzzles/slider/slider_widget.gd",
	"key": "res://scenes/puzzles/keyhole/keyhole_widget.gd",
	"tool": "res://scenes/puzzles/keyhole/keyhole_widget.gd",
	"hidden_tool": "res://scenes/puzzles/keyhole/keyhole_widget.gd",
	"hidden": "res://scenes/puzzles/search/search_widget.gd",
	"order": "res://scenes/puzzles/order/order_widget.gd",
	"sudoku": "res://scenes/puzzles/sudoku/sudoku_widget.gd",
	"pattern": "res://scenes/puzzles/pattern/pattern_widget.gd",
	"rotate": "res://scenes/puzzles/rotate/rotate_widget.gd",
	"dog": "res://scenes/puzzles/dog/dog_widget.gd",
	"care": "res://scenes/puzzles/dog/dog_widget.gd",
	"sniff": "res://scenes/puzzles/dog/dog_widget.gd",
}

var session: LevelSession
var text: LevelText
## What is shown: { "kind": "lock"|"clue"|"decoy"|"item"|"flavor"|"postcard", "id": ... }
var showing: Dictionary = {}
var widget: LockWidget

var _card: PanelContainer
var _title: Label
var _icon: TextureRect
var _body: VBoxContainer


func setup(level_session: LevelSession, level_text: LevelText) -> void:
	session = level_session
	text = level_text
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.169, 0.137, 0.314, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			close())
	add_child(dim)
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", UIKit.card(30))
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_card.custom_minimum_size = Vector2(1240, 0)
	_card.offset_left = -620
	_card.offset_right = 620
	_card.offset_top = 36
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	_card.add_child(v)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	v.add_child(header)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(76, 76)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(_icon)
	_title = UIKit.label("", 44, Palette.color("ink"), HORIZONTAL_ALIGNMENT_LEFT)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(_title)
	var close_button := UIKit.icon_button("ui/close.svg", 88, tr("CLOSE"))
	close_button.pressed.connect(close)
	header.add_child(close_button)
	_body = VBoxContainer.new()
	_body.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_theme_constant_override("separation", 20)
	_body.custom_minimum_size = Vector2(0, 560)
	v.add_child(_body)


func is_open() -> bool:
	return visible


func show_lock(lock_id: String) -> void:
	_show({"kind": "lock", "id": lock_id})


func show_thing(kind: String, id: String) -> void:
	_show({"kind": kind, "id": id})


func show_flavor(title: String, body_text: String, sprite_path: String) -> void:
	_show({"kind": "flavor", "id": title, "title": title, "text": body_text, "sprite": sprite_path})


## Rebuilds the current view (e.g. after a lock opened or an item was taken).
func refresh() -> void:
	if visible and not showing.is_empty():
		_show(showing, false)


## Adds an extra line of text under the current view (e.g. "You found every postcard!").
func add_line(message: String) -> void:
	var l := UIKit.label(message, 32, Palette.color("coral_dark"))
	l.custom_minimum_size.x = 900
	_body.add_child(l)


func close() -> void:
	if not visible:
		return
	visible = false
	showing = {}
	widget = null
	AudioManager.play_sfx("ui_back")
	closed.emit()


func _show(what: Dictionary, animate: bool = true) -> void:
	showing = what
	widget = null
	for c in _body.get_children():
		c.queue_free()
	var kind := str(what["kind"])
	var id := str(what["id"])
	match kind:
		"lock":
			_build_lock(id)
		"clue":
			var c: Dictionary = session.clues[id]
			var host: Dictionary = c.get("host", {})
			_header(_host_sprite(host), _cap(text.host_name(host)))
			if host.has("count"):
				# Something to count: show it big.
				var art := TextureRect.new()
				art.texture = _host_sprite(host)
				art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				art.custom_minimum_size = Vector2(560, 400)
				_body.add_child(art)
				var l := UIKit.label(str(c.get("text", "")), 36, Palette.color("ink"))
				l.custom_minimum_size.x = 900
				_body.add_child(l)
			else:
				_note(str(c.get("text", "")))
		"decoy":
			var d: Dictionary = session.decoys[id]
			_header(_host_sprite(d.get("host", {})), _cap(text.host_name(d.get("host", {}))))
			_note(str(d.get("text", "")))
		"item":
			_build_item(id)
		"flavor":
			_header(UIKit.texture(str(what.get("sprite", ""))), _cap(str(what.get("title", ""))))
			var l := UIKit.label(str(what.get("text", "")), 38, Palette.color("ink"))
			l.custom_minimum_size.x = 900
			_body.add_child(l)
		"postcard":
			_header(UIKit.texture("props/common/postcard_small.svg"), tr("POSTCARD_FOUND_TITLE"))
			var pc := GameState.postcard(id)
			var front := TextureRect.new()
			front.texture = UIKit.texture(str(pc.get("front", "props/common/postcard_small.svg")))
			front.custom_minimum_size = Vector2(560, 368)
			front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			front.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			front.rotation_degrees = -1.5
			_body.add_child(front)
			var l := UIKit.label(tr("POSTCARD_FOUND_TEXT") % str(pc.get("place", "")), 34, Palette.color("ink"))
			l.custom_minimum_size.x = 900
			_body.add_child(l)
	if not visible:
		visible = true
		if animate:
			UIKit.pop_in(_card)


func _build_lock(lock_id: String) -> void:
	var lock: Dictionary = session.locks[lock_id]
	var host: Dictionary = lock.get("host", {})
	var is_open := session.is_open(lock_id)
	var sprite := _host_sprite(host, is_open)
	_header(sprite, _cap(text.lock_name(lock_id)))
	if not is_open:
		var t := str(lock.get("type", ""))
		var key := t
		if t == "hidden" and session.lock_item(lock_id) != "":
			key = "hidden_tool"
		var script_path: String = WIDGETS.get(key, "")
		if script_path == "":
			return
		widget = (load(script_path) as GDScript).new() as LockWidget
		_body.add_child(widget)
		widget.setup(lock, text, hash(str(session.level.get("id", "")) + lock_id) + int(session.level.get("seed", 0)))
		widget.submitted.connect(func(answer: String) -> void: answer_submitted.emit(lock_id, answer))
		widget.use_requested.connect(func() -> void: use_requested.emit(lock_id))
		return
	# Opened: a solved number square stays visible, so its shaded squares can be read.
	if str(lock.get("type", "")) == "sudoku":
		var view := (load(WIDGETS["sudoku"]) as GDScript).new() as LockWidget
		view.call("setup_solved", lock)
		_body.add_child(view)
	# Show what's inside.
	var things := session.things_at(lock_id)
	var available: Array[Dictionary] = []
	for th in things:
		match str(th["kind"]):
			"item":
				if session.item_available(str(th["id"])):
					available.append(th)
			"postcard":
				if not session.postcard_taken:
					available.append(th)
			_:
				available.append(th)
	var reveal := str(_spot_or_prop(host).get("reveal", ""))
	var intro := tr("INSIDE_REVEAL") % reveal if reveal != "" else tr("INSIDE")
	if available.is_empty():
		intro = tr("INSIDE_EMPTY")
	_body.add_child(UIKit.label(intro, 36, Palette.color("ink_soft")))
	var row := HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 22)
	row.add_theme_constant_override("v_separation", 22)
	_body.add_child(row)
	for th in available:
		row.add_child(_thing_card(str(th["kind"]), str(th["id"])))


func _build_item(item_id: String) -> void:
	var data := text.item_type_data(item_id)
	_header(UIKit.texture(str(data.get("sprite", ""))), _cap(text.item_name(item_id)))
	var art := TextureRect.new()
	art.texture = UIKit.texture(str(data.get("sprite", "")))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(320, 320)
	_body.add_child(art)
	var l := UIKit.label(str(data.get("text", "")), 38, Palette.color("ink"))
	l.custom_minimum_size.x = 900
	_body.add_child(l)
	for c: String in session.clues.keys():
		if str(session.clues[c].get("item", "")) == item_id:
			_note(str(session.clues[c].get("text", "")))


func _thing_card(kind: String, id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 210)
	b.focus_mode = Control.FOCUS_NONE
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_font_size_override("font_size", 26)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match kind:
		"item":
			b.icon = UIKit.texture(str(text.item_type_data(id).get("sprite", "")))
			b.text = _cap(text.item_name(id))
			b.pressed.connect(func() -> void: take_requested.emit("item", id, b.global_position + b.size / 2.0))
		"clue", "decoy":
			var thing: Dictionary = session.clues[id] if kind == "clue" else session.decoys[id]
			b.icon = _host_sprite(thing.get("host", {}))
			b.text = _cap(text.host_name(thing.get("host", {})))
			b.pressed.connect(func() -> void: take_requested.emit(kind, id, b.global_position + b.size / 2.0))
		"lock":
			var lock: Dictionary = session.locks[id]
			b.icon = _host_sprite(lock.get("host", {}), session.is_open(id))
			b.text = _cap(text.lock_name(id))
			b.pressed.connect(func() -> void: lock_requested.emit(id))
		"postcard":
			b.icon = UIKit.texture("props/common/postcard_small.svg")
			b.text = tr("POSTCARD")
			b.pressed.connect(func() -> void: take_requested.emit("postcard", id, b.global_position + b.size / 2.0))
	return b


func _note(raw: String) -> void:
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", UIKit.paper(34))
	paper.custom_minimum_size = Vector2(880, 0)
	paper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	paper.rotation_degrees = -1.2
	_body.add_child(paper)
	var r := UIKit.handwriting(text.rich(raw, 52), 52)
	r.custom_minimum_size.x = 800
	paper.add_child(r)


func _header(icon: Texture2D, title: String) -> void:
	_icon.texture = icon
	_title.text = title


func _host_sprite(host: Dictionary, open: bool = false) -> Texture2D:
	match str(host.get("kind", "")):
		"prop":
			return UIKit.texture(LevelText.prop_sprite(host, open))
		"furniture":
			return UIKit.texture(str(text.furniture(str(host.get("furniture", ""))).get("sprite", "")))
		"door":
			return UIKit.texture("ui/home.svg")
		"dog":
			return UIKit.texture("props/chloe/chloe_portrait.svg")
	return null


func _spot_or_prop(host: Dictionary) -> Dictionary:
	if str(host.get("kind", "")) == "furniture":
		return text.furniture_spot(str(host.get("furniture", "")), str(host.get("spot", "")))
	if str(host.get("kind", "")) == "prop":
		return Data.get_dict("props").get(str(host.get("prop", "")), {})
	return {}


static func _cap(s: String) -> String:
	return s if s.is_empty() else s[0].to_upper() + s.substr(1)
