extends Node2D

signal wave_finished

class Bug:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var speed := 60.0
	var scale := 1.0
	var separation_radius := 8.0
	var anim := 0.0
	var heading := 0.0
	var tint := Color.WHITE

const TILE := 16.0
const SPAWN_RATE := 40.0    # жуков в секунду
const SEP_FORCE := 220.0    # расталкивание друг с другом
const WALL_FORCE := 160.0   # отталкивание от стен
const DIRS8 := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var bug_type: BugType
var road: Dictionary = {}          # Vector2i -> true, проходимые клетки
var spawns: Array[Vector2i] = []
var bases: Array[Vector2i] = []
var bugs: Array[Bug] = []
var leaked := 0
var running := false

var _base_set: Dictionary = {}
var _dist: Dictionary = {}         # Vector2i -> float
var _flow: Dictionary = {}         # Vector2i -> Vector2
var _sep_r := 10.0
var _to_spawn := 0
var _spawn_acc := 0.0
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func setup(road_cells: Dictionary, spawn_cells: Array[Vector2i], base_cells: Array[Vector2i], type: BugType) -> String:
	road = road_cells
	spawns = spawn_cells
	bases = base_cells
	bug_type = type if type != null else BugType.new()
	_sep_r = maxf(maxf(bug_type.separation_radius_min, bug_type.separation_radius_max), 1.0)
	if spawns.is_empty():
		return "На карте нет тайла Spawn"
	if bases.is_empty():
		return "На карте нет тайла Base"
	_base_set.clear()
	for c in bases:
		_base_set[c] = true
	rebuild_flow()
	for c in spawns:
		if not _dist.has(c):
			return "Дорога не соединяет Spawn с Base"
	return ""


## Вызывать, если дорога изменилась (например, башня перекрыла клетку:
## road.erase(клетка) и rebuild_flow()).
func rebuild_flow() -> void:
	_dist.clear()
	_flow.clear()
	var queue: Array[Vector2i] = []
	for c in bases:
		_dist[c] = 0.0
		queue.append(c)
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		var dc: float = _dist[c]
		for o in DIRS8:
			var off: Vector2i = o
			if not _can_step(c, off):
				continue
			var n := c + off
			var nd := dc + off.length()
			var old: float = _dist.get(n, INF)
			if nd < old:
				_dist[n] = nd
				queue.append(n)
	for c in _dist:
		var dc: float = _dist[c]
		var v := Vector2.ZERO
		for o in DIRS8:
			var off: Vector2i = o
			if not _can_step(c, off):
				continue
			var n: Vector2i = c + off
			if _dist.has(n):
				var gain: float = dc - _dist[n]
				if gain > 0.0:
					v += Vector2(off).normalized() * gain
		_flow[c] = v.normalized() if v != Vector2.ZERO else Vector2.ZERO


func _can_step(c: Vector2i, off: Vector2i) -> bool:
	if not road.has(c + off):
		return false
	if off.x != 0 and off.y != 0:  # по диагонали (только если углы свободны)
		if not road.has(c + Vector2i(off.x, 0)) or not road.has(c + Vector2i(0, off.y)):
			return false
	return true


func start(count: int) -> void:
	bugs.clear()
	leaked = 0
	_to_spawn = count
	_spawn_acc = 0.0
	running = true


func _physics_process(delta: float) -> void:
	if not running:
		return
	_time += delta
	_spawn(delta)
	_simulate(delta)
	queue_redraw()
	if _to_spawn == 0 and bugs.is_empty():
		running = false
		wave_finished.emit()


func _spawn(delta: float) -> void:
	_spawn_acc += SPAWN_RATE * delta
	while _spawn_acc >= 1.0 and _to_spawn > 0:
		_spawn_acc -= 1.0
		_to_spawn -= 1
		var cell: Vector2i = spawns[_rng.randi() % spawns.size()]
		var b := Bug.new()
		b.pos = (Vector2(cell) + Vector2(_rng.randf_range(0.15, 0.85), _rng.randf_range(0.15, 0.85))) * TILE
		b.speed = _rng.randf_range(bug_type.speed_min, bug_type.speed_max)
		b.scale = _rng.randf_range(bug_type.scale_min, bug_type.scale_max)
		var scale_span := bug_type.scale_max - bug_type.scale_min
		var scale_t := 0.0
		if absf(scale_span) > 0.0001:
			scale_t = clampf((b.scale - bug_type.scale_min) / scale_span, 0.0, 1.0)
		b.separation_radius = lerpf(
			bug_type.separation_radius_min,
			bug_type.separation_radius_max,
			scale_t
		)
		var k := 1.0 - _rng.randf() * bug_type.tint_variation
		b.tint = Color(k, k, k, 1.0)
		b.anim = _rng.randf() * maxf(bug_type.frame_count, 1)
		b.vel = _flow_at(b.pos) * b.speed
		b.heading = b.vel.angle()
		bugs.append(b)


func _cell(p: Vector2) -> Vector2i:
	return Vector2i((p / TILE).floor())


# Направление потока в точке
func _flow_at(p: Vector2) -> Vector2:
	var f := p / TILE - Vector2(0.5, 0.5)
	var c0 := Vector2i(f.floor())
	var t := f - Vector2(c0)
	var f00: Vector2 = _flow.get(c0, Vector2.ZERO)
	var f10: Vector2 = _flow.get(c0 + Vector2i(1, 0), Vector2.ZERO)
	var f01: Vector2 = _flow.get(c0 + Vector2i(0, 1), Vector2.ZERO)
	var f11: Vector2 = _flow.get(c0 + Vector2i(1, 1), Vector2.ZERO)
	var v := f00 * ((1.0 - t.x) * (1.0 - t.y)) + f10 * (t.x * (1.0 - t.y)) \
		+ f01 * ((1.0 - t.x) * t.y) + f11 * (t.x * t.y)
	if v.length_squared() < 0.0001:
		return Vector2.ZERO
	return v.normalized()


# Если рядом стена, то толкаем нахуй
func _wall_push(p: Vector2, c: Vector2i) -> Vector2:
	var r := bug_type.radius
	var l := p - Vector2(c) * TILE
	var push := Vector2.ZERO
	if l.x < r and not road.has(c + Vector2i(-1, 0)):
		push.x += (r - l.x) / r
	if TILE - l.x < r and not road.has(c + Vector2i(1, 0)):
		push.x -= (r - (TILE - l.x)) / r
	if l.y < r and not road.has(c + Vector2i(0, -1)):
		push.y += (r - l.y) / r
	if TILE - l.y < r and not road.has(c + Vector2i(0, 1)):
		push.y -= (r - (TILE - l.y)) / r
	return push


func _move(b: Bug, delta: float) -> void:
	var np := b.pos + b.vel * delta
	if road.has(_cell(np)):
		b.pos = np
		return
	var nx := Vector2(np.x, b.pos.y)
	var ny := Vector2(b.pos.x, np.y)
	if road.has(_cell(nx)):
		b.pos = nx
		b.vel.y = 0.0
	elif road.has(_cell(ny)):
		b.pos = ny
		b.vel.x = 0.0
	else:
		b.vel = Vector2.ZERO


func _simulate(delta: float) -> void:
	# сетка для быстрого поиска соседей
	var grid := {}
	for i in bugs.size():
		var gc := Vector2i((bugs[i].pos / _sep_r).floor())
		if not grid.has(gc):
			grid[gc] = []
		grid[gc].append(i)

	var alive: Array[Bug] = []
	for b in bugs:
		var cell := _cell(b.pos)
		if _base_set.has(cell):
			leaked += 1
			continue

		var desired := _flow_at(b.pos) * b.speed
		desired += _wall_push(b.pos, cell) * WALL_FORCE

		var sep := Vector2.ZERO
		var gb := Vector2i((b.pos / _sep_r).floor())
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var k := gb + Vector2i(dx, dy)
				if not grid.has(k):
					continue
				for j in grid[k]:
					var o: Bug = bugs[j]
					if o == b:
						continue
					var diff := b.pos - o.pos
					var dist_sq := diff.length_squared()
					var pair_radius := (b.separation_radius + o.separation_radius) * 0.5
					if dist_sq < 0.000001:
						sep += Vector2.from_angle(_rng.randf() * TAU)
					elif dist_sq < pair_radius * pair_radius:
						var dist := sqrt(dist_sq)
						sep += diff / dist * (1.0 - dist / pair_radius)
		desired += sep * SEP_FORCE

		b.vel = b.vel.lerp(desired, 1.0 - exp(-5.0 * delta))
		_move(b, delta)

		var sp := b.vel.length()
		# в пробке лапки (или чё там у них) перебирают медленнее
		b.anim += delta * bug_type.fps * clampf(sp / b.speed, 0.25, 1.5)
		if sp > 5.0:
			b.heading = lerp_angle(b.heading, b.vel.angle(), 1.0 - exp(-10.0 * delta))
		alive.append(b)
	bugs = alive


func _draw() -> void:
	var tex := bug_type.texture if bug_type != null else null
	if tex == null:
		for b in bugs:
			draw_circle(b.pos.round(), 4.0 * b.scale, Color(0.5, 0.2, 0.1) * b.tint)
		return
	var fs := Vector2(bug_type.frame_size)
	var frames := maxi(bug_type.frame_count, 1)
	for b in bugs:
		var frame := int(b.anim) % frames
		var src := Rect2(Vector2(frame * fs.x, 0.0), fs)
		var ang := 0.0
		var flip := 1.0
		if bug_type.rotate_to_heading:
			ang = b.heading
			if bug_type.rotation_steps > 0:
				ang = snappedf(ang, TAU / float(bug_type.rotation_steps))
		elif b.vel.x < -1.0:
			flip = -1.0
		draw_set_transform(b.pos.round(), ang, Vector2(b.scale * flip, b.scale))
		draw_texture_rect_region(tex, Rect2(-fs * 0.5, fs), src, b.tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
