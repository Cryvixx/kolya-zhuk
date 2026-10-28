class_name BugType
extends Resource
## Описание "вида" жука: спрайт, анимация, скорость, размер.
## Создать новый: ПКМ в файловой панели -> Create New -> Resource -> BugType.
## Потом перетащить его в поле Bug Type у корня уровня.

@export_group("Спрайт")
## Горизонтальная полоса кадров (все кадры в одну строку, жук смотрит ВПРАВО).
@export var texture: Texture2D
## Размер одного кадра в пикселях.
@export var frame_size := Vector2i(64, 64)
@export var frame_count := 4
@export var fps := 10.0
## true: спрайт поворачивается по ходу движения (вид сверху).
## false: только зеркалится влево/вправо (вид сбоку).
@export var rotate_to_heading := true
## 0 = плавный поворот, 8 = по 45° (выглядит "пиксельнее"), 4 = по 90°.
@export var rotation_steps := 8

@export_group("Поведение")
@export var radius := 5.0
@export_range(1.0, 64.0, 0.5) var separation_radius_min := 6.0
@export_range(1.0, 64.0, 0.5) var separation_radius_max := 10.0
@export var speed_min := 50.0
@export var speed_max := 80.0

@export_group("Разброс")
@export var scale_min := 0.3
@export var scale_max := 0.5
## 0 = все одинаковые, 0.2 = заметный разброс яркости.
@export_range(0.0, 0.5) var tint_variation := 0.12
