extends Node2D

@export var lifetime: float = 0.22
@export var max_radius: float = 14.0

var _t: float = 0.0
var _color: Color = Color(1, 0.9, 0.4)
var _spikes: Array = []  ## [Vector2 directions]

func setup(color: Color = Color(1, 0.9, 0.4)) -> void:
	_color = color
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_spikes.clear()
	for i in 5:
		var a: float = rng.randf_range(0, TAU)
		var len: float = rng.randf_range(8.0, 16.0)
		_spikes.append(Vector2(cos(a), sin(a)) * len)

func _ready() -> void:
	z_index = 25

func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var f: float = _t / lifetime
	var alpha: float = 1.0 - f
	# Flash circle
	var flash: Color = Color(1.0, 1.0, 0.85, alpha * 0.6)
	draw_circle(Vector2.ZERO, max_radius * (1.0 - f * 0.5), flash)
	# Star spikes
	var col := _color
	col.a = alpha
	for v in _spikes:
		draw_line(Vector2.ZERO, v * (1.0 - f * 0.3), col, 2.0)
