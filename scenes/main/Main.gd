extends Node

## Top-level scene. M0 boots straight into the M0 map; later milestones
## will sit MainMenu in front of map loading.

const M0_MAP := "res://scenes/map/maps/m0_field.tscn"

@onready var map_container: Node = $MapContainer

func _ready() -> void:
	GameState.reset_run()
	_load_map(M0_MAP)
	EventBus.run_ended.connect(_on_run_ended)

func _load_map(path: String) -> void:
	for c in map_container.get_children():
		c.queue_free()
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Main: failed to load %s" % path)
		return
	map_container.add_child(packed.instantiate())

func _on_run_ended(_victory: bool) -> void:
	pass  # HUD shows the end screen; M1+ will offer Restart / Main Menu here.
