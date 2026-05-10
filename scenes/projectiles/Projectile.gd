class_name Projectile extends Node2D

@export var speed: float = 480.0  ## px/sec

var target: Node = null
var damage: float = 0.0
var aoe_radius: float = 0.0  ## 0 = single-target

func setup(target_enemy: Node, dmg: float, aoe: float = 0.0) -> void:
	target = target_enemy
	damage = dmg
	aoe_radius = aoe

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.dead:
		queue_free()
		return
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	var step := speed * delta
	if step >= dist:
		_resolve_hit(target.global_position)
		queue_free()
		return
	global_position += to_target / dist * step
	rotation = to_target.angle()
	queue_redraw()

func _resolve_hit(impact_pos: Vector2) -> void:
	if aoe_radius <= 0.0:
		# Single-target hit
		if target and is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)
		return
	# AoE: damage all live enemies within radius of impact
	var tree := get_tree()
	if tree == null:
		return
	for enemy in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if impact_pos.distance_to(enemy.global_position) <= aoe_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

func _draw() -> void:
	# Bright tracer with a soft trail.
	draw_line(Vector2(-10, 0), Vector2.ZERO, Color(1, 0.85, 0.3, 0.4), 2.0)
	draw_circle(Vector2.ZERO, 3.0, Color(1, 0.95, 0.4))
