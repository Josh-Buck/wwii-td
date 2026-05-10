extends CanvasLayer

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var end_screen: Control = $EndScreen
@onready var end_label: Label = $EndScreen/Panel/VBox/Label
@onready var end_waves_label: Label = $EndScreen/Panel/VBox/WavesLabel
@onready var end_earned_label: Label = $EndScreen/Panel/VBox/EarnedLabel
@onready var end_total_label: Label = $EndScreen/Panel/VBox/TotalLabel
@onready var end_perk_btn: Button = $EndScreen/Panel/VBox/PerkButton
@onready var end_restart_btn: Button = $EndScreen/Panel/VBox/RestartButton
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
@onready var speed_btn: Button = $TopBar/SpeedButton
@onready var sidebar: PanelContainer = $TowerSidebar
@onready var sidebar_list: VBoxContainer = $TowerSidebar/VBox/ScrollContainer/PaletteList
@onready var sidebar_collapse_btn: Button = $TowerSidebar/VBox/HeaderRow/CollapseButton
@onready var sidebar_tab: Button = $TowerSidebarTab
@onready var wave_preview_panel: PanelContainer = $WavePreviewPanel
@onready var wave_preview_label: Label = $WavePreviewPanel/Label
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
@onready var shop_bonds_container: VBoxContainer = $ShopPanel/VBox/BondsContainer
@onready var shop_held_container: VBoxContainer = $ShopPanel/VBox/HeldContainer
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
	EventBus.wave_started.connect(func(w): wave_label.text = "Wave %d" % (w + 1))
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
	pause_overlay.visible = false
	speed_btn.pressed.connect(_cycle_speed)
	_apply_speed()
	end_perk_btn.pressed.connect(_on_perk_btn_pressed)
	end_restart_btn.pressed.connect(_on_restart_pressed)
	EventBus.map_ready.connect(_on_map_ready)
	sidebar_collapse_btn.pressed.connect(_toggle_sidebar)
	sidebar_tab.pressed.connect(_toggle_sidebar)
	def_close_btn.pressed.connect(_hide_defender_info)
	wave_preview_panel.visible = false
	EventBus.tower_placed.connect(_refresh_wave_preview_from_signal)
	EventBus.tower_sold.connect(_refresh_wave_preview_after_sell)
	EventBus.wave_started.connect(_refresh_wave_preview_after_wave)
	EventBus.wave_ended.connect(_refresh_wave_preview_after_wave)
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
		hint_label.text = "Click palette or 1-6 to pick. Click slot to deploy. Click tower to sell. Space=speed, P=pause, C=codex."
	if selection_label:
		selection_label.text = "Selected: —"

func _process(_delta: float) -> void:
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

func _on_selection_changed(stats: Resource) -> void:
	if selection_label and stats:
		selection_label.text = "Selected: %s (%dg)" % [stats.display_name, stats.cost]
	_refresh_palette_highlight(stats)

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
	btn.pressed.connect(_show_defender_info.bind(stats))

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

func _show_defender_info(stats: Resource, placed_tower: Node = null) -> void:
	if stats == null:
		return
	_info_active_stats = stats
	_info_active_tower = placed_tower if placed_tower and is_instance_valid(placed_tower) else null
	def_name.text = "%s — %dg" % [stats.display_name, stats.cost]
	def_faction.text = "Faction: %s" % _faction_label(stats.faction)
	var dps: float = stats.damage * stats.fire_rate
	var aoe_str: String = ""
	if stats.aoe_radius > 0:
		aoe_str = "  AoE r%d" % int(stats.aoe_radius)
	def_stats.text = "Damage %d  ·  Rate %.1f/s  ·  Range %d  ·  DPS %d%s" % [
		int(stats.damage), stats.fire_rate, int(stats.range_px), int(dps), aoe_str
	]
	def_hits.text = "Hits: %s   Default target: %s" % [
		_hits_text(stats.can_hit),
		_short_target_label(stats.default_targeting).replace("→ ", ""),
	]
	def_strength.text = "Strengths: %s" % _strengths_for(stats)
	def_weakness.text = "Weaknesses: %s" % _weaknesses_for(stats)
	def_lore.text = stats.tooltip_lore
	_refresh_upgrades_grid()
	def_info_panel.visible = true

func _hide_defender_info() -> void:
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

func _refresh_wave_preview_from_signal(_t: Node) -> void:
	_refresh_wave_preview()

func _refresh_wave_preview_after_sell(_t: Node, _refund: int) -> void:
	_refresh_wave_preview()

func _refresh_wave_preview_after_wave(_idx: int) -> void:
	_refresh_wave_preview()

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
	if wd.has_method("get_next_wave_summary"):
		wave_preview_label.text = "Next wave: %s" % wd.get_next_wave_summary()
		wave_preview_panel.visible = true

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
	_refresh_info_panel()
	info_panel.visible = is_instance_valid(_selected_tower)
	# Also open the defender info panel pinned to this placed tower so the
	# upgrade grid is interactive.
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
	shop_panel.visible = true

func _on_shop_next_pressed() -> void:
	shop_panel.visible = false
	EventBus.shop_closed.emit()

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

func _on_bond_matured_in_shop(_bond: Resource, _payout: int) -> void:
	if shop_panel.visible:
		_refresh_held_bonds()

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

func show_end_screen(victory: bool, waves_cleared: int = 0, earned: int = 0, total_waves: int = 9) -> void:
	end_label.text = "VICTORY" if victory else "DEFEAT"
	end_waves_label.text = "Waves cleared: %d / %d" % [waves_cleared, total_waves]
	end_earned_label.text = "+%d War Effort earned" % earned
	end_total_label.text = "Total War Effort: %d" % MetaProgress.war_effort_points
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

func _on_restart_pressed() -> void:
	end_screen.visible = false
	_speed_idx = 0
	_apply_speed()
	get_tree().paused = false
	get_tree().reload_current_scene()
