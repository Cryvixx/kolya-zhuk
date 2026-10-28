extends Node2D
## Универсальный уровень
##   тайл 0 (коричневый)  - дорога
##   тайл 1 (с ямой)      - Spawn, откуда ползут
##   тайл 2 (красный)     - Base, куда ползут
##   остальные тайлы      - декор/препятствия, по ним не ползут

const HordeScript := preload("res://scripts/horde.gd")
const ROAD := Vector2i(0, 0)
const SPAWN := Vector2i(1, 0)
const BASE := Vector2i(2, 0)

@export var bug_type: BugType
@export var bug_count := 3000
## Во сколько раз увеличить пиксельарт на экране.
@export var zoom := 2.0

var horde: Node2D
var start_btn: Button
var info: Label
var error_text := ""


func _ready() -> void:
	scale = Vector2.ONE * zoom
	var map := $Map as TileMapLayer

	var road := {}
	var spawns: Array[Vector2i] = []
	var bases: Array[Vector2i] = []
	for c in map.get_used_cells():
		var a := map.get_cell_atlas_coords(c)
		if a == ROAD:
			road[c] = true
		elif a == SPAWN:
			road[c] = true
			spawns.append(c)
		elif a == BASE:
			road[c] = true
			bases.append(c)

	horde = HordeScript.new()
	add_child(horde)  #рисуется поверх
	horde.wave_finished.connect(_on_wave_finished)
	error_text = horde.setup(road, spawns, bases, bug_type)
	_build_ui()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var bar := HBoxContainer.new()
	bar.position = Vector2(16, 16)
	bar.add_theme_constant_override("separation", 12)
	layer.add_child(bar)

	var back := Button.new()
	back.text = "← Меню"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/level_select.tscn"))
	bar.add_child(back)

	start_btn = Button.new()
	start_btn.text = "Запустить орду"
	start_btn.pressed.connect(_on_start)
	start_btn.disabled = error_text != ""
	bar.add_child(start_btn)

	info = Label.new()
	info.add_theme_color_override("font_outline_color", Color.BLACK)
	info.add_theme_constant_override("outline_size", 6)
	bar.add_child(info)


func _on_start() -> void:
	start_btn.disabled = true
	horde.start(bug_count)


func _on_wave_finished() -> void:
	start_btn.disabled = false
	start_btn.text = "Ещё раз"


func _process(_delta: float) -> void:
	if error_text != "":
		info.text = "  ⚠ " + error_text
		return
	info.text = "  Жуков на карте: %d    Дошло до базы: %d" % [horde.bugs.size(), horde.leaked]
