extends Control
## все .tscn из папки res://levels/
## кнопка появляется при добавлении файла в папку

const LEVEL_DIR := "res://levels/"


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#2b3a2b")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	var title := Label.new()
	title.text = "Выбор уровня"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	box.add_child(grid)

	for fname in _list_levels():
		var path := LEVEL_DIR + fname
		var b := Button.new()
		b.custom_minimum_size = Vector2(180, 100)
		b.add_theme_font_size_override("font_size", 22)
		b.text = fname.get_basename().replace("_", " ").capitalize()
		b.pressed.connect(func(): get_tree().change_scene_to_file(path))
		grid.add_child(b)

	var back := Button.new()
	back.text = "← Назад"
	back.custom_minimum_size = Vector2(200, 48)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	box.add_child(back)


func _list_levels() -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(LEVEL_DIR):
		var fname := f.trim_suffix(".remap")  # в экспортированной игре файлы с .remap
		if fname.ends_with(".tscn"):
			out.append(fname)
	out.sort()
	return out
