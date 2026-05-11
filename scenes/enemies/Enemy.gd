class_name Enemy extends PathFollow2D

@export var stats: EnemyStats

var hp: float = 0.0
var max_hp: float = 0.0
var dead: bool = false
var _slow_factor: float = 1.0
var _slow_until: float = 0.0
var _slow_active_prev: bool = false
var _summon_timer: Timer = null

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	rotates = false
	loop = false
	if stats == null:
		push_error("Enemy spawned without EnemyStats")
		return
	add_to_group("enemies")
	max_hp = stats.max_hp
	hp = max_hp
	if hitbox_collision and hitbox_collision.shape == null:
		var shape := CircleShape2D.new()
		shape.radius = stats.radius
		hitbox_collision.shape = shape
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
	if hitbox:
		hitbox.input_pickable = true
		hitbox.mouse_entered.connect(_on_hover_entered)
		hitbox.mouse_exited.connect(_on_hover_exited)
	# Boss reinforcement summons (e.g., Eichmann's transports, Tojo's air support).
	if stats.summon_interval > 0.0 and stats.summon_enemy_id != &"":
		_summon_timer = Timer.new()
		_summon_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
		_summon_timer.wait_time = stats.summon_interval
		_summon_timer.one_shot = false
		_summon_timer.timeout.connect(_on_summon_tick)
		add_child(_summon_timer)
		_summon_timer.start()
	queue_redraw()

func _on_summon_tick() -> void:
	if dead:
		return
	var tree := get_tree()
	if tree == null:
		return
	var wd_nodes := tree.get_nodes_in_group("wave_director")
	if wd_nodes.is_empty():
		return
	var wd = wd_nodes[0]
	if wd.has_method("spawn_enemy_external"):
		wd.spawn_enemy_external(stats.summon_enemy_id)

func _on_hover_entered() -> void:
	if not dead:
		EventBus.enemy_hovered.emit(self)

func _on_hover_exited() -> void:
	EventBus.enemy_unhovered.emit(self)

func _process(delta: float) -> void:
	if dead:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	var slow_active: bool = now < _slow_until
	if slow_active != _slow_active_prev:
		_slow_active_prev = slow_active
		queue_redraw()
	var speed_mult: float = _slow_factor if slow_active else 1.0
	progress += stats.speed * speed_mult * delta
	if stats.regen_per_sec > 0.0 and hp < max_hp:
		hp = minf(max_hp, hp + stats.regen_per_sec * delta)
		if health_bar:
			health_bar.value = hp
	if progress_ratio >= 1.0:
		_reach_end()

func apply_slow(factor: float, duration_sec: float) -> void:
	if dead:
		return
	_slow_factor = factor
	_slow_until = Time.get_ticks_msec() / 1000.0 + duration_sec

func apply_knockback(amount: float) -> void:
	if dead:
		return
	progress = max(0.0, progress - amount)

func is_camo() -> bool:
	return stats.is_camo() if stats else false

func take_damage(dmg: float, pierce_armor: bool = false) -> void:
	if dead or stats == null:
		return
	var effective: float = dmg
	if not pierce_armor:
		effective = dmg * (1.0 - clampf(stats.armor, 0.0, 0.95))
	hp -= effective
	if health_bar:
		health_bar.value = hp
	_spawn_damage_number(int(effective))
	if hp <= 0.0:
		_die()

func _spawn_damage_number(dmg: int) -> void:
	if dmg <= 0:
		return
	var scene: PackedScene = preload("res://scenes/effects/DamageNumber.tscn")
	var node: Node2D = scene.instantiate()
	node.setup(dmg)
	# Place above the enemy in world space. Add to scene root so it doesn't
	# move with the enemy (looks more natural).
	node.global_position = global_position + Vector2(0, -stats.radius - 4.0)
	var parent: Node = get_tree().current_scene
	if parent:
		parent.add_child(node)

func _die() -> void:
	dead = true
	_spawn_death_poof()
	EventBus.enemy_killed.emit(self, stats.kill_reward)
	queue_free()

func _spawn_death_poof() -> void:
	var scene: PackedScene = preload("res://scenes/effects/DeathPoof.tscn")
	var node: Node2D = scene.instantiate()
	node.setup(stats.color)
	node.global_position = global_position
	var parent: Node = get_tree().current_scene
	if parent:
		parent.add_child(node)

func _reach_end() -> void:
	dead = true
	if stats.escapes_at_path_end:
		# Mengele-style escape: no life loss, but the boss vanishes and a
		# narrative beat fires. Codex entry covers his historical evasion.
		EventBus.boss_escaped.emit(self, stats.id)
		queue_free()
		return
	for _i in stats.lives_lost_on_leak:
		EventBus.enemy_reached_end.emit(self)
	queue_free()

func _draw() -> void:
	if stats == null:
		return
	var r: float = stats.radius
	# Portrait: drawn first as a fill so the silhouette rim sits on top.
	if stats.portrait != null:
		var tex_size: Vector2 = stats.portrait.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var max_dim: float = maxf(tex_size.x, tex_size.y)
			var scale: float = (r * 2.0) / max_dim
			var draw_size: Vector2 = tex_size * scale
			draw_texture_rect(stats.portrait, Rect2(-draw_size / 2.0, draw_size), false)
			draw_arc(Vector2.ZERO, r, 0, TAU, 24, stats.color.darkened(0.5), 1.5)
			if stats.is_boss:
				draw_arc(Vector2.ZERO, r + 4.0, 0, TAU, 32, Color(1.0, 0.85, 0.3, 0.85), 2.5)
				draw_arc(Vector2.ZERO, r + 8.0, 0, TAU, 32, Color(1.0, 0.6, 0.2, 0.45), 1.5)
		return
	if stats.is_air():
		# Plane silhouette: forward-pointing triangle.
		var p1 := Vector2(-r * 0.85, -r * 0.55)
		var p2 := Vector2(r, 0)
		var p3 := Vector2(-r * 0.85, r * 0.55)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), stats.color)
		draw_polyline(PackedVector2Array([p1, p2, p3, p1]), stats.color.darkened(0.5), 1.5)
	elif stats.is_armor():
		# Tank silhouette: hull rectangle + small turret circle.
		var hull := Rect2(-r * 1.1, -r * 0.7, r * 2.2, r * 1.4)
		draw_rect(hull, stats.color)
		draw_rect(hull, stats.color.darkened(0.5), false, 1.5)
		draw_circle(Vector2(0, -r * 0.25), r * 0.45, stats.color.darkened(0.25))
	else:
		# Infantry: circle (default).
		draw_circle(Vector2.ZERO, r, stats.color)
		draw_arc(Vector2.ZERO, r, 0, TAU, 16, stats.color.darkened(0.5), 1.5)
	if stats.is_boss:
		# Glowing crown halo for bosses.
		draw_arc(Vector2.ZERO, r + 4.0, 0, TAU, 32, Color(1.0, 0.85, 0.3, 0.85), 2.5)
		draw_arc(Vector2.ZERO, r + 8.0, 0, TAU, 32, Color(1.0, 0.6, 0.2, 0.45), 1.5)
	if _slow_active_prev:
		# Cold-blue ring when slowed.
		draw_arc(Vector2.ZERO, r + 3.0, 0, TAU, 32, Color(0.45, 0.75, 1.0, 0.9), 2.0)
