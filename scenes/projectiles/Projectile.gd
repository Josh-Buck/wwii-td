class_name Projectile extends Node2D

@export var speed: float = 480.0  ## px/sec

var target: Node = null
var damage: float = 0.0

func setup(target_enemy: Node, dmg: float) -> void:
	target = target_enemy
	damage = dmg

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or target.dead:
		queue_free()
		return
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	var step := speed * delta
	if step >= dist:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
		return
	global_position += to_target / dist * step
	rotation = to_target.angle()
	queue_redraw()

func _draw() -> void:
	# Bright tracer with a soft trail.
	draw_line(Vector2(-10, 0), Vector2.ZERO, Color(1, 0.85, 0.3, 0.4), 2.0)
	draw_circle(Vector2.ZERO, 3.0, Color(1, 0.95, 0.4))
