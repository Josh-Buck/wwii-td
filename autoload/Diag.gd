extends Node

# Two responsibilities:
#  1. F2 screenshot — captures the current viewport. On desktop the PNG
#     lands on disk; on web the browser is told to download it.
#  2. Internal log buffer that other code can append to with Diag.log().
#     There is NO on-screen overlay. The buffer is kept in memory and can
#     be flushed via Diag.dump_log_to(path) if we ever need it.

const LOG_MAX_LINES: int = 60
const SCREENSHOT_DESKTOP_TMP: String = "/tmp/wwii-td-screen.png"
const SCREENSHOT_USER_DIR: String = "user://screenshots"

var _lines: PackedStringArray = PackedStringArray()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		take_screenshot()

func log(msg: String) -> void:
	var ts: String = "%6.1fs" % (Time.get_ticks_msec() / 1000.0)
	_lines.append("%s  %s" % [ts, msg])
	while _lines.size() > LOG_MAX_LINES:
		_lines.remove_at(0)

func take_screenshot() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var img: Image = vp.get_texture().get_image()
	if img == null:
		return
	var buf: PackedByteArray = img.save_png_to_buffer()
	if buf.is_empty():
		return
	# File name uses the run-time clock so multiple captures don't collide.
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-")
	var fname: String = "wwii-td-%s.png" % stamp
	# 1. Web: trigger a browser download via JavaScriptBridge.
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var jsb = Engine.get_singleton("JavaScriptBridge")
		if jsb and jsb.has_method("download_buffer"):
			jsb.download_buffer(buf, fname, "image/png")
	# 2. Desktop: save to a stable /tmp/ path AND a timestamped path under user://.
	if OS.has_feature("linux") or OS.has_feature("macos") or OS.has_feature("windows"):
		var f := FileAccess.open(SCREENSHOT_DESKTOP_TMP, FileAccess.WRITE)
		if f:
			f.store_buffer(buf)
			f = null
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCREENSHOT_USER_DIR))
		var user_path: String = "%s/%s" % [SCREENSHOT_USER_DIR, fname]
		var uf := FileAccess.open(user_path, FileAccess.WRITE)
		if uf:
			uf.store_buffer(buf)
			uf = null
	# Audio shutter feedback + toast via EventBus.
	AudioMan.play(&"click", 0.0)
	EventBus.screenshot_taken.emit(fname)

func dump_log_to(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		for line in _lines:
			f.store_line(line)
