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
@onready var palette_container: HBoxContainer = $TowerPalette

const _SPEED_CYCLE: Array[float] = [1.0, 2.0, 4.0]
var _speed_idx: int = 0
var _palette_towers: Array = []
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
	"res://data/codex/wehrmacht_infantry.tres",
	"res://data/codex/panzer_iii.tres",
	"res://data/codex/stuka.tres",
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
	for c in palette_container.get_children():
		c.queue_free()
	for i in towers.size():
		var stats = towers[i]
		var btn := Button.new()
		btn.text = "%d: %s\n%dg" % [i + 1, _short_figure_name(stats.display_name), stats.cost]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.modulate = stats.color.lerp(Color.WHITE, 0.5)
		btn.flat = true
		var idx := i
		btn.pressed.connect(func(): EventBus.tower_palette_pick.emit(idx))
		palette_container.add_child(btn)

func _refresh_palette_highlight(active_stats: Resource) -> void:
	for i in palette_container.get_child_count():
		var btn := palette_container.get_child(i) as Button
		if btn == null:
			continue
		if i < _palette_towers.size() and _palette_towers[i] == active_stats:
			btn.flat = false
		else:
			btn.flat = true

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
		_show_tooltip_for_stats(tower.stats)
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
		row.theme_override_constants_separation = 12
		var label := Label.new()
		label.text = "%s — pay %dg, receive %dg in %d waves" % [
			bond.display_name, bond.cost, bond.payout, bond.maturity_waves
		]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.text = "Buy %dg" % bond.cost
		btn.disabled = bond.cost > GameState.gold
		btn.pressed.connect(_make_buy_callback(bond))
		row.add_child(label)
		row.add_child(btn)
		shop_bonds_container.add_child(row)
	shop_gold_label.text = "Gold: %d   Lives: %d" % [GameState.gold, GameState.lives]

func _make_buy_callback(bond: Resource) -> Callable:
	return func(): _on_buy_bond(bond)

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

func show_end_screen(victory: bool, waves_cleared: int = 0, earned: int = 0) -> void:
	end_label.text = "VICTORY" if victory else "DEFEAT"
	end_waves_label.text = "Waves cleared: %d / 8" % waves_cleared
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
