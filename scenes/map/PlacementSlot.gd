class_name PlacementSlot extends Area2D

signal slot_clicked(slot)

@export var radius: float = 28.0

var _tower: Node = null

func _ready() -> void:
	# Slots stay clickable while the tree is paused so the player can
	# place towers as part of strategic planning during pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
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

func clear_tower() -> void:
	_tower = null
	queue_redraw()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(self)

func _draw() -> void:
	# Empty slots: bright cyan ring on faint cyan fill so they stand out
	# from the dirt path and the red enemies. Occupied slots fade.
	var fill_alpha := 0.08 if occupied() else 0.25
	draw_circle(Vector2.ZERO, radius, Color(0.2, 0.7, 1.0, fill_alpha))
	var rim_alpha := 0.4 if occupied() else 0.95
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.55, 0.85, 1.0, rim_alpha), 3.0)
