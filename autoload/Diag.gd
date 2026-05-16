extends Node

# Lightweight in-game log overlay so the player can see diagnostics
# without opening DevTools. Toggled with F1.
# Call Diag.log("message") from anywhere; recent lines render bottom-left.

const MAX_LINES: int = 25

var visible: bool = false
var _lines: PackedStringArray = PackedStringArray()
var _overlay: CanvasLayer = null
var _label: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = CanvasLayer.new()
	_overlay.layer = 128
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)
	var panel := PanelContainer.new()
	panel.anchor_left = 0
	panel.anchor_top = 1
	panel.anchor_right = 0
	panel.anchor_bottom = 1
	panel.offset_left = 12
	panel.offset_top = -360
	panel.offset_right = 720
	panel.offset_bottom = -16
	panel.modulate = Color(1, 1, 1, 0.92)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(panel)
	_label = Label.new()
	_label.text = ""
	_label.add_theme_font_size_override("font_size", 11)
	_label.modulate = Color(0.85, 1.0, 0.85, 1)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_label)
	_overlay.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		toggle()

func toggle() -> void:
	visible = not visible
	_overlay.visible = visible

func log(msg: String) -> void:
	var ts: String = "%6.1fs" % (Time.get_ticks_msec() / 1000.0)
	_lines.append("%s  %s" % [ts, msg])
	while _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	if _label:
		_label.text = "\n".join(_lines)

func clear() -> void:
	_lines.clear()
	if _label:
		_label.text = ""
