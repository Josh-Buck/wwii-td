extends Node

# user:// → IndexedDB on web export. Persists across browser sessions
# on the same origin. Save eagerly; web tabs can close before async
# IDB writes flush.

const META_PATH := "user://meta.save"
const RUN_PATH := "user://run.save"

var _save_queued := false

func _ready() -> void:
	load_or_default()

func save_async() -> void:
	if _save_queued:
		return
	_save_queued = true
	call_deferred("_save_now")

func _save_now() -> void:
	_save_queued = false
	var f := FileAccess.open(META_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot open %s for write (err=%d)" % [META_PATH, FileAccess.get_open_error()])
		return
	f.store_var(MetaProgress.to_dict())

func load_or_default() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f == null:
		push_error("SaveSystem: cannot open %s for read" % META_PATH)
		return
	var data = f.get_var()
	if data is Dictionary:
		MetaProgress.from_dict(data)

# ---------- Mid-run save ----------

func save_run(state: Dictionary) -> void:
	var f := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot open %s for write" % RUN_PATH)
		return
	f.store_var(state)

func load_run() -> Dictionary:
	if not FileAccess.file_exists(RUN_PATH):
		return {}
	var f := FileAccess.open(RUN_PATH, FileAccess.READ)
	if f == null:
		return {}
	var data = f.get_var()
	if data is Dictionary:
		return data
	return {}

func has_run_save() -> bool:
	return FileAccess.file_exists(RUN_PATH)

func clear_run_save() -> void:
	if FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_PATH))
