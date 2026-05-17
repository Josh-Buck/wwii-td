class_name Projectile extends Node2D

@export var speed: float = 480.0  ## px/sec

var target: Node = null
var damage: float = 0.0
var aoe_radius: float = 0.0
var color: Color = Color(1, 0.95, 0.4)
var style: StringName = &"bullet"   ## bullet | shell | laser | drop
var slow_factor: float = 1.0        ## 1.0 = no slow; <1.0 multiplies enemy speed
var slow_duration: float = 0.0
var knockback: float = 0.0          ## px to push enemy backward along path
var pierce_armor: bool = false      ## ignore enemy armor reduction
var instakill_below_hp: float = 0.0 ## kill outright if target hp <= this
var _spawn_pos: Vector2
var _trail: Array[Vector2] = []  ## recent positions for trail rendering
const _TRAIL_MAX: int = 6
var owner_tower: Node = null  ## set on setup so kills credit back to the firing tower

func setup(target_enemy: Node, dmg: float, opts: Dictionary = {}) -> void:
	target = target_enemy
	damage = dmg
	aoe_radius = opts.get("aoe", 0.0)
	color = opts.get("color", color)
	style = opts.get("style", &"bullet")
	slow_factor = opts.get("slow_factor", 1.0)
	slow_duration = opts.get("slow_duration", 0.0)
	knockback = opts.get("knockback", 0.0)
	pierce_armor = opts.get("pierce_armor", false)
	instakill_below_hp = opts.get("instakill_below_hp", 0.0)

func _ready() -> void:
	_spawn_pos = global_position
	# Laser hits instantly — resolve and free immediately.
	if style == &"laser":
		if target and is_instance_valid(target):
			_resolve_hit(target.global_position)
		# Stay alive for one frame so the laser line draws.
		await get_tree().process_frame
		queue_free()

func _process(delta: float) -> void:
	if style == &"laser":
		return  # already resolved
	if target == null or not is_instance_valid(target) or target.dead:
		queue_free()
		return
	var to_target: Vector2 = target.global_position - global_position
	var dist := to_target.length()
	var step := speed * delta
	# Sample trail in local space relative to current position.
	_trail.push_front(Vector2.ZERO)
	if _trail.size() > _TRAIL_MAX:
		_trail.resize(_TRAIL_MAX)
	# Translate older trail entries backward to keep them stationary in world.
	var back: Vector2 = -to_target / max(0.0001, dist) * step
	for i in range(1, _trail.size()):
		_trail[i] += back
	if step >= dist:
		_resolve_hit(target.global_position)
		queue_free()
		return
	global_position += to_target / dist * step
	rotation = to_target.angle()
	queue_redraw()

func _resolve_hit(impact_pos: Vector2) -> void:
	_spawn_impact_spark(impact_pos)
	if aoe_radius <= 0.0:
		_apply_to(target, impact_pos)
		return
	var tree := get_tree()
	if tree == null:
		return
	for enemy in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if impact_pos.distance_to(enemy.global_position) <= aoe_radius:
			_apply_to(enemy, impact_pos)

func _xp_for(enemy: Node) -> int:
	# Bosses worth more XP. Otherwise scale loosely with kill_reward.
	if enemy == null or enemy.stats == null:
		return 1
	if enemy.stats.is_boss:
		return 20
	return max(1, int(enemy.stats.kill_reward / 4))

func _spawn_impact_spark(at: Vector2) -> void:
	var scene: PackedScene = preload("res://scenes/effects/ImpactSpark.tscn")
	var node: Node2D = scene.instantiate()
	node.setup(color)
	node.global_position = at
	var parent: Node = get_tree().current_scene
	if parent:
		parent.add_child(node)

func _apply_to(enemy: Node, _impact: Vector2) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	# Instakill below threshold (Pavlichenko's White Death).
	if instakill_below_hp > 0.0 and enemy.hp <= instakill_below_hp:
		if enemy.has_method("take_damage"):
			var was_alive: bool = not enemy.dead
			enemy.take_damage(99999.0, true)
			if was_alive and enemy.dead and owner_tower and is_instance_valid(owner_tower):
				owner_tower.kills += 1
				if owner_tower.has_method("grant_hero_xp"):
					owner_tower.grant_hero_xp(_xp_for(enemy))
		return
	if enemy.has_method("take_damage"):
		var was_alive: bool = not enemy.dead
		var pre_hp: float = enemy.hp
		enemy.take_damage(damage, pierce_armor)
		if owner_tower and is_instance_valid(owner_tower):
			owner_tower.damage_dealt += int(max(0.0, pre_hp - max(0.0, enemy.hp)))
			if was_alive and enemy.dead:
				owner_tower.kills += 1
				if owner_tower.has_method("grant_hero_xp"):
					owner_tower.grant_hero_xp(_xp_for(enemy))
	if slow_factor < 1.0 and slow_duration > 0.0 and enemy.has_method("apply_slow"):
		enemy.apply_slow(slow_factor, slow_duration)
	if knockback > 0.0 and enemy.has_method("apply_knockback"):
		enemy.apply_knockback(knockback)

func _draw() -> void:
	# Smoke trail behind moving projectiles (skip laser since it's instant).
	if style != &"laser" and _trail.size() > 1:
		for i in range(1, _trail.size()):
			var a: float = 1.0 - float(i) / _TRAIL_MAX
			var c := color
			c.a = a * 0.55
			draw_line(_trail[i - 1], _trail[i], c, 3.0 * (1.0 - float(i) / _TRAIL_MAX))
	match style:
		&"laser":
			# Thin instant tracer from spawn to target position.
			var local_target: Vector2 = Vector2.ZERO
			if target and is_instance_valid(target):
				local_target = target.global_position - global_position
			draw_line(Vector2.ZERO, local_target, color.lightened(0.4), 2.0)
			draw_circle(local_target, 4.0, color)
		&"shell":
			# Chunky artillery shell with glow.
			draw_circle(Vector2.ZERO, 7.0, color)
			draw_arc(Vector2.ZERO, 7.0, 0, TAU, 16, color.lightened(0.3), 1.5)
			draw_circle(Vector2(-4, 0), 3.0, color.lightened(0.5))
		_:
			# Bullet (default).
			draw_line(Vector2(-10, 0), Vector2.ZERO, Color(color.r, color.g, color.b, 0.4), 2.0)
			draw_circle(Vector2.ZERO, 3.0, color)
