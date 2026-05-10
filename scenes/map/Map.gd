class_name Map extends Node2D

## Base class for all map scenes. Subclassed maps (m0_field, ardennes, etc.)
## set their own path curve, slot positions, and enemy/tower registries.

@export var available_towers: Array = []  ## TowerStats list (untyped to avoid scene-export quirks)
@export var enemy_set: Dictionary = {}  ## StringName -> EnemyStats
@export var tower_scene: PackedScene
@export var enemy_scene: PackedScene
@export var available_bonds: Array = []  ## WarBond list

@onready var path: Path2D = $Path
@onready var slots_container: Node2D = $PlacementSlots
@onready var towers_container: Node2D = $Towers
@onready var enemies_container: Node2D = $Enemies
@onready var wave_director: WaveDirector = $WaveDirector
@onready var hud: CanvasLayer = $HUD

var slots: Array = []
var selected_tower_stats: TowerStats = null

const _GHOST_SCENE: PackedScene = preload("res://scenes/towers/PlacementGhost.tscn")
const _PATH_CLEARANCE: float = 36.0  ## minimum px from path centreline
const _TOWER_CLEARANCE: float = 56.0 ## minimum px between towers
const _MAP_MARGIN: float = 32.0      ## keep towers off the screen edge

var _placement_ghost: Node = null
var _placement_active: bool = false
var _path_baked_points: PackedVector2Array

func _ready() -> void:
	# Fallback bindings: if scene-level exports didn't populate (typed
	# array quirks, version differences, etc.), load sensible defaults
	# so M0 is playable out of the box.
	if tower_scene == null:
		tower_scene = preload("res://scenes/towers/Tower.tscn")
	if enemy_scene == null:
		enemy_scene = preload("res://scenes/enemies/Enemy.tscn")
	if available_towers.is_empty():
		available_towers = [
			load("res://data/towers/patton.tres"),
			load("res://data/towers/eisenhower.tres"),
			load("res://data/towers/churchill.tres"),
			load("res://data/towers/anne_frank.tres"),
			load("res://data/towers/montgomery.tres"),
			load("res://data/towers/pavlichenko.tres"),
			load("res://data/towers/fdr.tres"),
			load("res://data/towers/bletchley.tres"),
			load("res://data/towers/airborne_101.tres"),
		]
	if enemy_set.is_empty():
		enemy_set = {
			&"wehrmacht_infantry": load("res://data/enemies/wehrmacht_infantry.tres"),
			&"panzer_iii": load("res://data/enemies/panzer_iii.tres"),
			&"stuka": load("res://data/enemies/stuka.tres"),
			&"rommel": load("res://data/enemies/rommel.tres"),
		}
	if available_bonds.is_empty():
		available_bonds = [
			load("res://data/bonds/bond_war_loan.tres"),
			load("res://data/bonds/bond_victory.tres"),
			load("res://data/bonds/bond_lend_lease.tres"),
		]

	# Wire WaveDirector to our enemy registry & path.
	wave_director.enemy_scene = enemy_scene
	wave_director.enemy_registry = enemy_set
	wave_director.wave_ended.connect(_on_wave_ended)
	wave_director.all_waves_completed.connect(_on_all_waves_completed)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.tower_placed.connect(_on_tower_placed_for_synergy)
	EventBus.tower_sold.connect(_on_tower_sold_for_synergy)

	# Bake path points once for placement validation.
	if path and path.curve:
		_path_baked_points = path.curve.get_baked_points()

	# Hide legacy placement slots; free placement replaces the slot system.
	if slots_container:
		slots_container.visible = false

	# Free placement input requires Map to receive input even when paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	EventBus.tower_palette_pick.connect(_select_tower_index)
	EventBus.start_wave_requested.connect(_on_start_wave_requested)
	EventBus.map_ready.emit(available_towers)

	# Wave 1 no longer auto-starts; HUD's Start Wave button drives it.

func _input(event: InputEvent) -> void:
	# Hotkey selection (1-9 picks from palette)
	if event is InputEventKey and event.pressed and not event.echo:
		var idx := -1
		match event.keycode:
			KEY_1: idx = 0
			KEY_2: idx = 1
			KEY_3: idx = 2
			KEY_4: idx = 3
			KEY_5: idx = 4
			KEY_6: idx = 5
			KEY_7: idx = 6
			KEY_8: idx = 7
			KEY_9: idx = 8
			KEY_ESCAPE:
				_exit_placement_mode()
				return
		if idx >= 0 and idx < available_towers.size():
			_select_tower_index(idx)
			return

	# Placement input — only meaningful when in placement mode.
	if not _placement_active or _placement_ghost == null:
		return
	if event is InputEventMouseMotion:
		_placement_ghost.global_position = get_global_mouse_position()
		_placement_ghost.set_valid(_is_valid_placement(_placement_ghost.global_position))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_exit_placement_mode()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var pos := get_global_mouse_position()
			if _is_valid_placement(pos) and selected_tower_stats and GameState.gold >= selected_tower_stats.cost:
				_place_tower_at(pos, selected_tower_stats)
				get_viewport().set_input_as_handled()

func _select_tower_index(idx: int) -> void:
	if idx < 0 or idx >= available_towers.size():
		return
	selected_tower_stats = available_towers[idx]
	EventBus.tower_selection_changed.emit(selected_tower_stats)
	_enter_placement_mode(selected_tower_stats)

func _enter_placement_mode(stats: Resource) -> void:
	_exit_placement_mode()
	if stats == null:
		return
	_placement_active = true
	_placement_ghost = _GHOST_SCENE.instantiate()
	_placement_ghost.set_stats(stats)
	_placement_ghost.global_position = get_global_mouse_position()
	_placement_ghost.set_valid(_is_valid_placement(_placement_ghost.global_position))
	add_child(_placement_ghost)

func _exit_placement_mode() -> void:
	_placement_active = false
	if _placement_ghost and is_instance_valid(_placement_ghost):
		_placement_ghost.queue_free()
	_placement_ghost = null

func _place_tower_at(pos: Vector2, stats: Resource) -> void:
	if not GameState.spend_gold(stats.cost):
		return
	var tower = tower_scene.instantiate()
	tower.stats = stats
	tower.global_position = pos
	towers_container.add_child(tower)
	EventBus.tower_placed.emit(tower)
	# Refresh ghost validity at the new spot (tower-too-close check now applies).
	if _placement_ghost and is_instance_valid(_placement_ghost):
		_placement_ghost.set_valid(_is_valid_placement(_placement_ghost.global_position))

func _is_valid_placement(pos: Vector2) -> bool:
	if pos.x < _MAP_MARGIN or pos.x > 1280.0 - _MAP_MARGIN:
		return false
	if pos.y < _MAP_MARGIN or pos.y > 720.0 - _MAP_MARGIN:
		return false
	if _distance_to_path(pos) < _PATH_CLEARANCE:
		return false
	for tw in get_tree().get_nodes_in_group("towers"):
		if not is_instance_valid(tw):
			continue
		if pos.distance_to(tw.global_position) < _TOWER_CLEARANCE:
			return false
	return true

func _distance_to_path(pos: Vector2) -> float:
	if _path_baked_points.is_empty():
		return 9999.0
	var min_d: float = 9999.0
	for p in _path_baked_points:
		var d: float = pos.distance_to(p)
		if d < min_d:
			min_d = d
	return min_d

func _on_start_wave_requested() -> void:
	if not GameState.run_active:
		return
	if wave_director.has_more_waves():
		wave_director.start_next_wave()

func _on_wave_ended(idx: int) -> void:
	if not GameState.run_active:
		return
	if not wave_director.has_more_waves():
		return  # all_waves_completed signal fires elsewhere
	if idx == 0:
		# Wave 1 just ended; no shop yet. HUD's Start Wave button drives advance.
		return
	# Shop phase for waves 2+: open the war room and wait for player.
	EventBus.shop_opened.emit(available_bonds)
	await EventBus.shop_closed
	# After shop closes, control returns; HUD's Start Wave button starts next.

func _on_all_waves_completed() -> void:
	if GameState.run_active:
		GameState.run_active = false
		EventBus.run_ended.emit(true)

func _on_run_ended(victory: bool) -> void:
	var waves_cleared := GameState.wave_index + (1 if victory else 0)
	var earned := waves_cleared
	var total := wave_director.wave_count() if wave_director else 9
	MetaProgress.award_war_effort(earned)
	if hud and hud.has_method("show_end_screen"):
		hud.show_end_screen(victory, waves_cleared, earned, total)

func _on_tower_placed_for_synergy(tower: Node) -> void:
	AdjacencySystem.recompute_in_radius(tower)
	AuraSystem.recompute_in_radius(tower)

func _on_tower_sold_for_synergy(tower: Node, _refund: int) -> void:
	if tower and is_instance_valid(tower):
		var aura_r: float = tower.stats.aura_radius if tower.stats else 0.0
		AdjacencySystem.recompute_after_removal(tower.global_position, tower.get_tree())
		AuraSystem.recompute_after_removal(tower.global_position, aura_r, tower.get_tree())
