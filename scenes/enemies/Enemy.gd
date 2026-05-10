class_name Enemy extends PathFollow2D

@export var stats: EnemyStats

var hp: float = 0.0
var max_hp: float = 0.0
var dead: bool = false

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
	queue_redraw()

func _on_hover_entered() -> void:
	if not dead:
		EventBus.enemy_hovered.emit(self)

func _on_hover_exited() -> void:
	EventBus.enemy_unhovered.emit(self)

func _process(delta: float) -> void:
	if dead:
		return
	progress += stats.speed * delta
	if progress_ratio >= 1.0:
		_reach_end()

func is_camo() -> bool:
	return stats.is_camo() if stats else false

func take_damage(dmg: float) -> void:
	if dead or stats == null:
		return
	var effective: float = dmg * (1.0 - clampf(stats.armor, 0.0, 0.95))
	hp -= effective
	if health_bar:
		health_bar.value = hp
	if hp <= 0.0:
		_die()

func _die() -> void:
	dead = true
	EventBus.enemy_killed.emit(self, stats.kill_reward)
	queue_free()

func _reach_end() -> void:
	dead = true
	for _i in stats.lives_lost_on_leak:
		EventBus.enemy_reached_end.emit(self)
	queue_free()

func _draw() -> void:
	if stats == null:
		return
	var r: float = stats.radius
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
