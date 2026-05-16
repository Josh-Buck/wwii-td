class_name BombingRun extends Node2D

# Player-triggered global AoE strike. Player clicks a point on the map; a
# 1.5s warning telegraph appears at that spot, then enemies inside the
# blast radius take damage. 90 s cooldown after each use.

const COOLDOWN: float = 90.0
const TELEGRAPH_TIME: float = 1.5
const DAMAGE: float = 320.0
const RADIUS: float = 110.0

signal cooldown_changed(remaining: float)
signal targeting_started
signal targeting_cancelled
signal strike_complete

var _cooldown_left: float = 0.0
var _targeting: bool = false
var _telegraph_pos: Vector2 = Vector2.ZERO
var _telegraph_left: float = 0.0
var _telegraph_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("bombing_run")

func is_ready() -> bool:
	return _cooldown_left <= 0.0 and not _telegraph_active

func cooldown_remaining() -> float:
	return _cooldown_left

func is_targeting() -> bool:
	return _targeting

func toggle_targeting() -> void:
	if not is_ready():
		return
	_targeting = not _targeting
	if _targeting:
		targeting_started.emit()
	else:
		targeting_cancelled.emit()
	queue_redraw()

func cancel_targeting() -> void:
	if _targeting:
		_targeting = false
		targeting_cancelled.emit()
		queue_redraw()

func fire_at(pos: Vector2) -> void:
	if not is_ready():
		return
	_targeting = false
	_telegraph_pos = pos
	_telegraph_left = TELEGRAPH_TIME
	_telegraph_active = true
	_cooldown_left = COOLDOWN
	GameState.bombing_run_used = true
	global_position = Vector2.ZERO
	queue_redraw()

func _process(delta: float) -> void:
	# Cooldown only ticks during active waves so the player can't farm it
	# by waiting between rounds. Telegraph still resolves if already fired.
	if _cooldown_left > 0.0 and GameState.wave_in_progress:
		_cooldown_left = max(0.0, _cooldown_left - delta)
		cooldown_changed.emit(_cooldown_left)
	if _telegraph_active:
		_telegraph_left -= delta
		queue_redraw()
		if _telegraph_left <= 0.0:
			_telegraph_active = false
			_apply_damage()
			EventBus.screen_shake.emit(14.0, 0.55)
			strike_complete.emit()
			queue_redraw()
	if _targeting:
		queue_redraw()

func _apply_damage() -> void:
	var r2: float = RADIUS * RADIUS
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.global_position.distance_squared_to(_telegraph_pos) <= r2:
			if e.has_method("take_damage"):
				e.take_damage(DAMAGE, true)  # pierces armor

func _draw() -> void:
	if _targeting and not _telegraph_active:
		var mouse_pos: Vector2 = get_global_mouse_position()
		draw_circle(mouse_pos, RADIUS, Color(1.0, 0.85, 0.3, 0.15))
		draw_arc(mouse_pos, RADIUS, 0, TAU, 64, Color(1.0, 0.85, 0.3, 0.75), 2.0)
		draw_line(mouse_pos - Vector2(6, 0), mouse_pos + Vector2(6, 0), Color(1.0, 0.85, 0.3, 0.9), 2.0)
		draw_line(mouse_pos - Vector2(0, 6), mouse_pos + Vector2(0, 6), Color(1.0, 0.85, 0.3, 0.9), 2.0)
	if _telegraph_active:
		var t: float = clamp(_telegraph_left / TELEGRAPH_TIME, 0.0, 1.0)
		var color := Color(1.0, 0.4, 0.3, 0.45 - 0.20 * t)
		draw_circle(_telegraph_pos, RADIUS, color)
		draw_arc(_telegraph_pos, RADIUS, 0, TAU, 64, Color(1.0, 0.4, 0.3, 0.95), 3.0)
		var inner: float = RADIUS * (1.0 - t)
		draw_arc(_telegraph_pos, inner, 0, TAU, 64, Color(1.0, 0.85, 0.5, 0.9), 2.0)
