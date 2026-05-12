extends Node2D

@export var lifetime: float = 0.85
@export var rise_distance: float = 40.0

var _t: float = 0.0
var _text: String = ""
var _start_pos: Vector2

func setup(amount: int) -> void:
	_text = "+%dg" % amount

func _ready() -> void:
	_start_pos = position
	z_index = 30
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _t >= lifetime:
		queue_free()
		return
	# Float upward with slight ease-out arc.
	var f: float = _t / lifetime
	position.y = _start_pos.y - rise_distance * (1.0 - pow(1.0 - f, 2.0))
	queue_redraw()

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var alpha: float = 1.0 - (_t / lifetime)
	var col: Color = Color(1.0, 0.92, 0.40, alpha)
	var fs: int = 13
	var size: Vector2 = font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var origin: Vector2 = Vector2(-size.x / 2.0, 0)
	draw_string(font, origin + Vector2(1, 1), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, alpha * 0.75))
	draw_string(font, origin, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
