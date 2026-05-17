class_name WaveDirector extends Node

# Loads wave schedules from JSON during dev. After the scripted list runs out
# we switch to endless mode: each subsequent wave is generated procedurally
# with a difficulty multiplier applied to enemy HP and rewards.

signal wave_started(wave_index: int)
signal wave_ended(wave_index: int)
signal all_waves_completed  ## retained for back-compat; never fired in endless mode

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
var _difficulty_mult: float = 1.0  ## HP + reward scaler applied to spawned enemies
var _wave_start_time_ms: int = 0  ## set when a wave starts; used for clear-time bonus

const _ENDLESS_HP_PER_WAVE: float = 0.10
const _ENDLESS_REWARD_PER_WAVE: float = 0.07
const _ENDLESS_BASE_POOL: Array[StringName] = [
	&"wehrmacht_infantry", &"panzer_iii", &"stuka",
	&"waffen_ss", &"tiger_i", &"banzai", &"bersaglieri",
]
const _ENDLESS_BOSS_POOL: Array[StringName] = [
	&"rommel", &"eichmann", &"heydrich", &"himmler", &"tojo",
]
const _ENDLESS_BOSS_INTERVAL: int = 5

@onready var _path: Path2D = _resolve_path()
var _rng := RandomNumberGenerator.new()

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
	_rng.randomize()
	_load_waves()
	EventBus.enemy_killed.connect(_on_enemy_killed_for_count)
	EventBus.enemy_reached_end.connect(_on_enemy_leaked)

func get_boss_id_for_current_wave() -> StringName:
	var spawns: Array = _wave_spawns_at(_current_wave_index)
	for s in spawns:
		var enemy_id: StringName = StringName(s.get("enemy", ""))
		if enemy_registry.has(enemy_id):
			var stats: Resource = enemy_registry[enemy_id]
			if stats and stats.is_boss:
				return enemy_id
	return &""

func get_next_wave_spawns() -> Array:
	return _wave_spawns_at(_current_wave_index + 1)

func get_next_wave_summary() -> String:
	var spawns: Array = get_next_wave_spawns()
	if spawns.is_empty():
		return "(no preview)"
	var counts: Dictionary = {}
	for s in spawns:
		var enemy_id: String = s.get("enemy", "")
		var count: int = int(s.get("count", 1))
		counts[enemy_id] = counts.get(enemy_id, 0) + count
	var parts: Array[String] = []
	for enemy_id in counts:
		parts.append("%dx %s" % [counts[enemy_id], _humanize(enemy_id)])
	return ", ".join(parts)

func _wave_spawns_at(idx: int) -> Array:
	if idx < 0:
		return []
	if idx < _waves.size():
		return _waves[idx].get("spawns", [])
	return _generate_endless_spawns(idx)

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
	return true  ## endless: there is always another wave

func wave_count() -> int:
	return _waves.size()  ## scripted-only count, used by UI for progress display

func is_endless() -> bool:
	return _current_wave_index + 1 >= _waves.size()

func current_wave_number() -> int:
	return _current_wave_index + 1

func start_next_wave() -> void:
	_current_wave_index += 1
	_wave_active = true
	_enemies_alive = 0
	_enemies_killed_this_wave = 0
	var spawns: Array = _wave_spawns_at(_current_wave_index)
	# Difficulty: scripted waves use the JSON-balanced numbers; endless waves
	# apply a per-wave multiplier on top.
	if _current_wave_index < _waves.size():
		_difficulty_mult = 1.0
	else:
		var endless_step: int = _current_wave_index - _waves.size() + 1
		_difficulty_mult = pow(1.0 + _ENDLESS_HP_PER_WAVE, endless_step)
	_enemies_total_this_wave = 0
	for s in spawns:
		_enemies_total_this_wave += int(s.get("count", 1))
	_wave_start_time_ms = Time.get_ticks_msec()
	wave_started.emit(_current_wave_index)
	EventBus.wave_started.emit(_current_wave_index)
	_spawn_wave_async(spawns)

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
	# Scripted late waves (10+) get a small bite so they don't feel trivial.
	var late_bump: float = 1.0
	if _current_wave_index >= 9 and _current_wave_index < _waves.size():
		late_bump = 1.0 + 0.05 * (_current_wave_index - 8)  ## +5% per wave from 10 → +30% at 15
	enemy.hp_mult = _difficulty_mult * GameState.DIFFICULTY_HP_MULT[GameState.difficulty] * late_bump
	# Endless rewards scaled DOWN slightly per wave so income doesn't snowball forever.
	enemy.reward_mult = max(0.6, 1.0 - 0.02 * max(0, _current_wave_index - _waves.size() + 1))
	if _path:
		_path.add_child(enemy)
	else:
		add_child(enemy)
	_enemies_alive += 1

func _generate_endless_spawns(wave_idx: int) -> Array:
	var endless_step: int = wave_idx - _waves.size() + 1
	var spawns: Array = []
	# Boss every Nth endless wave
	if endless_step % _ENDLESS_BOSS_INTERVAL == 0:
		var boss_id: String = String(_ENDLESS_BOSS_POOL[(endless_step / _ENDLESS_BOSS_INTERVAL - 1) % _ENDLESS_BOSS_POOL.size()])
		spawns.append({"enemy": boss_id, "count": 1, "interval": 1.0, "delay": 1.0})
	# Mixed wave: grows by ~2 enemies per endless wave; intervals tighten.
	var total: int = 8 + endless_step * 2
	var interval: float = max(0.25, 0.65 - endless_step * 0.02)
	var pool_size: int = min(_ENDLESS_BASE_POOL.size(), 3 + endless_step / 2)
	var per_kind: int = max(1, total / pool_size)
	for i in pool_size:
		var enemy_id: String = String(_ENDLESS_BASE_POOL[i])
		if not enemy_registry.has(StringName(enemy_id)):
			continue
		spawns.append({
			"enemy": enemy_id,
			"count": per_kind,
			"interval": interval,
			"delay": 0.2 * i,
		})
	return spawns

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
		# Clear-time bonus: faster clears grant up to +50g and a toast.
		# Threshold scales with wave size so a 50-enemy wave isn't unfair.
		var elapsed_s: float = (Time.get_ticks_msec() - _wave_start_time_ms) / 1000.0
		var expected_s: float = 6.0 + _enemies_total_this_wave * 0.8
		var bonus_gold: int = 0
		if elapsed_s < expected_s:
			var ratio: float = clamp(1.0 - (elapsed_s / expected_s), 0.0, 1.0)
			bonus_gold = int(10 + 25 * ratio)  ## was 20 + 60, halved
			GameState.add_gold(bonus_gold)
		EventBus.wave_cleared.emit(_current_wave_index, bonus_gold, elapsed_s)
		wave_ended.emit(_current_wave_index)
		EventBus.wave_ended.emit(_current_wave_index)
