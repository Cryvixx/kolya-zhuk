extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#2b3a2b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var title := Label.new()
	title.text = "Порно жуки"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	box.add_child(_make_button("Играть", func(): get_tree().change_scene_to_file("res://scenes/level_select.tscn")))
	box.add_child(_make_button("Выход", func(): get_tree().quit()))


func _make_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 56)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(on_press)
	return b
