class_name MapDecor extends Node2D

# Draws procedural decorations on the map — trees, hedgerows, sandbags,
# craters — using a seeded RNG so the layout is stable across reloads.
# Decor is drawn under towers/enemies (lower z_index) and avoids the
# path corridor.

@export var style: StringName = &"normandy"  ## normandy | ardennes
@export var seed: int = 1942
@export var decor_count: int = 64
@export var path_points: PackedVector2Array  ## set from the parent map scene

const _MIN_PATH_DIST: float = 60.0
const _MAP_LEFT: float = 32.0
const _MAP_TOP: float = 56.0
const _MAP_RIGHT: float = 1052.0
const _MAP_BOTTOM: float = 680.0

var _items: Array = []  ## [{pos: Vector2, kind: StringName, rot: float, scale: float}]

const _TEX: Dictionary = {
	&"pine":     preload("res://art/decor/tree_pine.png"),
	&"rock":     preload("res://art/decor/rock.png"),
	&"hedge":    preload("res://art/decor/hedgerow.png"),
	&"bush":     preload("res://art/decor/bush.png"),
	&"sandbag":  preload("res://art/decor/sandbags.png"),
	&"crater":   preload("res://art/decor/crater.png"),
	&"barrel":   preload("res://art/decor/oil_barrel.png"),
	&"treads":   preload("res://art/decor/tank_treads.png"),
}

func _ready() -> void:
	z_index = -10
	z_as_relative = false
	_generate()

func _generate() -> void:
	_items.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var kinds: Array
	if style == &"ardennes":
		kinds = [&"pine", &"pine", &"pine", &"rock", &"rock", &"bush"]
	else:
		kinds = [&"hedge", &"bush", &"sandbag", &"crater", &"barrel", &"treads"]
	var attempts: int = 0
	while _items.size() < decor_count and attempts < decor_count * 20:
		attempts += 1
		var p := Vector2(
			rng.randf_range(_MAP_LEFT + 12, _MAP_RIGHT - 12),
			rng.randf_range(_MAP_TOP + 12, _MAP_BOTTOM - 12),
		)
		if _min_dist_to_path(p) < _MIN_PATH_DIST:
			continue
		_items.append({
			"pos": p,
			"kind": kinds[rng.randi() % kinds.size()],
			"rot": rng.randf_range(0, TAU),
			"scale": rng.randf_range(0.85, 1.25),
		})
	queue_redraw()

func _min_dist_to_path(p: Vector2) -> float:
	if path_points.size() < 2:
		return 9999.0
	var m: float = 9999.0
	for i in path_points.size() - 1:
		var d: float = _point_to_segment(p, path_points[i], path_points[i + 1])
		if d < m:
			m = d
	return m

func _point_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq <= 0.0001:
		return p.distance_to(a)
	var t: float = clamp((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _draw() -> void:
	for it in _items:
		var pos: Vector2 = it.pos
		var rot: float = it.rot
		var s: float = it.scale
		var tex: Texture2D = _TEX.get(it.kind)
		if tex != null:
			_draw_sprite(tex, pos, rot, s)
			continue
		# Fallback procedural shapes for kinds without a sprite.
		match it.kind:
			&"snow_tuft":      _draw_snow_tuft(pos, s)
			&"grass":          _draw_grass(pos, s)

func _draw_sprite(tex: Texture2D, pos: Vector2, rot: float, s: float) -> void:
	var size: Vector2 = tex.get_size() * s
	# Rotate around the sprite's centre.
	draw_set_transform(pos, rot, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-size / 2.0, size), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_pine(pos: Vector2, s: float) -> void:
	# Snow-capped pine: dark green triangle with white tip
	var w: float = 10.0 * s
	var h: float = 18.0 * s
	var pts := PackedVector2Array([
		pos + Vector2(-w, h * 0.4),
		pos + Vector2(w, h * 0.4),
		pos + Vector2(0, -h * 0.8),
	])
	draw_colored_polygon(pts, Color(0.08, 0.20, 0.14, 1))
	draw_circle(pos + Vector2(0, -h * 0.6), 3.0 * s, Color(0.96, 0.98, 1.0, 0.9))
	draw_rect(Rect2(pos + Vector2(-1.5 * s, h * 0.35), Vector2(3 * s, 4 * s)), Color(0.18, 0.10, 0.05))

func _draw_snow_tuft(pos: Vector2, s: float) -> void:
	draw_circle(pos, 6.0 * s, Color(0.95, 0.97, 1.0, 0.85))
	draw_circle(pos + Vector2(4 * s, 1), 4.0 * s, Color(0.92, 0.95, 0.99, 0.7))

func _draw_rock(pos: Vector2, s: float) -> void:
	draw_circle(pos, 5.0 * s, Color(0.40, 0.42, 0.45))
	draw_arc(pos, 5.0 * s, 0, TAU, 12, Color(0.25, 0.27, 0.30), 1.0)

func _draw_hedge(pos: Vector2, rot: float, s: float) -> void:
	# Normandy bocage — long dark-green rectangles
	var w: float = 28.0 * s
	var h: float = 8.0 * s
	var c := cos(rot)
	var sn := sin(rot)
	var corners := PackedVector2Array([
		pos + Vector2(-w, -h).rotated(rot),
		pos + Vector2(w, -h).rotated(rot),
		pos + Vector2(w, h).rotated(rot),
		pos + Vector2(-w, h).rotated(rot),
	])
	draw_colored_polygon(corners, Color(0.13, 0.22, 0.12, 1))
	draw_polyline(corners + PackedVector2Array([corners[0]]), Color(0.08, 0.14, 0.07, 0.8), 1.0)

func _draw_grass(pos: Vector2, s: float) -> void:
	var col := Color(0.30, 0.42, 0.22, 0.9)
	for i in 3:
		var off := Vector2(i * 2.0 - 2.0, 0) * s
		draw_line(pos + off + Vector2(0, 2 * s), pos + off + Vector2(0, -4 * s), col, 1.5)

func _draw_sandbag(pos: Vector2, rot: float, s: float) -> void:
	var w: float = 16.0 * s
	var h: float = 5.0 * s
	var pts := PackedVector2Array([
		pos + Vector2(-w, -h).rotated(rot),
		pos + Vector2(w, -h).rotated(rot),
		pos + Vector2(w, h).rotated(rot),
		pos + Vector2(-w, h).rotated(rot),
	])
	draw_colored_polygon(pts, Color(0.60, 0.52, 0.34, 1))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.32, 0.26, 0.16, 0.9), 1.0)

func _draw_crater(pos: Vector2, s: float) -> void:
	draw_circle(pos, 10.0 * s, Color(0.16, 0.18, 0.13, 1))
	draw_arc(pos, 10.0 * s, 0, TAU, 24, Color(0.08, 0.08, 0.06, 0.9), 1.2)
	draw_circle(pos, 5.0 * s, Color(0.10, 0.10, 0.08, 0.9))
