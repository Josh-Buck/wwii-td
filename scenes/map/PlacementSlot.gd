class_name PlacementSlot extends Area2D

signal slot_clicked(slot)

@export var radius: float = 28.0

var _tower: Node = null

func _ready() -> void:
	input_pickable = true
	if get_child_count() == 0:
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = radius
		col.shape = shape
		add_child(col)
	queue_redraw()

func occupied() -> bool:
	return _tower != null and is_instance_valid(_tower)

func set_tower(tower: Node) -> void:
	_tower = tower
	queue_redraw()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(self)

func _draw() -> void:
	var alpha := 0.15 if occupied() else 0.30
	draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, alpha))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1, 1, 1, 0.6), 2.0)
