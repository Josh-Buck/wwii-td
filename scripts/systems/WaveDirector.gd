class_name WaveDirector extends Node

# Loads wave schedules from JSON during dev. Bake to .tres before web export
# (PCK is read-only; mtime hot-reload only works in editor / desktop).

signal wave_started(wave_index: int)
signal wave_ended(wave_index: int)
signal all_waves_completed

@export var waves_json_path: String = "res://data/waves/m0.json"
@export var enemy_scene: PackedScene
@export var enemy_registry: Dictionary = {}  ## StringName -> EnemyStats

var _waves: Array = []
var _current_wave_index: int = -1
var _enemies_alive: int = 0
var _wave_active: bool = false
var _spawning_active: bool = false
var _enemies_killed_this_wave: int = 0
var _enemies_total_this_wave: int = 0

@onready var _path: Path2D = _resolve_path()

func _resolve_path() -> Path2D:
	var p := get_parent()
	while p:
		var n: Node = p.get_node_or_null("Path")
		if n is Path2D:
			return n
		p = p.get_parent()
	return null

func _ready() -> void:
	add_to_group("wave_director")
	_load_waves()
	EventBus.enemy_killed.connect(_on_enemy_killed_for_count)
	EventBus.enemy_reached_end.connect(_on_enemy_leaked)

func get_boss_id_for_current_wave() -> StringName:
	if _current_wave_index < 0 or _current_wave_index >= _waves.size():
		return &""
	var spawns: Array = _waves[_current_wave_index].get("spawns", [])
	for s in spawns:
		var enemy_id: StringName = StringName(s.get("enemy", ""))
		if enemy_registry.has(enemy_id):
			var stats: Resource = enemy_registry[enemy_id]
			if stats and stats.is_boss:
				return enemy_id
	return &""

func get_next_wave_spawns() -> Array:
	var idx: int = _current_wave_index + 1
	if idx >= _waves.size():
		return []
	return _waves[idx].get("spawns", [])

func get_next_wave_summary() -> String:
	var next_idx: int = _current_wave_index + 1
	if next_idx >= _waves.size():
		return "(final wave cleared)"
	var spawns: Array = _waves[next_idx].get("spawns", [])
	var counts: Dictionary = {}
	for s in spawns:
		var enemy_id: String = s.get("enemy", "")
		var count: int = int(s.get("count", 1))
		counts[enemy_id] = counts.get(enemy_id, 0) + count
	var parts: Array[String] = []
	for enemy_id in counts:
		parts.append("%dx %s" % [counts[enemy_id], _humanize(enemy_id)])
	return ", ".join(parts)

func _humanize(enemy_id: String) -> String:
	var label := enemy_id.replace("_", " ")
	return label.capitalize()

func _load_waves() -> void:
	var f := FileAccess.open(waves_json_path, FileAccess.READ)
	if f == null:
		push_error("WaveDirector: missing %s" % waves_json_path)
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Array:
		_waves = parsed
	else:
		push_error("WaveDirector: %s root must be an array" % waves_json_path)

func has_more_waves() -> bool:
	return _current_wave_index + 1 < _waves.size()

func wave_count() -> int:
	return _waves.size()

func start_next_wave() -> void:
	if not has_more_waves():
		all_waves_completed.emit()
		return
	_current_wave_index += 1
	_wave_active = true
	_enemies_alive = 0
	_enemies_killed_this_wave = 0
	var wave_def: Dictionary = _waves[_current_wave_index]
	_enemies_total_this_wave = 0
	for s in wave_def.get("spawns", []):
		_enemies_total_this_wave += int(s.get("count", 1))
	wave_started.emit(_current_wave_index)
	EventBus.wave_started.emit(_current_wave_index)
	_spawn_wave_async(wave_def.get("spawns", []))

func get_enemies_remaining() -> int:
	return max(0, _enemies_total_this_wave - _enemies_killed_this_wave)

func get_wave_total() -> int:
	return _enemies_total_this_wave

func _spawn_wave_async(spawns: Array) -> void:
	_spawning_active = true
	for spawn in spawns:
		var enemy_id := StringName(spawn.get("enemy", ""))
		var count: int = int(spawn.get("count", 1))
		var interval: float = float(spawn.get("interval", 1.0))
		var delay: float = float(spawn.get("delay", 0.0))
		if delay > 0.0:
			await get_tree().create_timer(delay).timeout
			if not _wave_active:
				_spawning_active = false
				return
		for i in count:
			if not _wave_active:
				_spawning_active = false
				return
			_spawn_enemy(enemy_id)
			if i + 1 < count:
				await get_tree().create_timer(interval).timeout
	_spawning_active = false
	_check_wave_end()

func spawn_enemy_external(enemy_id: StringName) -> void:
	# Allows boss minions / scripted spawns to reuse the same instantiation path.
	_spawn_enemy(enemy_id)

func _spawn_enemy(enemy_id: StringName) -> void:
	if enemy_scene == null:
		push_error("WaveDirector.enemy_scene not set")
		return
	if not enemy_registry.has(enemy_id):
		push_error("WaveDirector: no enemy registered as %s" % enemy_id)
		return
	var enemy = enemy_scene.instantiate()
	enemy.stats = enemy_registry[enemy_id]
	if _path:
		_path.add_child(enemy)
	else:
		add_child(enemy)
	_enemies_alive += 1

func _on_enemy_killed_for_count(_e: Node, _r: int) -> void:
	_enemies_killed_this_wave += 1
	_dec_alive()

func _on_enemy_leaked(_e: Node) -> void:
	_enemies_killed_this_wave += 1
	_dec_alive()

func _dec_alive() -> void:
	_enemies_alive = max(0, _enemies_alive - 1)
	_check_wave_end()

func _check_wave_end() -> void:
	if _wave_active and not _spawning_active and _enemies_alive == 0:
		_wave_active = false
		wave_ended.emit(_current_wave_index)
		EventBus.wave_ended.emit(_current_wave_index)
