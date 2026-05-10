extends CanvasLayer

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var end_screen: Control = $EndScreen
@onready var end_label: Label = $EndScreen/Panel/Label
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
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var shop_title: Label = $ShopPanel/VBox/Title
@onready var shop_gold_label: Label = $ShopPanel/VBox/GoldLabel
@onready var shop_bonds_container: VBoxContainer = $ShopPanel/VBox/BondsContainer
@onready var shop_held_container: VBoxContainer = $ShopPanel/VBox/HeldContainer
@onready var shop_next_btn: Button = $ShopPanel/VBox/NextWaveButton

var _selected_tower: Node = null
var _shop_bonds: Array = []

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
	shop_panel.visible = false
	shop_next_btn.pressed.connect(_on_shop_next_pressed)
	EventBus.shop_opened.connect(_on_shop_opened)
	EventBus.gold_changed.connect(_on_gold_changed_for_shop)
	EventBus.bond_matured.connect(_on_bond_matured_in_shop)
	gold_label.text = "Gold: %d" % GameState.gold
	lives_label.text = "Lives: %d" % GameState.lives
	wave_label.text = "Wave 1"
	if hint_label:
		hint_label.text = "Click a slot to deploy. Press 1-4 to switch tower. Click placed towers for sell/target."
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

func _show_tooltip_for_stats(stats: Resource) -> void:
	if stats == null:
		return
	tooltip_title.text = stats.display_name
	tooltip_lore.text = stats.tooltip_lore
	tooltip.visible = true

func _on_tower_hovered(tower: Node) -> void:
	if tower and tower.stats:
		_show_tooltip_for_stats(tower.stats)

func _on_tower_unhovered(_tower: Node) -> void:
	tooltip.visible = false

func _on_enemy_hovered(enemy: Node) -> void:
	if enemy and enemy.stats:
		_show_tooltip_for_stats(enemy.stats)

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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var p := not get_tree().paused
	get_tree().paused = p
	pause_overlay.visible = p
	pause_btn.text = "Resume (P)" if p else "Pause (P)"
	EventBus.pause_toggled.emit(p)

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

func show_end_screen(victory: bool) -> void:
	end_label.text = "VICTORY" if victory else "DEFEAT"
	end_screen.visible = true
