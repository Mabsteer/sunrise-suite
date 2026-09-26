extends Control
## Developer screen: shows every sprite in a folder as a labelled grid (used by the screenshot tour).
## Router params: { "dirs": ["props/common", "items"], "scale": 1.0 }

const SPRITES := "res://assets/sprites/"


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.color("sand")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var grid := HFlowContainer.new()
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.offset_left = 20
	grid.offset_top = 20
	grid.offset_right = -20
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	var scale_factor := float(Router.params.get("scale", 1.0))
	var dirs: Array = Router.params.get("dirs", ["props/common"])
	for dir: String in dirs:
		var files := DirAccess.get_files_at(SPRITES + dir)
		for f in files:
			if not f.ends_with(".svg"):
				continue
			var tex := load(SPRITES + dir + "/" + f) as Texture2D
			if tex == null:
				continue
			var box := VBoxContainer.new()
			var rect := TextureRect.new()
			rect.texture = tex
			rect.custom_minimum_size = tex.get_size() * scale_factor
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			box.add_child(rect)
			var label := Label.new()
			label.text = f.get_basename()
			label.add_theme_font_size_override("font_size", 16)
			box.add_child(label)
			grid.add_child(box)
