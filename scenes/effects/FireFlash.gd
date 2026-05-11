extends Node2D

@export var lifetime: float = 0.12
@export var max_radius: float = 10.0

var _t: float = 0.0
var _color: Color = Color(1, 0.95, 0.4)

func setup(color: Color = Color(1, 0.95, 0.4)) -> void:
	_color = color

func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var f: float = _t / lifetime
	var alpha: float = 1.0 - f
	var r: float = max_radius * (1.0 - f * 0.4)
	var col: Color = _color
	col.a = alpha
	draw_circle(Vector2.ZERO, r, col)
	col.a = alpha * 0.55
	draw_circle(Vector2.ZERO, r * 1.6, col)
