extends Node2D

@export var lifetime: float = 0.55
@export var max_radius: float = 32.0

var _t: float = 0.0
var _color: Color = Color(1, 0.85, 0.3)
var _debris: Array = []  ## [{pos: Vector2, vel: Vector2, size: float}]

func setup(color: Color = Color(1, 0.85, 0.3)) -> void:
	_color = color
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_debris.clear()
	for i in 7:
		var ang: float = rng.randf_range(0.0, TAU)
		var spd: float = rng.randf_range(60.0, 140.0)
		_debris.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"size": rng.randf_range(1.5, 3.5),
		})

func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	for d in _debris:
		d.pos += d.vel * delta
		d.vel *= 0.92  ## drag
	queue_redraw()

func _draw() -> void:
	var f: float = _t / lifetime  ## 0..1
	var r: float = max_radius * sqrt(f)
	var alpha: float = 1.0 - f
	var fill: Color = _color
	fill.a = alpha * 0.35
	var rim: Color = _color
	rim.a = alpha * 0.9
	draw_circle(Vector2.ZERO, r, fill)
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, rim, 2.5)
	# Inner smoke puff
	var smoke: Color = Color(0.20, 0.18, 0.16, alpha * 0.5)
	draw_circle(Vector2.ZERO, r * 0.55, smoke)
	# Debris specks flying outward
	for d in _debris:
		var col := _color
		col.a = alpha
		draw_circle(d.pos, d.size, col)
