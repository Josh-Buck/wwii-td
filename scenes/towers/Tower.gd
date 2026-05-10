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

const _PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/Projectile.tscn")

@onready var range_area: Area2D = $RangeArea
@onready var range_collision: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var hover_area: Area2D = $HoverArea
@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	if stats == null:
		push_error("Tower spawned without TowerStats")
		return
	add_to_group("towers")
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
	# Leave the towers group BEFORE emitting tower_sold so adjacency
	# recompute on the remaining towers doesn't see this one.
	remove_from_group("towers")
	EventBus.tower_sold.emit(self, refund)
	queue_free()

func effective_damage() -> float:
	return stats.damage

func effective_fire_rate() -> float:
	if stats == null:
		return 1.0
	var multiplier := 1.0 + AdjacencySystem.RATE_BONUS_PER_BUFF * active_buffs.size()
	return stats.fire_rate * multiplier

func effective_range() -> float:
	return stats.range_px

func apply_buffs() -> void:
	if fire_timer:
		fire_timer.wait_time = 1.0 / max(0.0001, effective_fire_rate())
	queue_redraw()
	EventBus.tower_buffs_changed.emit(self)

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
	if not is_instance_valid(target):
		return
	var projectile := _PROJECTILE_SCENE.instantiate()
	var aoe: float = stats.aoe_radius if stats else 0.0
	projectile.setup(target, effective_damage(), aoe)
	projectile.global_position = global_position
	var container := _find_projectiles_container()
	if container:
		container.add_child(projectile)
	else:
		get_parent().add_child(projectile)

func _find_projectiles_container() -> Node:
	var n: Node = get_parent()
	while n:
		var c: Node = n.get_node_or_null("Projectiles")
		if c:
			return c
		n = n.get_parent()
	return null

func _draw() -> void:
	if stats == null:
		return
	if stats.portrait != null:
		_draw_portrait()
	else:
		# Placeholder visual: faction-colored disc with last-name initials.
		draw_circle(Vector2.ZERO, 22.0, stats.color)
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 32, stats.color.darkened(0.4), 2.0)
		_draw_initials()
	# Synergy indicator: golden ring when at least one adjacency buff is active.
	if active_buffs.size() > 0:
		draw_arc(Vector2.ZERO, 30.0, 0, TAU, 32, Color(1.0, 0.85, 0.3, 0.85), 2.5)
	# Faction flag stripe always shows (over portrait or placeholder).
	_draw_flag_stripe(stats.faction)

func _draw_portrait() -> void:
	var tex: Texture2D = stats.portrait
	if tex == null:
		return
	var tex_size: Vector2 = tex.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	var max_dim: float = maxf(tex_size.x, tex_size.y)
	var scale: float = 44.0 / max_dim   # fit in ~44px circle
	var draw_size: Vector2 = tex_size * scale
	draw_texture_rect(tex, Rect2(-draw_size / 2.0, draw_size), false)
	draw_arc(Vector2.ZERO, 23.0, 0, TAU, 32, stats.color.darkened(0.4), 2.0)

func _draw_initials() -> void:
	if stats == null or stats.display_name == "":
		return
	var text: String = _short_initials()
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var fs: int = 13
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	# draw_string anchors at baseline; offset y so text vertically centers near 0.
	var pos := Vector2(-size.x / 2.0, size.y / 4.0)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.08, 0.08, 0.08))

func _short_initials() -> String:
	var parts := stats.display_name.split(" ", false)
	if parts.is_empty():
		return stats.display_name.substr(0, 3).to_upper()
	return parts[-1].substr(0, 3).to_upper()

func _draw_flag_stripe(faction: StringName) -> void:
	# Small banner above the tower disc: y = -34 to -28 (6px tall, 32px wide)
	var x: float = -16.0
	var y: float = -34.0
	var w: float = 32.0
	var h: float = 6.0
	match faction:
		&"us":
			# 3 horizontal stripes: red, white, blue (simplified)
			draw_rect(Rect2(x, y, w, h / 3.0), Color(0.78, 0.10, 0.16))
			draw_rect(Rect2(x, y + h / 3.0, w, h / 3.0), Color.WHITE)
			draw_rect(Rect2(x, y + 2.0 * h / 3.0, w, h / 3.0), Color(0.05, 0.13, 0.39))
		&"uk":
			# Union flag approximation: blue background, white cross, red centerline
			draw_rect(Rect2(x, y, w, h), Color(0.05, 0.13, 0.39))
			draw_rect(Rect2(x, y + h / 2.0 - 1.0, w, 2.0), Color.WHITE)
			draw_rect(Rect2(x + w / 2.0 - 1.0, y, 2.0, h), Color.WHITE)
			draw_rect(Rect2(x + w / 2.0 - 0.5, y, 1.0, h), Color(0.78, 0.10, 0.16))
		&"ussr":
			# Solid red banner
			draw_rect(Rect2(x, y, w, h), Color(0.72, 0.04, 0.04))
		&"resistance":
			# French tricolor
			draw_rect(Rect2(x, y, w / 3.0, h), Color(0.05, 0.13, 0.39))
			draw_rect(Rect2(x + w / 3.0, y, w / 3.0, h), Color.WHITE)
			draw_rect(Rect2(x + 2.0 * w / 3.0, y, w / 3.0, h), Color(0.78, 0.10, 0.16))
		_:
			pass
