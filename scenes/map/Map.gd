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
const _MAP_LEFT: float = 32.0
const _MAP_TOP: float = 56.0         ## below TopBar
const _MAP_RIGHT: float = 1052.0     ## left of the TowerSidebar (starts at 1064)
const _MAP_BOTTOM: float = 680.0     ## above HintLabel

var _placement_ghost: Node = null
var _placement_active: bool = false
var _path_baked_points: PackedVector2Array
var _bombing_run: BombingRun = null
var _camera: Camera2D = null
var _shake_remaining: float = 0.0
var _shake_intensity: float = 0.0
var _shake_rng := RandomNumberGenerator.new()

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
			load("res://data/towers/maginot_bunker.tres"),
			load("res://data/towers/patton.tres"),
			load("res://data/towers/eisenhower.tres"),
			load("res://data/towers/churchill.tres"),
			load("res://data/towers/anne_frank.tres"),
			load("res://data/towers/montgomery.tres"),
			load("res://data/towers/pavlichenko.tres"),
			load("res://data/towers/fdr.tres"),
			load("res://data/towers/bletchley.tres"),
			load("res://data/towers/airborne_101.tres"),
			load("res://data/towers/audie_murphy.tres"),
			load("res://data/towers/zhukov.tres"),
			load("res://data/towers/rosie.tres"),
			load("res://data/towers/lemay.tres"),
			load("res://data/towers/tuskegee.tres"),
			load("res://data/towers/spitfire.tres"),
			load("res://data/towers/mustang.tres"),
			load("res://data/towers/b17.tres"),
		]
	available_towers = _filter_unlocked(available_towers)
	if enemy_set.is_empty():
		enemy_set = {
			&"wehrmacht_infantry": load("res://data/enemies/wehrmacht_infantry.tres"),
			&"panzer_iii": load("res://data/enemies/panzer_iii.tres"),
			&"stuka": load("res://data/enemies/stuka.tres"),
			&"rommel": load("res://data/enemies/rommel.tres"),
			&"eichmann": load("res://data/enemies/eichmann.tres"),
			&"heydrich": load("res://data/enemies/heydrich.tres"),
			&"mengele": load("res://data/enemies/mengele.tres"),
			&"himmler": load("res://data/enemies/himmler.tres"),
			&"tojo": load("res://data/enemies/tojo.tres"),
			&"hitler": load("res://data/enemies/hitler.tres"),
			&"v2_rocket": load("res://data/enemies/v2_rocket.tres"),
			&"kamikaze": load("res://data/enemies/kamikaze.tres"),
			&"tiger_i": load("res://data/enemies/tiger_i.tres"),
			&"waffen_ss": load("res://data/enemies/waffen_ss.tres"),
			&"banzai": load("res://data/enemies/banzai.tres"),
			&"bersaglieri": load("res://data/enemies/bersaglieri.tres"),
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

	_bombing_run = BombingRun.new()
	add_child(_bombing_run)

	_camera = Camera2D.new()
	_camera.process_mode = Node.PROCESS_MODE_ALWAYS
	_camera.position = Vector2(640, 360)
	add_child(_camera)
	_camera.make_current()
	_shake_rng.randomize()
	EventBus.screen_shake.connect(_on_shake_requested)

	EventBus.tower_palette_pick.connect(_select_tower_index)
	EventBus.start_wave_requested.connect(_on_start_wave_requested)
	EventBus.map_ready.emit(available_towers)

	# Wave 1 no longer auto-starts; HUD's Start Wave button drives it.

func _input(event: InputEvent) -> void:
	# Hotkey selection (1-9 picks from palette, B toggles bombing run targeting)
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
			KEY_B:
				if _bombing_run:
					_bombing_run.toggle_targeting()
				return
			KEY_ESCAPE:
				_exit_placement_mode()
				if _bombing_run:
					_bombing_run.cancel_targeting()
				return
		if idx >= 0 and idx < available_towers.size():
			_select_tower_index(idx)
			return

	# Bombing run targeting click consumes the next left-click on the map.
	if _bombing_run and _bombing_run.is_targeting() and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos := get_global_mouse_position()
		if pos.x >= _MAP_LEFT and pos.x <= _MAP_RIGHT and pos.y >= _MAP_TOP and pos.y <= _MAP_BOTTOM:
			_bombing_run.fire_at(pos)
			get_viewport().set_input_as_handled()
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
			# Clicking on a placed tower during placement mode → exit
			# placement and let the tower's HoverArea open the info panel.
			var clicked_tower := _tower_at(pos)
			if clicked_tower:
				_exit_placement_mode()
				return  # don't consume; Tower's HoverArea handles the click
			if _is_valid_placement(pos) and selected_tower_stats:
				var has_gold: bool = GameState.gold >= selected_tower_stats.cost
				var is_free: bool = GameState.free_tower_pending == selected_tower_stats.id
				if has_gold or is_free:
					_place_tower_at(pos, selected_tower_stats)
					get_viewport().set_input_as_handled()

func _filter_unlocked(towers: Array) -> Array:
	var out: Array = []
	for t in towers:
		if t == null:
			continue
		if MetaProgress.is_unlocked(t.id):
			out.append(t)
	return out

func _on_shake_requested(intensity: float, duration: float) -> void:
	_shake_intensity = max(_shake_intensity, intensity)
	_shake_remaining = max(_shake_remaining, duration)

func _process(delta: float) -> void:
	if _camera == null:
		return
	if _shake_remaining > 0.0:
		_shake_remaining = max(0.0, _shake_remaining - delta)
		var t: float = _shake_remaining / max(0.001, _shake_remaining + delta)  ## decay scalar
		var falloff: float = _shake_remaining / 0.4 if _shake_remaining < 0.4 else 1.0
		_camera.offset = Vector2(
			_shake_rng.randf_range(-1.0, 1.0),
			_shake_rng.randf_range(-1.0, 1.0),
		) * _shake_intensity * falloff
		if _shake_remaining <= 0.0:
			_camera.offset = Vector2.ZERO
			_shake_intensity = 0.0
	else:
		_camera.offset = Vector2.ZERO

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
	# Free placement from the roguelike shop ("Volunteer" offer) bypasses cost.
	var free: bool = GameState.free_tower_pending == stats.id
	if free:
		GameState.free_tower_pending = &""
	elif not GameState.spend_gold(stats.cost):
		return
	var tower = tower_scene.instantiate()
	tower.stats = stats
	tower.global_position = pos
	towers_container.add_child(tower)
	EventBus.tower_placed.emit(tower)
	if _placement_ghost and is_instance_valid(_placement_ghost):
		_placement_ghost.set_valid(_is_valid_placement(_placement_ghost.global_position))

func _is_valid_placement(pos: Vector2) -> bool:
	if pos.x < _MAP_LEFT or pos.x > _MAP_RIGHT:
		return false
	if pos.y < _MAP_TOP or pos.y > _MAP_BOTTOM:
		return false
	# Air units patrol overhead — they ignore path clearance and only clash
	# with other air units.
	var is_air: bool = selected_tower_stats != null and selected_tower_stats.is_air_unit
	if not is_air and _distance_to_path(pos) < _PATH_CLEARANCE:
		return false
	for tw in get_tree().get_nodes_in_group("towers"):
		if not is_instance_valid(tw) or tw.stats == null:
			continue
		# Ground vs air use separate spatial layers.
		if tw.stats.is_air_unit != is_air:
			continue
		if pos.distance_to(tw.global_position) < _TOWER_CLEARANCE:
			return false
	return true

func _tower_at(pos: Vector2) -> Node:
	for tw in get_tree().get_nodes_in_group("towers"):
		if not is_instance_valid(tw):
			continue
		if pos.distance_to(tw.global_position) < 30.0:
			return tw
	return null

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
	# 2 WEP per wave + 10 victory bonus + 1 per kill / 25 so a real run earns
	# enough to recruit a figure (5-18 WEP) without grinding 4 runs each time.
	var earned := waves_cleared * 2 + (10 if victory else 0) + (GameState.stat_kills / 25)
	if GameState.manhattan_penalty:
		earned = int(earned * 0.5)
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
