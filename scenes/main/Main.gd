extends Node

const M0_MAP := "res://scenes/map/maps/m0_field.tscn"
const ARDENNES_MAP := "res://scenes/map/maps/ardennes.tscn"
const MAIN_MENU := "res://scenes/main/MainMenu.tscn"

@onready var map_container: Node = $MapContainer

func _ready() -> void:
	_show_main_menu()
	EventBus.run_ended.connect(_on_run_ended)

func _show_main_menu() -> void:
	_clear_container()
	var menu: Control = (load(MAIN_MENU) as PackedScene).instantiate()
	map_container.add_child(menu)
	menu.start_run_requested.connect(_on_start_run)
	if menu.has_signal("continue_run_requested"):
		menu.continue_run_requested.connect(_on_continue_run)

func _on_start_run(map_path: String = M0_MAP) -> void:
	GameState.reset_run()
	SaveSystem.clear_run_save()  ## starting fresh; drop any stale mid-run save
	_load_map(map_path)

func _on_continue_run() -> void:
	var state: Dictionary = SaveSystem.load_run()
	if state.is_empty():
		# Nothing to continue; fall back to fresh run on Normandy.
		_on_start_run()
		return
	var map_id: String = state.get("map_id", "M0Field")
	var path: String = ARDENNES_MAP if map_id == "Ardennes" else M0_MAP
	GameState.reset_run()
	GameState.difficulty = int(state.get("difficulty", GameState.Difficulty.NORMAL))
	_load_map(path, state)

func _load_map(path: String, run_state: Dictionary = {}) -> void:
	_clear_container()
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Main: failed to load %s" % path)
		return
	var map_node = packed.instantiate()
	if not run_state.is_empty():
		map_node._pending_run_state = run_state
	map_container.add_child(map_node)

func _clear_container() -> void:
	for c in map_container.get_children():
		c.queue_free()

func _on_run_ended(_victory: bool) -> void:
	pass  # HUD shows the end screen; restart reloads scene, returning to menu.
