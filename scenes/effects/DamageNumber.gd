extends Node2D

@export var lifetime: float = 0.6
@export var rise_distance: float = 30.0

var _t: float = 0.0
var _text: String = ""
var _color: Color = Color(1, 0.9, 0.4)
var _start_pos: Vector2

func setup(damage: int, color: Color = Color(1, 0.9, 0.4)) -> void:
	_text = str(damage)
	_color = color

func _ready() -> void:
	_start_pos = position
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	# Float upward.
	position.y = _start_pos.y - rise_distance * (_t / lifetime)
	queue_redraw()

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var alpha: float = 1.0 - (_t / lifetime)
	var col: Color = _color
	col.a = alpha
	# Drop shadow + main text.
	var fs: int = 14
	var size: Vector2 = font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var origin: Vector2 = Vector2(-size.x / 2.0, 0)
	draw_string(font, origin + Vector2(1, 1), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, alpha * 0.7))
	draw_string(font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
