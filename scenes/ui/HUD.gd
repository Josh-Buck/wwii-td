extends CanvasLayer

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var enemy_count_label: Label = $TopBar/EnemyCountLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var end_screen: Control = $EndScreen
@onready var end_label: Label = $EndScreen/Panel/VBox/Label
@onready var end_waves_label: Label = $EndScreen/Panel/VBox/WavesLabel
@onready var end_earned_label: Label = $EndScreen/Panel/VBox/EarnedLabel
@onready var end_total_label: Label = $EndScreen/Panel/VBox/TotalLabel
@onready var end_stats_label: Label = $EndScreen/Panel/VBox/StatsLabel
@onready var end_perk_btn: Button = $EndScreen/Panel/VBox/PerkButton
@onready var end_recruit_btn: Button = $EndScreen/Panel/VBox/RecruitButton
@onready var end_restart_btn: Button = $EndScreen/Panel/VBox/RestartButton
@onready var recruit_screen: Control = $RecruitScreen
@onready var recruit_wep_label: Label = $RecruitScreen/Panel/VBox/WepLabel
@onready var recruit_roster_list: VBoxContainer = $RecruitScreen/Panel/VBox/Scroll/RosterList
@onready var recruit_close_btn: Button = $RecruitScreen/Panel/VBox/CloseButton
@onready var hint_label: Label = $HintLabel
@onready var selection_label: Label = $SelectionLabel
@onready var tooltip: PanelContainer = $Tooltip
@onready var tooltip_title: Label = $Tooltip/VBox/TitleLabel
@onready var tooltip_lore: Label = $Tooltip/VBox/LoreLabel
@onready var info_panel: PanelContainer = $TowerInfoPanel
@onready var info_name: Label = $TowerInfoPanel/VBox/NameLabel
@onready var info_lore: Label = $TowerInfoPanel/VBox/LoreLabel
@onready var info_target_btn: Button = $TowerInfoPanel/VBox/ButtonRow/TargetButton
@onready var info_sell_btn: Button = $TowerInfoPanel/VBox/ButtonRow/SellButton
@onready var info_close_btn: Button = $TowerInfoPanel/VBox/CloseButton
@onready var pause_btn: Button = $TopBar/PauseButton
@onready var pause_overlay: Control = $PauseOverlay
@onready var resume_btn: Button = $PauseOverlay/Center/VBox/ResumeButton
@onready var pause_restart_btn: Button = $PauseOverlay/Center/VBox/PauseRestartButton
@onready var pause_quit_btn: Button = $PauseOverlay/Center/VBox/PauseQuitButton
@onready var speed_btn: Button = $TopBar/SpeedButton
@onready var sidebar: PanelContainer = $TowerSidebar
@onready var sidebar_list: VBoxContainer = $TowerSidebar/VBox/ScrollContainer/PaletteList
@onready var sidebar_collapse_btn: Button = $TowerSidebar/VBox/HeaderRow/CollapseButton
@onready var sidebar_tab: Button = $TowerSidebarTab
@onready var wave_preview_panel: PanelContainer = $WavePreviewPanel
@onready var wave_preview_label: Label = $WavePreviewPanel/HBox/Label
@onready var wave_preview_icons: HBoxContainer = $WavePreviewPanel/HBox/IconRow
@onready var start_wave_panel: PanelContainer = $StartWavePanel
@onready var start_wave_btn: Button = $StartWavePanel/VBox/StartWaveButton
@onready var boss_telegraph: PanelContainer = $BossTelegraph
@onready var boss_telegraph_label: Label = $BossTelegraph/Label
@onready var toast: PanelContainer = $Toast
@onready var toast_label: Label = $Toast/Label
var _toast_remaining: float = 0.0

var _wave_in_progress: bool = false
var _waves_completed: int = 0
@onready var def_info_panel: PanelContainer = $DefenderInfoPanel
@onready var def_name: Label = $DefenderInfoPanel/VBox/HeaderRow/NameLabel
@onready var def_close_btn: Button = $DefenderInfoPanel/VBox/HeaderRow/CloseButton
@onready var def_faction: Label = $DefenderInfoPanel/VBox/FactionLabel
@onready var def_stats: Label = $DefenderInfoPanel/VBox/StatsLabel
@onready var def_hits: Label = $DefenderInfoPanel/VBox/HitsLabel
@onready var def_strength: Label = $DefenderInfoPanel/VBox/StrengthLabel
@onready var def_weakness: Label = $DefenderInfoPanel/VBox/WeaknessLabel
@onready var def_lore: Label = $DefenderInfoPanel/VBox/LoreLabel
@onready var def_upgrades_header: Label = $DefenderInfoPanel/VBox/UpgradesHeader
@onready var def_upgrades_grid: GridContainer = $DefenderInfoPanel/VBox/UpgradesGrid
@onready var def_target_btn: Button = $DefenderInfoPanel/VBox/ActionRow/TargetButton
@onready var def_sell_btn: Button = $DefenderInfoPanel/VBox/ActionRow/SellButton

var _info_active_tower: Node = null  ## tower currently shown in info panel (if placed)
var _info_active_stats: Resource = null  ## stats currently shown (palette card or placed tower)

const _SPEED_CYCLE: Array[float] = [1.0, 2.0, 4.0]
var _speed_idx: int = 0
var _palette_towers: Array = []
var _palette_btns: Array = []
var _sidebar_collapsed: bool = false
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var shop_title: Label = $ShopPanel/VBox/Title
@onready var shop_gold_label: Label = $ShopPanel/VBox/GoldLabel
@onready var shop_bonds_container: VBoxContainer = $ShopPanel/VBox/Scroll/ScrollContent/BondsContainer
@onready var shop_held_container: VBoxContainer = $ShopPanel/VBox/Scroll/ScrollContent/HeldContainer
@onready var shop_stocks_container: VBoxContainer = $ShopPanel/VBox/Scroll/ScrollContent/StocksContainer
@onready var shop_next_btn: Button = $ShopPanel/VBox/NextWaveButton
@onready var codex_btn: Button = $TopBar/CodexButton
@onready var codex_panel: PanelContainer = $CodexPanel
@onready var codex_title: Label = $CodexPanel/VBox/Title
@onready var codex_list: VBoxContainer = $CodexPanel/VBox/Scroll/EntryList
@onready var codex_close_btn: Button = $CodexPanel/VBox/CloseButton

const _CODEX_ENTRY_PATHS: Array[String] = [
	"res://data/codex/patton.tres",
	"res://data/codex/eisenhower.tres",
	"res://data/codex/churchill.tres",
	"res://data/codex/anne_frank.tres",
	"res://data/codex/montgomery.tres",
	"res://data/codex/pavlichenko.tres",
	"res://data/codex/fdr.tres",
	"res://data/codex/bletchley.tres",
	"res://data/codex/airborne_101.tres",
	"res://data/codex/wehrmacht_infantry.tres",
	"res://data/codex/panzer_iii.tres",
	"res://data/codex/stuka.tres",
	"res://data/codex/rommel.tres",
	"res://data/codex/eichmann.tres",
	"res://data/codex/heydrich.tres",
	"res://data/codex/mengele.tres",
	"res://data/codex/himmler.tres",
	"res://data/codex/tojo.tres",
	"res://data/codex/audie_murphy.tres",
	"res://data/codex/zhukov.tres",
	"res://data/codex/rosie.tres",
	"res://data/codex/lemay.tres",
	"res://data/codex/tuskegee.tres",
	"res://data/codex/tiger_i.tres",
	"res://data/codex/waffen_ss.tres",
	"res://data/codex/banzai.tres",
	"res://data/codex/bersaglieri.tres",
]

var _selected_tower: Node = null
var _shop_bonds: Array = []
var _codex_entries: Array = []

func _ready() -> void:
	end_screen.visible = false
	tooltip.visible = false
	info_panel.visible = false
	EventBus.gold_changed.connect(func(g): gold_label.text = "Gold: %d" % g)
	EventBus.lives_changed.connect(func(l): lives_label.text = "Lives: %d" % l)
	EventBus.wave_started.connect(_on_wave_label_update)
	EventBus.tower_selection_changed.connect(_on_selection_changed)
	EventBus.tower_hovered.connect(_on_tower_hovered)
	EventBus.tower_unhovered.connect(_on_tower_unhovered)
	EventBus.enemy_hovered.connect(_on_enemy_hovered)
	EventBus.enemy_unhovered.connect(_on_enemy_unhovered)
	EventBus.tower_clicked.connect(_on_tower_clicked)
	info_target_btn.pressed.connect(_on_target_btn_pressed)
	info_sell_btn.pressed.connect(_on_sell_btn_pressed)
	info_close_btn.pressed.connect(_on_close_btn_pressed)
	pause_btn.pressed.connect(toggle_pause)
	resume_btn.pressed.connect(toggle_pause)
	pause_restart_btn.pressed.connect(_on_pause_restart_pressed)
	pause_quit_btn.pressed.connect(_on_pause_quit_pressed)
	pause_overlay.visible = false
	speed_btn.pressed.connect(_cycle_speed)
	_apply_speed()
	end_perk_btn.pressed.connect(_on_perk_btn_pressed)
	end_recruit_btn.pressed.connect(_open_recruit_screen)
	end_restart_btn.pressed.connect(_on_restart_pressed)
	recruit_close_btn.pressed.connect(_close_recruit_screen)
	recruit_screen.visible = false
	EventBus.map_ready.connect(_on_map_ready)
	sidebar_collapse_btn.pressed.connect(_toggle_sidebar)
	sidebar_tab.pressed.connect(_toggle_sidebar)
	def_close_btn.pressed.connect(_hide_defender_info)
	def_target_btn.pressed.connect(_on_def_target_pressed)
	def_sell_btn.pressed.connect(_on_def_sell_pressed)
	wave_preview_panel.visible = false
	EventBus.tower_placed.connect(_refresh_wave_preview_from_signal)
	EventBus.tower_sold.connect(_refresh_wave_preview_after_sell)
	EventBus.wave_started.connect(_refresh_wave_preview_after_wave)
	EventBus.wave_ended.connect(_refresh_wave_preview_after_wave)
	EventBus.wave_started.connect(_check_boss_telegraph)
	EventBus.boss_escaped.connect(_on_boss_escaped)
	boss_telegraph.visible = false
	EventBus.codex_entry_unlocked.connect(_on_codex_unlocked_toast)
	EventBus.bond_matured.connect(_on_bond_matured_toast)
	toast.visible = false
	# Start Wave button drives wave advance (replaces auto-start timer).
	start_wave_btn.pressed.connect(_on_start_wave_btn_pressed)
	EventBus.wave_started.connect(_on_wave_started_for_btn)
	EventBus.wave_ended.connect(_on_wave_ended_for_btn)
	EventBus.run_started.connect(_on_run_started_for_btn)
	EventBus.run_ended.connect(_on_run_ended_for_btn)
	EventBus.shop_opened.connect(_on_shop_opened_for_btn)
	EventBus.shop_closed.connect(_on_shop_closed_for_btn)
	_refresh_start_wave_btn()
	shop_panel.visible = false
	shop_next_btn.pressed.connect(_on_shop_next_pressed)
	EventBus.shop_opened.connect(_on_shop_opened)
	EventBus.gold_changed.connect(_on_gold_changed_for_shop)
	EventBus.bond_matured.connect(_on_bond_matured_in_shop)
	codex_panel.visible = false
	codex_btn.pressed.connect(_toggle_codex)
	codex_close_btn.pressed.connect(_toggle_codex)
	EventBus.codex_entry_unlocked.connect(_on_codex_entry_unlocked)
	for path in _CODEX_ENTRY_PATHS:
		var entry: Resource = load(path)
		if entry != null:
			_codex_entries.append(entry)
	gold_label.text = "Gold: %d" % GameState.gold
	lives_label.text = "Lives: %d" % GameState.lives
	wave_label.text = "Wave 1"
	if hint_label:
		hint_label.text = "Sidebar: left-click = pick, right-click = info.  Click placed tower = upgrades / sell / target.  Space=speed, P=pause, C=codex."
	if selection_label:
		selection_label.text = "Selected: —"

func _process(delta: float) -> void:
	if tooltip.visible:
		var mp := get_viewport().get_mouse_position()
		# Offset so cursor doesn't overlap; flip to left of cursor near right edge.
		var pos := mp + Vector2(20, 16)
		var vp_size := get_viewport().get_visible_rect().size
		if pos.x + tooltip.size.x > vp_size.x:
			pos.x = mp.x - tooltip.size.x - 20
		if pos.y + tooltip.size.y > vp_size.y:
			pos.y = mp.y - tooltip.size.y - 16
		tooltip.position = pos
	if _toast_remaining > 0.0:
		_toast_remaining -= delta
		if _toast_remaining <= 0.0:
			toast.visible = false
	# Live enemy count during a wave.
	if _wave_in_progress:
		var wd_nodes := get_tree().get_nodes_in_group("wave_director")
		if not wd_nodes.is_empty():
			var wd: Node = wd_nodes[0]
			if wd.has_method("get_enemies_remaining") and wd.has_method("get_wave_total"):
				var rem: int = wd.get_enemies_remaining()
				var tot: int = wd.get_wave_total()
				enemy_count_label.text = "  ·  %d / %d enemies" % [tot - rem, tot]
	else:
		enemy_count_label.text = ""

func _on_selection_changed(stats: Resource) -> void:
	if selection_label and stats:
		selection_label.text = "Selected: %s (%dg)" % [stats.display_name, stats.cost]
	_refresh_palette_highlight(stats)

func _on_wave_label_update(w: int) -> void:
	var wd_nodes := get_tree().get_nodes_in_group("wave_director")
	if wd_nodes.is_empty():
		wave_label.text = "Wave %d" % (w + 1)
		return
	var wd: Node = wd_nodes[0]
	var scripted: int = wd.wave_count()
	if w < scripted:
		wave_label.text = "Wave %d / %d" % [w + 1, scripted]
	else:
		wave_label.text = "Endless +%d" % (w - scripted + 1)

func _on_map_ready(towers: Array) -> void:
	_palette_towers = towers
	_palette_btns.clear()
	for c in sidebar_list.get_children():
		c.queue_free()
	for i in towers.size():
		var stats = towers[i]
		var card := _build_sidebar_card(i, stats)
		sidebar_list.add_child(card)
		_palette_btns.append(card)

func _build_sidebar_card(idx: int, stats: Resource) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 84)
	btn.toggle_mode = true
	btn.flat = false
	btn.text = ""  ## text rendered by inner Label so layout is precise
	btn.modulate = stats.color.lerp(Color.WHITE, 0.4)
	btn.pressed.connect(_on_palette_btn_pressed.bind(idx))
	# Sidebar click only selects for placement; the detailed info panel is
	# reserved for placed towers (where the upgrade grid is interactive).
	# Built-in hover tooltip (fixed-position, ~0.5s delay) carries description.
	btn.tooltip_text = _palette_tooltip_for(stats)
	# Right-click → open the description panel without entering placement mode.
	btn.gui_input.connect(_on_palette_card_gui_input.bind(stats))

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	btn.add_child(hbox)

	# Portrait (~72px square) on the left — face front-and-center.
	if stats.portrait != null:
		var tex := TextureRect.new()
		tex.texture = stats.portrait
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.custom_minimum_size = Vector2(72, 72)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(tex)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = "%d. %s" % [idx + 1, _short_figure_name(stats.display_name)]
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "%dg %s" % [stats.cost, _short_target_label(stats.default_targeting)]
	cost_lbl.modulate = Color(1, 1, 1, 0.85)
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_lbl)

	return btn

func _palette_tooltip_for(stats: Resource) -> String:
	if stats == null:
		return ""
	var dps: float = stats.damage * stats.fire_rate
	var lines: Array[String] = []
	lines.append("%s — %dg" % [stats.display_name, stats.cost])
	if stats.damage > 0:
		lines.append("Damage %d  ·  Rate %.1f/s  ·  Range %d  ·  DPS %d" % [
			int(stats.damage), stats.fire_rate, int(stats.range_px), int(dps)
		])
	if stats.aura_radius > 0:
		lines.append("Aura r%d  ·  +%d%% fire rate to allies" % [
			int(stats.aura_radius), int(stats.aura_fire_rate_bonus * 100)
		])
	if stats.gold_per_sec > 0:
		lines.append("Eco: +%dg/sec while a wave is active" % int(stats.gold_per_sec))
	if stats.provides_wave_preview:
		lines.append("Reveals next wave's enemy composition")
	if stats.tooltip_lore != "":
		lines.append("")
		lines.append(stats.tooltip_lore)
	lines.append("")
	lines.append("Left-click to select for placement.  Right-click for full info.")
	return "\n".join(lines)

func _on_palette_card_gui_input(event: InputEvent, stats: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_show_defender_info(stats, null)
		get_viewport().set_input_as_handled()

func _show_defender_info(stats: Resource, placed_tower: Node = null) -> void:
	if stats == null:
		return
	# Deselect previously selected tower (range ring goes away).
	if _info_active_tower and is_instance_valid(_info_active_tower):
		_info_active_tower.selected = false
		_info_active_tower.queue_redraw()
	_info_active_stats = stats
	_info_active_tower = placed_tower if placed_tower and is_instance_valid(placed_tower) else null
	if _info_active_tower:
		_info_active_tower.selected = true
		_info_active_tower.queue_redraw()
	def_name.text = "%s — %dg" % [stats.display_name, stats.cost]
	def_faction.text = "Faction: %s" % _faction_label(stats.faction)
	# If a placed tower is shown, display its EFFECTIVE stats (with upgrades);
	# otherwise show the base stats from the resource.
	var d_value: float = stats.damage
	var r_value: float = stats.fire_rate
	var range_value: float = stats.range_px
	var aoe_value: float = stats.aoe_radius
	if _info_active_tower and is_instance_valid(_info_active_tower):
		if _info_active_tower.has_method("effective_damage"):
			d_value = _info_active_tower.effective_damage()
		if _info_active_tower.has_method("effective_fire_rate"):
			r_value = _info_active_tower.effective_fire_rate()
		if _info_active_tower.has_method("effective_range"):
			range_value = _info_active_tower.effective_range()
		if _info_active_tower.has_method("effective_aoe_radius"):
			aoe_value = _info_active_tower.effective_aoe_radius()
	var dps: float = d_value * r_value
	var aoe_str: String = ""
	if aoe_value > 0:
		aoe_str = "  AoE r%d" % int(aoe_value)
	def_stats.text = "Damage %d  ·  Rate %.1f/s  ·  Range %d  ·  DPS %d%s" % [
		int(d_value), r_value, int(range_value), int(dps), aoe_str
	]
	def_hits.text = "Hits: %s   Default target: %s" % [
		_hits_text(stats.can_hit),
		_short_target_label(stats.default_targeting).replace("→ ", ""),
	]
	def_strength.text = "Strengths: %s" % _strengths_for(stats)
	def_weakness.text = "Weaknesses: %s" % _weaknesses_for(stats)
	def_lore.text = stats.tooltip_lore
	_refresh_upgrades_grid()
	_refresh_action_row()
	_position_defender_panel(placed_tower)
	def_info_panel.visible = true

func _position_defender_panel(placed_tower: Node) -> void:
	# Anchor the panel to whichever half of the screen the tower is NOT on,
	# so it never covers the unit you're inspecting.
	var panel_width: float = 320.0
	var left: float
	if placed_tower and is_instance_valid(placed_tower) and placed_tower.global_position.x > 640.0:
		left = 32.0  # tower is right side → panel on left
	else:
		left = 1052.0 - panel_width  # tower is left side → panel on right
	def_info_panel.offset_left = left
	def_info_panel.offset_top = 60.0
	def_info_panel.offset_right = left + panel_width
	def_info_panel.offset_bottom = 660.0

func _hide_defender_info() -> void:
	if _info_active_tower and is_instance_valid(_info_active_tower):
		_info_active_tower.selected = false
		_info_active_tower.queue_redraw()
	def_info_panel.visible = false
	_info_active_tower = null
	_info_active_stats = null

func _refresh_upgrades_grid() -> void:
	for c in def_upgrades_grid.get_children():
		c.queue_free()
	if _info_active_stats == null:
		return
	var branches: Dictionary = UpgradeRegistry.get_branches(_info_active_stats.id)
	if branches.is_empty():
		def_upgrades_header.text = "Upgrades — none defined"
		return
	if _info_active_tower:
		def_upgrades_header.text = "Upgrades — Branch A vs Branch B"
	else:
		def_upgrades_header.text = "Upgrades (place this tower to purchase)"
	var branch_keys: Array = [&"branch_a", &"branch_b"]
	for tier_idx in 3:
		for branch in branch_keys:
			var step: Dictionary = UpgradeRegistry.get_tier(_info_active_stats.id, branch, tier_idx)
			if step.is_empty():
				def_upgrades_grid.add_child(Control.new())
				continue
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.text = _format_upgrade_btn_text(step, tier_idx, branch)
			btn.disabled = not _can_purchase_upgrade(branch, tier_idx, step)
			btn.tooltip_text = step.get("desc", "")
			btn.pressed.connect(_on_upgrade_btn_pressed.bind(branch, tier_idx))
			def_upgrades_grid.add_child(btn)

func _format_upgrade_btn_text(step: Dictionary, tier_idx: int, branch: StringName) -> String:
	var owned := false
	if _info_active_tower:
		var current_tier: int = _info_active_tower.upgrade_a_tier if branch == &"branch_a" else _info_active_tower.upgrade_b_tier
		owned = current_tier > tier_idx
	var prefix := "✓ " if owned else ""
	return "%sT%d %s — %dg" % [prefix, tier_idx + 1, step.get("name", ""), step.get("cost", 0)]

func _can_purchase_upgrade(branch: StringName, tier_idx: int, step: Dictionary) -> bool:
	if _info_active_tower == null or not is_instance_valid(_info_active_tower):
		return false
	var current_tier: int = _info_active_tower.upgrade_a_tier if branch == &"branch_a" else _info_active_tower.upgrade_b_tier
	if tier_idx < current_tier:
		return false  # already owned
	if tier_idx > current_tier:
		return false  # need previous tier first
	return GameState.gold >= int(step.get("cost", 0))

func _on_upgrade_btn_pressed(branch: StringName, tier_idx: int) -> void:
	if _info_active_tower == null or not is_instance_valid(_info_active_tower):
		return
	if _info_active_tower.purchase_upgrade(branch, tier_idx):
		_refresh_upgrades_grid()
		_refresh_action_row()

func _refresh_action_row() -> void:
	# Sell + target controls only apply to placed towers; hide for palette previews.
	var has_placed: bool = _info_active_tower != null and is_instance_valid(_info_active_tower)
	def_target_btn.visible = has_placed
	def_sell_btn.visible = has_placed
	if not has_placed:
		return
	def_target_btn.text = "Target: %s" % String(_info_active_tower.targeting_mode).capitalize()
	var base_cost: int = _info_active_stats.cost if _info_active_stats else 0
	var refund: int = int((base_cost + _info_active_tower.total_invested) * 0.75)
	def_sell_btn.text = "Sell (+%dg)" % refund

func _on_def_target_pressed() -> void:
	if _info_active_tower and is_instance_valid(_info_active_tower):
		_info_active_tower.cycle_targeting_mode()
		_refresh_action_row()
		_show_defender_info(_info_active_stats, _info_active_tower)

func _on_def_sell_pressed() -> void:
	if _info_active_tower and is_instance_valid(_info_active_tower):
		_info_active_tower.sell()
	_hide_defender_info()

func _faction_label(f: StringName) -> String:
	match f:
		&"us": return "United States"
		&"uk": return "United Kingdom"
		&"ussr": return "Soviet Union"
		&"resistance": return "Resistance / civilian"
		&"axis_germany": return "Nazi Germany"
		&"axis_japan": return "Imperial Japan"
		&"axis_italy": return "Fascist Italy"
	return String(f)

func _hits_text(flags: int) -> String:
	var parts: Array[String] = []
	if flags & 1: parts.append("Ground")
	if flags & 2: parts.append("Air")
	if flags & 4: parts.append("Armor")
	if flags & 8: parts.append("Camo")
	return " + ".join(parts) if parts.size() > 0 else "—"

func _strengths_for(stats: Resource) -> String:
	var parts: Array[String] = []
	if stats.aoe_radius > 0:
		parts.append("clears tight clusters")
	if stats.range_px >= 250:
		parts.append("very long range")
	if stats.damage >= 50 and stats.fire_rate <= 0.4:
		parts.append("massive single-shot vs heavies")
	if (stats.can_hit & 8) != 0:
		parts.append("sees hidden / camo enemies")
	if stats.fire_rate >= 1.2:
		parts.append("fast firing")
	if (stats.can_hit & 4) != 0 and stats.damage * stats.fire_rate >= 15:
		parts.append("cuts through armor")
	if parts.is_empty():
		parts.append("flexible generalist")
	return ", ".join(parts)

func _weaknesses_for(stats: Resource) -> String:
	var parts: Array[String] = []
	if (stats.can_hit & 2) == 0:
		parts.append("can't hit air")
	if (stats.can_hit & 4) == 0:
		parts.append("struggles vs armor")
	if (stats.can_hit & 8) == 0 and stats.range_px < 200:
		parts.append("blind to camo")
	if stats.fire_rate <= 0.25:
		parts.append("very slow rate of fire")
	if stats.cost >= 200:
		parts.append("expensive")
	if parts.is_empty():
		parts.append("none specifically")
	return ", ".join(parts)

func _short_target_label(mode: StringName) -> String:
	match mode:
		&"first": return "→ first"
		&"last": return "→ last"
		&"strong": return "→ strong"
		&"close": return "→ close"
		&"camo": return "→ camo"
	return ""

func _on_palette_btn_pressed(idx: int) -> void:
	EventBus.tower_palette_pick.emit(idx)

func _refresh_palette_highlight(active_stats: Resource) -> void:
	for i in _palette_btns.size():
		var btn: Button = _palette_btns[i]
		if not is_instance_valid(btn):
			continue
		var is_active: bool = i < _palette_towers.size() and _palette_towers[i] == active_stats
		btn.button_pressed = is_active

func _toggle_sidebar() -> void:
	_sidebar_collapsed = not _sidebar_collapsed
	sidebar.visible = not _sidebar_collapsed
	sidebar_tab.visible = _sidebar_collapsed
	# When sidebar collapses, also dismiss the detailed info panel so the
	# screen isn't cluttered.
	if _sidebar_collapsed:
		_hide_defender_info()

func _refresh_wave_preview_from_signal(_t: Node) -> void:
	_refresh_wave_preview()

func _refresh_wave_preview_after_sell(_t: Node, _refund: int) -> void:
	_refresh_wave_preview()

func _refresh_wave_preview_after_wave(_idx: int) -> void:
	_refresh_wave_preview()

func _on_boss_escaped(_boss: Node, boss_id: StringName) -> void:
	# Mengele-style narrative beat — boss got away. Show in the boss telegraph
	# slot in a different colour so the player notices.
	boss_telegraph_label.text = "%s ESCAPED — never captured" % _humanize_id(boss_id)
	boss_telegraph.modulate = Color(0.9, 0.4, 0.4, 1)
	boss_telegraph.visible = true
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(boss_telegraph):
		boss_telegraph.visible = false
		boss_telegraph.modulate = Color(1, 0.7, 0.3, 1)  # restore default tint

func _check_boss_telegraph(_idx: int) -> void:
	var wd_nodes := get_tree().get_nodes_in_group("wave_director")
	if wd_nodes.is_empty():
		return
	var wd: Node = wd_nodes[0]
	if not wd.has_method("get_boss_id_for_current_wave"):
		return
	var boss_id: StringName = wd.get_boss_id_for_current_wave()
	if boss_id == &"":
		return
	# Show telegraph with the boss's display name.
	var label_text: String = "⚠ BOSS WAVE: %s" % _humanize_id(boss_id)
	boss_telegraph_label.text = label_text
	boss_telegraph.visible = true
	# Auto-hide after 4 seconds.
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(boss_telegraph):
		boss_telegraph.visible = false

func _humanize_id(id: StringName) -> String:
	var s: String = String(id).replace("_", " ")
	return s.capitalize()

func _refresh_wave_preview() -> void:
	var providers := get_tree().get_nodes_in_group("wave_preview_providers")
	if providers.is_empty():
		wave_preview_panel.visible = false
		return
	var wd_nodes := get_tree().get_nodes_in_group("wave_director")
	if wd_nodes.is_empty():
		wave_preview_panel.visible = false
		return
	var wd: Node = wd_nodes[0]
	if not wd.has_method("get_next_wave_spawns"):
		return
	# Clear existing icons.
	for c in wave_preview_icons.get_children():
		c.queue_free()
	# Aggregate by enemy id.
	var spawns: Array = wd.get_next_wave_spawns()
	var counts: Dictionary = {}
	for s in spawns:
		var id: StringName = StringName(s.get("enemy", ""))
		if id == &"":
			continue
		counts[id] = counts.get(id, 0) + int(s.get("count", 1))
	if counts.is_empty():
		wave_preview_label.text = "Next: (final wave cleared)"
		wave_preview_panel.visible = true
		return
	wave_preview_label.text = "Next:"
	for id in counts:
		var stats: Resource = wd.enemy_registry.get(id, null) if "enemy_registry" in wd else null
		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 4)
		entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if stats and stats.portrait != null:
			var tex := TextureRect.new()
			tex.texture = stats.portrait
			tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tex.custom_minimum_size = Vector2(28, 28)
			tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			entry.add_child(tex)
		var lbl := Label.new()
		lbl.text = "x%d" % counts[id]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(lbl)
		wave_preview_icons.add_child(entry)
	wave_preview_panel.visible = true

func _on_start_wave_btn_pressed() -> void:
	EventBus.start_wave_requested.emit()

func _on_wave_started_for_btn(_idx: int) -> void:
	_wave_in_progress = true
	_refresh_start_wave_btn()

func _on_wave_ended_for_btn(idx: int) -> void:
	_wave_in_progress = false
	_waves_completed = idx + 1
	_refresh_start_wave_btn()

func _on_run_started_for_btn() -> void:
	_wave_in_progress = false
	_waves_completed = 0
	_refresh_start_wave_btn()

func _on_run_ended_for_btn(_v: bool) -> void:
	_wave_in_progress = false
	start_wave_panel.visible = false

func _on_shop_opened_for_btn(_b: Array) -> void:
	# While shop is open, hide the start button; shop's Next Wave button drives advance.
	start_wave_panel.visible = false

func _on_shop_closed_for_btn() -> void:
	# Map auto-emits start_wave_requested via shop's Next Wave button now? No —
	# shop's Next Wave just closes the panel. We re-show the start button so the
	# player can place towers between shop close and the next wave.
	_refresh_start_wave_btn()

func _refresh_start_wave_btn() -> void:
	if not GameState.run_active:
		start_wave_panel.visible = false
		return
	if _wave_in_progress:
		start_wave_panel.visible = false
		return
	# Determine which wave is next.
	var next_wave_num: int = _waves_completed + 1
	start_wave_btn.text = "Start Wave %d ▶" % next_wave_num
	start_wave_panel.visible = true

func _short_figure_name(full: String) -> String:
	var parts := full.split(" ")
	if parts.size() <= 1:
		return full
	return "%s. %s" % [parts[0].substr(0, 1), parts[-1]]

func _show_tooltip_for_stats(stats: Resource) -> void:
	if stats == null:
		return
	tooltip_title.text = stats.display_name
	tooltip_lore.text = stats.tooltip_lore
	tooltip.visible = true

func _on_tower_hovered(tower: Node) -> void:
	if tower and tower.stats:
		tooltip_title.text = tower.stats.display_name
		tooltip_lore.text = tower.stats.tooltip_lore + "\n\n→ Click to sell or change targeting"
		tooltip.visible = true
		if tower.stats.codex_id != &"":
			MetaProgress.mark_codex_seen(tower.stats.codex_id)

func _on_tower_unhovered(_tower: Node) -> void:
	tooltip.visible = false

func _on_enemy_hovered(enemy: Node) -> void:
	if enemy and enemy.stats:
		_show_tooltip_for_stats(enemy.stats)
		if enemy.stats.codex_id != &"":
			MetaProgress.mark_codex_seen(enemy.stats.codex_id)

func _on_enemy_unhovered(_enemy: Node) -> void:
	tooltip.visible = false

func _on_tower_clicked(tower: Node) -> void:
	_selected_tower = tower
	if is_instance_valid(tower) and tower.stats:
		_show_defender_info(tower.stats, tower)

func _refresh_info_panel() -> void:
	if _selected_tower == null or not is_instance_valid(_selected_tower):
		info_panel.visible = false
		return
	var stats = _selected_tower.stats
	if stats == null:
		info_panel.visible = false
		return
	info_name.text = "%s (cost %dg)" % [stats.display_name, stats.cost]
	info_lore.text = stats.tooltip_lore
	info_target_btn.text = "Target: %s" % String(_selected_tower.targeting_mode).capitalize()
	info_sell_btn.text = "Sell (+%dg)" % int(stats.cost * 0.75)

func _on_target_btn_pressed() -> void:
	if _selected_tower and is_instance_valid(_selected_tower):
		_selected_tower.cycle_targeting_mode()
		_refresh_info_panel()

func _on_sell_btn_pressed() -> void:
	if _selected_tower and is_instance_valid(_selected_tower):
		_selected_tower.sell()
	_selected_tower = null
	info_panel.visible = false

func _on_close_btn_pressed() -> void:
	_selected_tower = null
	info_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_P:
			toggle_pause()
			get_viewport().set_input_as_handled()
		KEY_C:
			_toggle_codex()
			get_viewport().set_input_as_handled()
		KEY_SPACE:
			_cycle_speed()
			get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var p := not get_tree().paused
	get_tree().paused = p
	pause_overlay.visible = p
	pause_btn.text = "Resume (P)" if p else "Pause (P)"
	EventBus.pause_toggled.emit(p)

func _cycle_speed() -> void:
	_speed_idx = (_speed_idx + 1) % _SPEED_CYCLE.size()
	_apply_speed()

func _apply_speed() -> void:
	Engine.time_scale = _SPEED_CYCLE[_speed_idx]
	speed_btn.text = "Speed: %dx" % int(_SPEED_CYCLE[_speed_idx])

func _on_shop_opened(bonds: Array) -> void:
	_shop_bonds = bonds
	shop_title.text = "Wave %d complete — War Room" % (GameState.wave_index + 1)
	_refresh_shop_bonds()
	_refresh_held_bonds()
	_refresh_shop_stocks()
	shop_panel.visible = true

func _on_shop_next_pressed() -> void:
	shop_panel.visible = false
	EventBus.shop_closed.emit()
	# Immediately start the next wave (shop's Next Wave is the wave-trigger
	# during the shop phase). For Wave 2+ this matches the user's expectation.
	EventBus.start_wave_requested.emit()

func _refresh_shop_bonds() -> void:
	for c in shop_bonds_container.get_children():
		c.queue_free()
	for bond in _shop_bonds:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s — pay %dg, receive %dg in %d waves" % [
			bond.display_name, bond.cost, bond.payout, bond.maturity_waves
		]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.text = "Buy %dg" % bond.cost
		btn.disabled = bond.cost > GameState.gold
		btn.pressed.connect(_on_buy_bond.bind(bond))
		row.add_child(label)
		row.add_child(btn)
		shop_bonds_container.add_child(row)
	shop_gold_label.text = "Gold: %d   Lives: %d" % [GameState.gold, GameState.lives]

func _on_buy_bond(bond: Resource) -> void:
	if GameState.buy_bond(bond):
		_refresh_shop_bonds()
		_refresh_held_bonds()

func _refresh_held_bonds() -> void:
	for c in shop_held_container.get_children():
		c.queue_free()
	if GameState.held_bonds.is_empty():
		var label := Label.new()
		label.text = "(none)"
		label.modulate = Color(1, 1, 1, 0.55)
		shop_held_container.add_child(label)
		return
	for entry in GameState.held_bonds:
		var label := Label.new()
		var plural := "s" if entry.waves_remaining != 1 else ""
		label.text = "%s — matures in %d wave%s, pays %dg" % [
			entry.bond.display_name,
			entry.waves_remaining,
			plural,
			entry.bond.payout,
		]
		shop_held_container.add_child(label)

func _on_gold_changed_for_shop(_g: int) -> void:
	if shop_panel.visible:
		_refresh_shop_bonds()
		_refresh_shop_stocks()

func _on_bond_matured_in_shop(_bond: Resource, _payout: int) -> void:
	if shop_panel.visible:
		_refresh_held_bonds()

func _refresh_shop_stocks() -> void:
	for c in shop_stocks_container.get_children():
		c.queue_free()
	for stock in StockMarket.stocks:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var price: float = StockMarket.get_price(stock.id)
		var trend: String = StockMarket.get_trend_symbol(stock.id)
		var owned: int = GameState.held_shares.get(stock.id, 0)
		var value: int = int(price * owned)
		var label := Label.new()
		label.text = "%s  %s %dg/share" % [stock.display_name, trend, int(round(price))]
		label.add_theme_font_size_override("font_size", 13)
		var hold_lbl := Label.new()
		hold_lbl.text = "Held: %d  ·  Value: %dg" % [owned, value]
		hold_lbl.add_theme_font_size_override("font_size", 11)
		hold_lbl.modulate = Color(0.85, 0.85, 0.85, 1)
		row.add_child(label)
		row.add_child(hold_lbl)
		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 4)
		var buy1 := Button.new()
		buy1.text = "Buy 1"
		buy1.disabled = GameState.gold < int(ceil(price))
		buy1.pressed.connect(_on_buy_share.bind(stock, 1))
		var buy5 := Button.new()
		buy5.text = "Buy 5"
		buy5.disabled = GameState.gold < int(ceil(price * 5))
		buy5.pressed.connect(_on_buy_share.bind(stock, 5))
		var sell1 := Button.new()
		sell1.text = "Sell 1"
		sell1.disabled = owned <= 0
		sell1.pressed.connect(_on_sell_share.bind(stock, 1))
		var sellall := Button.new()
		sellall.text = "Sell all"
		sellall.disabled = owned <= 0
		sellall.pressed.connect(_on_sell_share.bind(stock, owned))
		btn_row.add_child(buy1)
		btn_row.add_child(buy5)
		btn_row.add_child(sell1)
		btn_row.add_child(sellall)
		row.add_child(btn_row)
		shop_stocks_container.add_child(row)

func _on_buy_share(stock: Resource, count: int) -> void:
	if GameState.buy_shares(stock, count):
		_refresh_shop_stocks()

func _on_sell_share(stock: Resource, count: int) -> void:
	if count <= 0:
		return
	if GameState.sell_shares(stock, count):
		_refresh_shop_stocks()

func _toggle_codex() -> void:
	codex_panel.visible = not codex_panel.visible
	if codex_panel.visible:
		_refresh_codex()

func _refresh_codex() -> void:
	var unlocked_count := 0
	for entry in _codex_entries:
		if entry.id in MetaProgress.codex_seen:
			unlocked_count += 1
	codex_title.text = "Codex — %d / %d unlocked" % [unlocked_count, _codex_entries.size()]
	for c in codex_list.get_children():
		c.queue_free()
	for entry in _codex_entries:
		var unlocked: bool = entry.id in MetaProgress.codex_seen
		var entry_box := VBoxContainer.new()
		entry_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title_label := Label.new()
		title_label.add_theme_font_size_override("font_size", 18)
		if unlocked:
			title_label.text = entry.title
		else:
			title_label.text = "??? (encounter to unlock)"
			title_label.modulate = Color(1, 1, 1, 0.4)
		entry_box.add_child(title_label)
		if unlocked:
			var body_label := Label.new()
			body_label.text = entry.body
			body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			body_label.custom_minimum_size = Vector2(700, 0)
			entry_box.add_child(body_label)
			if entry.sources != "":
				var src_label := Label.new()
				src_label.text = entry.sources
				src_label.modulate = Color(0.7, 0.7, 0.7, 1)
				src_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				src_label.custom_minimum_size = Vector2(700, 0)
				entry_box.add_child(src_label)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 16)
		entry_box.add_child(spacer)
		codex_list.add_child(entry_box)

func _on_codex_entry_unlocked(_entry_id: StringName) -> void:
	if codex_panel.visible:
		_refresh_codex()

func _show_toast(text: String) -> void:
	toast_label.text = text
	toast.visible = true
	_toast_remaining = 3.0

func _on_codex_unlocked_toast(entry_id: StringName) -> void:
	_show_toast("Codex unlocked: %s" % _humanize_id(entry_id))

func _on_bond_matured_toast(bond: Resource, payout: int) -> void:
	if bond:
		_show_toast("%s matured: +%dg" % [bond.display_name, payout])

func show_end_screen(victory: bool, waves_cleared: int = 0, earned: int = 0, total_waves: int = 9) -> void:
	end_label.text = "VICTORY" if victory else "DEFEAT"
	end_waves_label.text = "Waves cleared: %d / %d" % [waves_cleared, total_waves]
	end_earned_label.text = "+%d War Effort earned" % earned
	end_total_label.text = "Total War Effort: %d" % MetaProgress.war_effort_points
	end_stats_label.text = "%d kills  ·  %dg from kills  ·  %d towers placed  ·  %d bonds bought  ·  %dg from payouts" % [
		GameState.stat_kills,
		GameState.stat_gold_from_kills,
		GameState.stat_towers_placed,
		GameState.stat_bonds_purchased,
		GameState.stat_bond_payouts,
	]
	_refresh_perk_button()
	end_screen.visible = true

func _refresh_perk_button() -> void:
	var perk_id: StringName = MetaProgress.PERK_STARTING_GOLD_BONUS
	if perk_id in MetaProgress.unlocked_perks:
		end_perk_btn.text = "✓ %s (unlocked)" % MetaProgress.PERK_LABELS[perk_id]
		end_perk_btn.disabled = true
	else:
		var cost: int = MetaProgress.PERK_COSTS.get(perk_id, 0)
		end_perk_btn.text = "Buy: %s (%d WEP)" % [MetaProgress.PERK_LABELS[perk_id], cost]
		end_perk_btn.disabled = MetaProgress.war_effort_points < cost

func _on_perk_btn_pressed() -> void:
	if MetaProgress.unlock_perk(MetaProgress.PERK_STARTING_GOLD_BONUS):
		end_total_label.text = "Total War Effort: %d" % MetaProgress.war_effort_points
		_refresh_perk_button()

const _RECRUIT_ROSTER: Array[String] = [
	"res://data/towers/montgomery.tres",
	"res://data/towers/audie_murphy.tres",
	"res://data/towers/rosie.tres",
	"res://data/towers/airborne_101.tres",
	"res://data/towers/tuskegee.tres",
	"res://data/towers/fdr.tres",
	"res://data/towers/bletchley.tres",
	"res://data/towers/zhukov.tres",
	"res://data/towers/lemay.tres",
	"res://data/towers/pavlichenko.tres",
]
const _STARTING_ROSTER: Array[String] = [
	"res://data/towers/patton.tres",
	"res://data/towers/eisenhower.tres",
	"res://data/towers/churchill.tres",
	"res://data/towers/anne_frank.tres",
]

func _open_recruit_screen() -> void:
	recruit_screen.visible = true
	_refresh_recruit_screen()

func _close_recruit_screen() -> void:
	recruit_screen.visible = false

func _refresh_recruit_screen() -> void:
	recruit_wep_label.text = "War Effort: %d" % MetaProgress.war_effort_points
	for c in recruit_roster_list.get_children():
		c.queue_free()
	# Starting roster first (always unlocked, can be promoted)
	for path in _STARTING_ROSTER:
		var stats: Resource = load(path)
		if stats:
			recruit_roster_list.add_child(_build_recruit_row(stats))
	# Then the rest of the roster (locked + recruited)
	for path in _RECRUIT_ROSTER:
		var stats: Resource = load(path)
		if stats:
			recruit_roster_list.add_child(_build_recruit_row(stats))

func _build_recruit_row(stats: Resource) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)
	# Portrait
	if stats.portrait != null:
		var tex := TextureRect.new()
		tex.texture = stats.portrait
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.custom_minimum_size = Vector2(56, 56)
		hbox.add_child(tex)
	# Name + status
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
		var rank_str: String = "Rank %d / %d" % [rank, MetaProgress.MAX_RANK]
		if rank > 0:
			rank_str += "  ·  +%d%% dmg  ·  +%d%% rate" % [
				int(MetaProgress.DAMAGE_PER_RANK * rank * 100),
				int(MetaProgress.FIRE_RATE_PER_RANK * rank * 100),
			]
		status_lbl.text = rank_str
		status_lbl.modulate = Color(0.8, 1.0, 0.8, 1.0)
	else:
		status_lbl.text = "Locked"
		status_lbl.modulate = Color(1.0, 0.6, 0.6, 1.0)
	status_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(status_lbl)
	# Action button (recruit or promote)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(220, 48)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not unlocked:
		var cost: int = int(MetaProgress.RECRUIT_COSTS.get(stats.id, 0))
		btn.text = "Recruit  (%d WEP)" % cost
		btn.disabled = MetaProgress.war_effort_points < cost
		btn.pressed.connect(_on_recruit_pressed.bind(stats.id))
	elif rank >= MetaProgress.MAX_RANK:
		btn.text = "Max Rank"
		btn.disabled = true
	else:
		var cost: int = MetaProgress.next_promote_cost(stats.id)
		btn.text = "Promote to Rank %d  (%d WEP)" % [rank + 1, cost]
		btn.disabled = MetaProgress.war_effort_points < cost
		btn.pressed.connect(_on_promote_pressed.bind(stats.id))
	hbox.add_child(btn)
	return panel

func _on_recruit_pressed(figure_id: StringName) -> void:
	if MetaProgress.recruit_figure(figure_id):
		_refresh_recruit_screen()
		end_total_label.text = "Total War Effort: %d" % MetaProgress.war_effort_points

func _on_promote_pressed(figure_id: StringName) -> void:
	if MetaProgress.promote_figure(figure_id):
		_refresh_recruit_screen()
		end_total_label.text = "Total War Effort: %d" % MetaProgress.war_effort_points

func _on_restart_pressed() -> void:
	end_screen.visible = false
	_speed_idx = 0
	_apply_speed()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_restart_pressed() -> void:
	pause_overlay.visible = false
	_speed_idx = 0
	_apply_speed()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_quit_pressed() -> void:
	# No main menu yet; this is essentially "reload" which gets you back to a
	# fresh start state. (Web export can't actually close the tab.)
	pause_overlay.visible = false
	_speed_idx = 0
	_apply_speed()
	get_tree().paused = false
	get_tree().reload_current_scene()
