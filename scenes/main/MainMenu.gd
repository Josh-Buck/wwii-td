extends Control

signal start_run_requested(map_path: String)

const _MAP_NORMANDY := "res://scenes/map/maps/m0_field.tscn"
const _MAP_ARDENNES := "res://scenes/map/maps/ardennes.tscn"

@onready var wep_label: Label = $Center/Panel/VBox/WepLabel
@onready var map_label: Label = $Center/Panel/VBox/MapLabel
@onready var map_normandy_btn: Button = $Center/Panel/VBox/MapRow/NormandyButton
@onready var map_ardennes_btn: Button = $Center/Panel/VBox/MapRow/ArdennesButton
@onready var start_btn: Button = $Center/Panel/VBox/StartButton
@onready var recruit_btn: Button = $Center/Panel/VBox/RecruitButton
@onready var codex_btn: Button = $Center/Panel/VBox/CodexButton

var _selected_map: String = _MAP_NORMANDY
@onready var recruit_overlay: Control = $RecruitOverlay
@onready var recruit_wep: Label = $RecruitOverlay/Panel/VBox/WepLabel
@onready var recruit_list: VBoxContainer = $RecruitOverlay/Panel/VBox/Scroll/RosterList
@onready var recruit_close: Button = $RecruitOverlay/Panel/VBox/CloseButton

const _STARTING_ROSTER: Array[String] = [
	"res://data/towers/patton.tres",
	"res://data/towers/eisenhower.tres",
	"res://data/towers/churchill.tres",
	"res://data/towers/anne_frank.tres",
]
const _RECRUIT_ROSTER: Array[String] = [
	"res://data/towers/montgomery.tres",
	"res://data/towers/audie_murphy.tres",
	"res://data/towers/rosie.tres",
	"res://data/towers/airborne_101.tres",
	"res://data/towers/tuskegee.tres",
	"res://data/towers/spitfire.tres",
	"res://data/towers/fdr.tres",
	"res://data/towers/bletchley.tres",
	"res://data/towers/zhukov.tres",
	"res://data/towers/lemay.tres",
	"res://data/towers/mustang.tres",
	"res://data/towers/pavlichenko.tres",
	"res://data/towers/b17.tres",
]

func _ready() -> void:
	recruit_overlay.visible = false
	start_btn.pressed.connect(_on_start_pressed)
	recruit_btn.pressed.connect(_open_recruit)
	codex_btn.pressed.connect(_on_codex_pressed)
	recruit_close.pressed.connect(_close_recruit)
	map_normandy_btn.pressed.connect(_select_map.bind(_MAP_NORMANDY))
	map_ardennes_btn.pressed.connect(_select_map.bind(_MAP_ARDENNES))
	_refresh_map_buttons()
	_refresh_top()

func _select_map(path: String) -> void:
	_selected_map = path
	_refresh_map_buttons()

func _refresh_map_buttons() -> void:
	map_normandy_btn.disabled = _selected_map == _MAP_NORMANDY
	map_ardennes_btn.disabled = _selected_map == _MAP_ARDENNES
	if _selected_map == _MAP_NORMANDY:
		map_label.text = "Map: Normandy Field"
	else:
		map_label.text = "Map: Ardennes (winding forest path)"

func _refresh_top() -> void:
	wep_label.text = "War Effort: %d" % MetaProgress.war_effort_points

func _on_start_pressed() -> void:
	start_run_requested.emit(_selected_map)

func _on_codex_pressed() -> void:
	# Codex lives inside the HUD during a run. Tell the player how to access it.
	# (Standalone codex view is a follow-up.)
	codex_btn.text = "Codex opens during a run (press C)"

func _open_recruit() -> void:
	recruit_overlay.visible = true
	_refresh_recruit()

func _close_recruit() -> void:
	recruit_overlay.visible = false
	_refresh_top()

func _refresh_recruit() -> void:
	recruit_wep.text = "War Effort: %d" % MetaProgress.war_effort_points
	for c in recruit_list.get_children():
		c.queue_free()
	for path in _STARTING_ROSTER:
		var s: Resource = load(path)
		if s:
			recruit_list.add_child(_build_row(s))
	for path in _RECRUIT_ROSTER:
		var s: Resource = load(path)
		if s:
			recruit_list.add_child(_build_row(s))

func _build_row(stats: Resource) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)
	if stats.portrait != null:
		var tex := TextureRect.new()
		tex.texture = stats.portrait
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.custom_minimum_size = Vector2(56, 56)
		hbox.add_child(tex)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = stats.display_name
	name_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(name_lbl)
	var unlocked := MetaProgress.is_unlocked(stats.id)
	var rank := MetaProgress.rank_of(stats.id)
	var status_lbl := Label.new()
	if unlocked:
		var s: String = "Rank %d / %d" % [rank, MetaProgress.MAX_RANK]
		if rank > 0:
			s += "  ·  +%d%% dmg  ·  +%d%% rate" % [
				int(MetaProgress.DAMAGE_PER_RANK * rank * 100),
				int(MetaProgress.FIRE_RATE_PER_RANK * rank * 100),
			]
		status_lbl.text = s
		status_lbl.modulate = Color(0.8, 1.0, 0.8, 1.0)
	else:
		status_lbl.text = "Locked"
		status_lbl.modulate = Color(1.0, 0.6, 0.6, 1.0)
	status_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(status_lbl)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 48)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not unlocked:
		var cost: int = int(MetaProgress.RECRUIT_COSTS.get(stats.id, 0))
		btn.text = "Recruit  (%d WEP)" % cost
		btn.disabled = MetaProgress.war_effort_points < cost
		btn.pressed.connect(_on_recruit.bind(stats.id))
	elif rank >= MetaProgress.MAX_RANK:
		btn.text = "Max Rank"
		btn.disabled = true
	else:
		var cost: int = MetaProgress.next_promote_cost(stats.id)
		btn.text = "Promote to Rank %d  (%d WEP)" % [rank + 1, cost]
		btn.disabled = MetaProgress.war_effort_points < cost
		btn.pressed.connect(_on_promote.bind(stats.id))
	hbox.add_child(btn)
	return panel

func _on_recruit(figure_id: StringName) -> void:
	if MetaProgress.recruit_figure(figure_id):
		_refresh_recruit()

func _on_promote(figure_id: StringName) -> void:
	if MetaProgress.promote_figure(figure_id):
		_refresh_recruit()
