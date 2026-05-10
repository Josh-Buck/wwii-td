class_name Map extends Node2D

## Base class for all map scenes. Subclassed maps (m0_field, ardennes, etc.)
## set their own path curve, slot positions, and enemy/tower registries.

@export var available_towers: Array[Resource] = []  ## TowerStats list
@export var enemy_set: Dictionary = {}  ## StringName -> EnemyStats
@export var tower_scene: PackedScene
@export var enemy_scene: PackedScene

@onready var path: Path2D = $Path
@onready var slots_container: Node2D = $PlacementSlots
@onready var towers_container: Node2D = $Towers
@onready var enemies_container: Node2D = $Enemies
@onready var wave_director: WaveDirector = $WaveDirector
@onready var hud: CanvasLayer = $HUD

var slots: Array = []
var selected_tower_stats: TowerStats = null

func _ready() -> void:
	# Wire WaveDirector to our enemy registry & path.
	wave_director.enemy_scene = enemy_scene
	wave_director.enemy_registry = enemy_set
	wave_director.wave_ended.connect(_on_wave_ended)
	wave_director.all_waves_completed.connect(_on_all_waves_completed)
	EventBus.run_ended.connect(_on_run_ended)

	# Default M0: auto-select the first tower.
	if available_towers.size() > 0:
		selected_tower_stats = available_towers[0]

	# Hook up slots.
	for slot in slots_container.get_children():
		if slot is PlacementSlot:
			slots.append(slot)
			slot.slot_clicked.connect(_on_slot_clicked)

	# Auto-start first wave after a short lead-in.
	await get_tree().create_timer(2.0).timeout
	if GameState.run_active:
		wave_director.start_next_wave()

func _on_slot_clicked(slot) -> void:
	if selected_tower_stats == null:
		return
	if slot.occupied():
		return
	if not GameState.spend_gold(selected_tower_stats.cost):
		return
	var tower = tower_scene.instantiate()
	tower.stats = selected_tower_stats
	tower.global_position = slot.global_position
	towers_container.add_child(tower)
	slot.set_tower(tower)
	EventBus.tower_placed.emit(tower)

func _on_wave_ended(_idx: int) -> void:
	# M0: chain into the next wave automatically with a 3s breather.
	await get_tree().create_timer(3.0).timeout
	if not GameState.run_active:
		return
	if wave_director.has_more_waves():
		wave_director.start_next_wave()
	# else: all_waves_completed signal fires when the last wave's enemies
	# are fully cleared (handled separately).

func _on_all_waves_completed() -> void:
	if GameState.run_active:
		GameState.run_active = false
		EventBus.run_ended.emit(true)

func _on_run_ended(victory: bool) -> void:
	if hud and hud.has_method("show_end_screen"):
		hud.show_end_screen(victory)
