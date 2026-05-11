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

func _on_start_run(map_path: String = M0_MAP) -> void:
	GameState.reset_run()
	_load_map(map_path)

func _load_map(path: String) -> void:
	_clear_container()
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Main: failed to load %s" % path)
		return
	map_container.add_child(packed.instantiate())

func _clear_container() -> void:
	for c in map_container.get_children():
		c.queue_free()

func _on_run_ended(_victory: bool) -> void:
	pass  # HUD shows the end screen; restart reloads scene, returning to menu.
