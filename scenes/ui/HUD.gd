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

var _selected_tower: Node = null

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

func show_end_screen(victory: bool) -> void:
	end_label.text = "VICTORY" if victory else "DEFEAT"
	end_screen.visible = true
