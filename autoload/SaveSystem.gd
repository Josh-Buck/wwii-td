extends Node

# user:// → IndexedDB on web export. Persists across browser sessions
# on the same origin. Save eagerly; web tabs can close before async
# IDB writes flush.

const PATH := "user://meta.save"

var _save_queued := false

func _ready() -> void:
	load_or_default()

func save_async() -> void:
	# Coalesce multiple save calls in the same frame.
	if _save_queued:
		return
	_save_queued = true
	call_deferred("_save_now")

func _save_now() -> void:
	_save_queued = false
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot open %s for write (err=%d)" % [PATH, FileAccess.get_open_error()])
		return
	f.store_var(MetaProgress.to_dict())

func load_or_default() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_error("SaveSystem: cannot open %s for read" % PATH)
		return
	var data = f.get_var()
	if data is Dictionary:
		MetaProgress.from_dict(data)
