extends Node2D

@export var lifetime: float = 0.16
@export var max_radius: float = 14.0

var _t: float = 0.0
var _color: Color = Color(1, 0.95, 0.4)
var _angle: float = 0.0  ## direction toward target so flash flares outward

func setup(color: Color = Color(1, 0.95, 0.4), angle: float = 0.0) -> void:
	_color = color
	_angle = angle

func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var f: float = _t / lifetime
	var alpha: float = 1.0 - f
	var r: float = max_radius * (1.0 - f * 0.3)
	# Bright core
	var core: Color = Color(1.0, 1.0, 0.85, alpha)
	draw_circle(Vector2.ZERO, r * 0.5, core)
	# Mid glow
	var mid: Color = _color
	mid.a = alpha * 0.85
	draw_circle(Vector2.ZERO, r, mid)
	# Wide soft halo
	var halo: Color = _color
	halo.a = alpha * 0.35
	draw_circle(Vector2.ZERO, r * 2.0, halo)
	# Directional flare cone toward target
	var dir := Vector2(cos(_angle), sin(_angle))
	var perp := Vector2(-dir.y, dir.x)
	var tip: Vector2 = dir * r * 2.2
	var base_l: Vector2 = perp * r * 0.4
	var base_r: Vector2 = -perp * r * 0.4
	var pts := PackedVector2Array([tip, base_l, base_r])
	draw_colored_polygon(pts, mid)
