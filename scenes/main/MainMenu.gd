extends Control

signal start_run_requested(map_path: String)

const _MAP_NORMANDY := "res://scenes/map/maps/m0_field.tscn"
const _MAP_ARDENNES := "res://scenes/map/maps/ardennes.tscn"

@onready var wep_label: Label = $Center/Panel/VBox/WepLabel
@onready var stats_label: Label = $Center/Panel/VBox/StatsLabel
@onready var ach_label: Label = $Center/Panel/VBox/AchLabel
@onready var map_label: Label = $Center/Panel/VBox/MapLabel
@onready var map_normandy_btn: Button = $Center/Panel/VBox/MapRow/NormandyButton
@onready var map_ardennes_btn: Button = $Center/Panel/VBox/MapRow/ArdennesButton
@onready var diff_label: Label = $Center/Panel/VBox/DiffLabel
@onready var diff_easy_btn: Button = $Center/Panel/VBox/DiffRow/EasyButton
@onready var diff_normal_btn: Button = $Center/Panel/VBox/DiffRow/NormalButton
@onready var diff_hard_btn: Button = $Center/Panel/VBox/DiffRow/HardButton
@onready var start_btn: Button = $Center/Panel/VBox/StartButton
@onready var recruit_btn: Button = $Center/Panel/VBox/RecruitButton
@onready var codex_btn: Button = $Center/Panel/VBox/CodexButton
@onready var build_label: Label = $Center/Panel/VBox/BuildLabel
@onready var ach_btn: Button = $Center/Panel/VBox/AchievementsButton
@onready var ach_overlay: Control = $AchOverlay
@onready var ach_progress: Label = $AchOverlay/Panel/VBox/Progress
@onready var ach_list: VBoxContainer = $AchOverlay/Panel/VBox/Scroll/List
@onready var ach_close: Button = $AchOverlay/Panel/VBox/CloseButton

var _selected_map: String = _MAP_NORMANDY
@onready var recruit_overlay: Control = $RecruitOverlay
@onready var recruit_wep: Label = $RecruitOverlay/Panel/VBox/WepLabel
@onready var recruit_list: VBoxContainer = $RecruitOverlay/Panel/VBox/Scroll/RosterList
@onready var recruit_close: Button = $RecruitOverlay/Panel/VBox/CloseButton
@onready var codex_overlay: Control = $CodexOverlay
@onready var codex_progress: Label = $CodexOverlay/Panel/VBox/Progress
@onready var codex_list: VBoxContainer = $CodexOverlay/Panel/VBox/HSplit/ListScroll/EntryList
@onready var codex_portrait: TextureRect = $CodexOverlay/Panel/VBox/HSplit/ContentScroll/ContentVBox/EntryPortrait
@onready var codex_title: Label = $CodexOverlay/Panel/VBox/HSplit/ContentScroll/ContentVBox/EntryTitle
@onready var codex_body: Label = $CodexOverlay/Panel/VBox/HSplit/ContentScroll/ContentVBox/EntryBody
@onready var codex_sources: Label = $CodexOverlay/Panel/VBox/HSplit/ContentScroll/ContentVBox/EntrySources
@onready var codex_close_btn: Button = $CodexOverlay/Panel/VBox/CodexCloseButton

const _CODEX_PATHS: Array[String] = [
	"res://data/codex/patton.tres", "res://data/codex/eisenhower.tres",
	"res://data/codex/churchill.tres", "res://data/codex/anne_frank.tres",
	"res://data/codex/montgomery.tres", "res://data/codex/pavlichenko.tres",
	"res://data/codex/fdr.tres", "res://data/codex/bletchley.tres",
	"res://data/codex/airborne_101.tres", "res://data/codex/audie_murphy.tres",
	"res://data/codex/zhukov.tres", "res://data/codex/rosie.tres",
	"res://data/codex/lemay.tres", "res://data/codex/tuskegee.tres",
	"res://data/codex/spitfire.tres", "res://data/codex/mustang.tres",
	"res://data/codex/b17.tres", "res://data/codex/maginot_bunker.tres",
	"res://data/codex/wehrmacht_infantry.tres", "res://data/codex/panzer_iii.tres",
	"res://data/codex/stuka.tres", "res://data/codex/waffen_ss.tres",
	"res://data/codex/tiger_i.tres", "res://data/codex/banzai.tres",
	"res://data/codex/bersaglieri.tres", "res://data/codex/v2_rocket.tres",
	"res://data/codex/kamikaze.tres",
	"res://data/codex/rommel.tres", "res://data/codex/eichmann.tres",
	"res://data/codex/heydrich.tres", "res://data/codex/mengele.tres",
	"res://data/codex/himmler.tres", "res://data/codex/tojo.tres",
	"res://data/codex/hitler.tres",
	"res://data/codex/oppenheimer.tres", "res://data/codex/trinity.tres",
	"res://data/codex/hiroshima.tres", "res://data/codex/nagasaki.tres",
]

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
	codex_overlay.visible = false
	start_btn.pressed.connect(_on_start_pressed)
	recruit_btn.pressed.connect(_open_recruit)
	codex_btn.pressed.connect(_on_codex_pressed)
	codex_close_btn.pressed.connect(_close_codex)
	ach_overlay.visible = false
	ach_btn.pressed.connect(_open_ach)
	ach_close.pressed.connect(_close_ach)
	recruit_close.pressed.connect(_close_recruit)
	map_normandy_btn.pressed.connect(_select_map.bind(_MAP_NORMANDY))
	map_ardennes_btn.pressed.connect(_select_map.bind(_MAP_ARDENNES))
	diff_easy_btn.pressed.connect(_select_difficulty.bind(GameState.Difficulty.EASY))
	diff_normal_btn.pressed.connect(_select_difficulty.bind(GameState.Difficulty.NORMAL))
	diff_hard_btn.pressed.connect(_select_difficulty.bind(GameState.Difficulty.HARD))
	_refresh_map_buttons()
	_refresh_difficulty_buttons()
	_refresh_top()
	_refresh_build_label()

func _refresh_build_label() -> void:
	# data/build.txt is written by the deploy workflow with one short SHA
	# per line + a timestamp. Lets us tell whether the browser is loading
	# the latest deploy. Missing in local-editor runs.
	var path: String = "res://data/build.txt"
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f:
			var sha: String = f.get_line().strip_edges()
			var when: String = f.get_line().strip_edges()
			build_label.text = "build: %s  ·  %s" % [sha, when]
			return
	build_label.text = "build: dev (local)"

func _select_difficulty(d: int) -> void:
	GameState.difficulty = d
	_refresh_difficulty_buttons()

func _refresh_difficulty_buttons() -> void:
	# Stars are difficulty-specific, so refresh map labels too.
	if has_node("Center/Panel/VBox/MapRow/NormandyButton"):
		_refresh_map_buttons()
	diff_easy_btn.disabled = GameState.difficulty == GameState.Difficulty.EASY
	diff_normal_btn.disabled = GameState.difficulty == GameState.Difficulty.NORMAL
	diff_hard_btn.disabled = GameState.difficulty == GameState.Difficulty.HARD
	var hp: float = GameState.DIFFICULTY_HP_MULT[GameState.difficulty]
	var wep: float = GameState.DIFFICULTY_WEP_MULT[GameState.difficulty]
	var lives_b: int = GameState.DIFFICULTY_LIVES_BONUS[GameState.difficulty]
	var gold_b: int = GameState.DIFFICULTY_GOLD_BONUS[GameState.difficulty]
	diff_label.text = "Difficulty: %s — enemy HP x%.2f · WEP x%.2f · lives %+d · gold %+d" % [
		GameState.DIFFICULTY_LABELS[GameState.difficulty], hp, wep, lives_b, gold_b
	]

func _select_map(path: String) -> void:
	_selected_map = path
	_refresh_map_buttons()

func _refresh_map_buttons() -> void:
	map_normandy_btn.disabled = _selected_map == _MAP_NORMANDY
	map_ardennes_btn.disabled = _selected_map == _MAP_ARDENNES
	var n_stars: int = MetaProgress.get_stars("M0Field", GameState.difficulty)
	var a_stars: int = MetaProgress.get_stars("Ardennes", GameState.difficulty)
	var name_for_map: String = "Normandy Field" if _selected_map == _MAP_NORMANDY else "Ardennes (winding forest path)"
	var s: int = n_stars if _selected_map == _MAP_NORMANDY else a_stars
	var rating: String = "★".repeat(s) + "☆".repeat(3 - s)
	map_label.text = "Map: %s   %s" % [name_for_map, rating]
	map_normandy_btn.text = "Normandy %s" % ("★".repeat(n_stars) + "☆".repeat(3 - n_stars))
	map_ardennes_btn.text = "Ardennes %s" % ("★".repeat(a_stars) + "☆".repeat(3 - a_stars))

func _refresh_top() -> void:
	wep_label.text = "War Effort: %d" % MetaProgress.war_effort_points
	if MetaProgress.lifetime_runs > 0:
		stats_label.text = "%d runs  ·  %d victories  ·  highest wave %d  ·  %d kills  ·  best combo x%d" % [
			MetaProgress.lifetime_runs,
			MetaProgress.lifetime_victories,
			MetaProgress.highest_wave,
			MetaProgress.lifetime_kills,
			MetaProgress.highest_combo,
		]
	else:
		stats_label.text = "No runs yet — start one below."
	var earned: int = MetaProgress.achievements_earned.size()
	var total: int = MetaProgress.ACHIEVEMENTS.size()
	ach_label.text = "Achievements: %d / %d" % [earned, total]

func _on_start_pressed() -> void:
	start_run_requested.emit(_selected_map)

func _on_codex_pressed() -> void:
	codex_overlay.visible = true
	_refresh_codex_list()

func _close_codex() -> void:
	codex_overlay.visible = false

func _refresh_codex_list() -> void:
	for c in codex_list.get_children():
		c.queue_free()
	var seen_count: int = 0
	for path in _CODEX_PATHS:
		var entry: Resource = load(path)
		if entry == null:
			continue
		var seen: bool = entry.id in MetaProgress.codex_seen
		if seen:
			seen_count += 1
		var btn := Button.new()
		btn.text = ("✓ " if seen else "    ") + entry.title
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.modulate = Color(1, 1, 1, 1) if seen else Color(0.6, 0.6, 0.6, 1)
		btn.pressed.connect(_show_codex_entry.bind(entry))
		codex_list.add_child(btn)
	codex_progress.text = "Codex read: %d / %d" % [seen_count, _CODEX_PATHS.size()]

func _open_ach() -> void:
	ach_overlay.visible = true
	_refresh_ach_list()

func _close_ach() -> void:
	ach_overlay.visible = false

func _refresh_ach_list() -> void:
	for c in ach_list.get_children():
		c.queue_free()
	var earned: int = MetaProgress.achievements_earned.size()
	var total: int = MetaProgress.ACHIEVEMENTS.size()
	ach_progress.text = "Earned: %d / %d" % [earned, total]
	for id in MetaProgress.ACHIEVEMENTS:
		var entry: Dictionary = MetaProgress.ACHIEVEMENTS[id]
		var unlocked: bool = id in MetaProgress.achievements_earned
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		card.add_child(vb)
		var name_lbl := Label.new()
		var icon: String = "✓ " if unlocked else "• "
		name_lbl.text = "%s%s  —  +%d WEP" % [icon, entry.get("label", ""), int(entry.get("wep", 0))]
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.modulate = Color(1, 0.95, 0.55, 1) if unlocked else Color(0.6, 0.6, 0.6, 1)
		vb.add_child(name_lbl)
		var desc_lbl := Label.new()
		desc_lbl.text = entry.get("desc", "")
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.85, 0.85, 0.85, 1) if unlocked else Color(0.55, 0.55, 0.55, 1)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(desc_lbl)
		ach_list.add_child(card)

func _show_codex_entry(entry: Resource) -> void:
	codex_title.text = entry.title
	codex_body.text = entry.body
	codex_sources.text = entry.sources
	# Try to load a matching portrait from the figure or enemy bank.
	var portrait_paths: Array[String] = [
		"res://art/figures/%s.jpg" % String(entry.id),
		"res://art/enemies/%s.jpg" % String(entry.id),
	]
	codex_portrait.visible = false
	for p in portrait_paths:
		if ResourceLoader.exists(p):
			codex_portrait.texture = load(p)
			codex_portrait.visible = true
			break
	MetaProgress.mark_codex_seen(entry.id)
	_refresh_codex_list()

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
