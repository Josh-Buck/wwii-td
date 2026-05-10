class_name Tower extends Node2D

@export var stats: TowerStats

const _PRIORITY_CYCLE: Array[StringName] = [
	TargetingSystem.FIRST,
	TargetingSystem.LAST,
	TargetingSystem.STRONG,
	TargetingSystem.CLOSE,
]

var targeting_mode: StringName = TargetingSystem.FIRST
var targets_in_range: Array = []
var active_buffs: Dictionary = {}  ## tag -> source tower (M2)
var owning_slot: Node = null   ## set by Map on placement; cleared on sell

@onready var range_area: Area2D = $RangeArea
@onready var range_collision: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var hover_area: Area2D = $HoverArea
@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	if stats == null:
		push_error("Tower spawned without TowerStats")
		return
	# Always assign a fresh shape per tower so range tweaks don't leak
	# across instances via a shared scene-level sub_resource.
	if range_collision:
		var shape := CircleShape2D.new()
		shape.radius = effective_range()
		range_collision.shape = shape
	fire_timer.wait_time = 1.0 / max(0.0001, effective_fire_rate())
	fire_timer.one_shot = false
	if not fire_timer.timeout.is_connected(_on_fire_tick):
		fire_timer.timeout.connect(_on_fire_tick)
	fire_timer.start()
	range_area.body_entered.connect(_on_target_entered)
	range_area.body_exited.connect(_on_target_exited)
	range_area.area_entered.connect(_on_target_area_entered)
	range_area.area_exited.connect(_on_target_area_exited)
	hover_area.mouse_entered.connect(_on_hover_entered)
	hover_area.mouse_exited.connect(_on_hover_exited)
	hover_area.input_event.connect(_on_hover_input)
	queue_redraw()

func _on_hover_entered() -> void:
	EventBus.tower_hovered.emit(self)

func _on_hover_exited() -> void:
	EventBus.tower_unhovered.emit(self)

func _on_hover_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		EventBus.tower_clicked.emit(self)

func cycle_targeting_mode() -> StringName:
	var idx := _PRIORITY_CYCLE.find(targeting_mode)
	targeting_mode = _PRIORITY_CYCLE[(idx + 1) % _PRIORITY_CYCLE.size()]
	return targeting_mode

func sell() -> void:
	if stats == null:
		queue_free()
		return
	var refund := int(stats.cost * 0.75)
	if owning_slot and is_instance_valid(owning_slot) and owning_slot.has_method("clear_tower"):
		owning_slot.clear_tower()
	GameState.add_gold(refund)
	EventBus.tower_sold.emit(self, refund)
	queue_free()

func effective_damage() -> float:
	return stats.damage  # M2 will fold in adjacency buffs

func effective_fire_rate() -> float:
	return stats.fire_rate

func effective_range() -> float:
	return stats.range_px

func _on_target_entered(body: Node) -> void:
	if body is Enemy and not body in targets_in_range:
		targets_in_range.append(body)

func _on_target_exited(body: Node) -> void:
	targets_in_range.erase(body)

func _on_target_area_entered(area: Node) -> void:
	var p = area.get_parent()
	if p is Enemy and not p in targets_in_range:
		targets_in_range.append(p)

func _on_target_area_exited(area: Node) -> void:
	var p = area.get_parent()
	if p:
		targets_in_range.erase(p)

func _on_fire_tick() -> void:
	targets_in_range = targets_in_range.filter(func(e): return is_instance_valid(e) and not e.dead)
	if targets_in_range.is_empty():
		return
	var target = TargetingSystem.pick(targets_in_range, targeting_mode, global_position)
	if target == null:
		return
	_fire_at(target)

func _fire_at(target: Node) -> void:
	# M0: instant-hit damage. Projectiles arrive in M1.
	if target.has_method("take_damage"):
		target.take_damage(effective_damage())

func _draw() -> void:
	if stats == null:
		return
	# Placeholder visual: filled circle in faction color with darker rim.
	draw_circle(Vector2.ZERO, 18.0, stats.color)
	draw_arc(Vector2.ZERO, 18.0, 0, TAU, 24, stats.color.darkened(0.4), 2.0)
