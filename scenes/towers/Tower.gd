class_name Tower extends Node2D

@export var stats: TowerStats

var targeting_mode: StringName = TargetingSystem.FIRST
var targets_in_range: Array = []
var active_buffs: Dictionary = {}  ## tag -> source tower (M2)

@onready var range_area: Area2D = $RangeArea
@onready var range_collision: CollisionShape2D = $RangeArea/CollisionShape2D
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
	queue_redraw()

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
