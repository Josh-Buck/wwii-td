extends Node2D

@export var lifetime: float = 0.35
@export var max_radius: float = 28.0

var _t: float = 0.0
var _color: Color = Color(1, 0.85, 0.3)

func setup(color: Color = Color(1, 0.85, 0.3)) -> void:
	_color = color

func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var f: float = _t / lifetime  ## 0..1
	var r: float = max_radius * f
	var alpha: float = 1.0 - f
	var fill: Color = _color
	fill.a = alpha * 0.4
	var rim: Color = _color
	rim.a = alpha
	draw_circle(Vector2.ZERO, r, fill)
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, rim, 2.0)
