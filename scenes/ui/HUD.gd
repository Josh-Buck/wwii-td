extends CanvasLayer

@onready var gold_label: Label = $TopBar/GoldLabel
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var lives_label: Label = $TopBar/LivesLabel
@onready var end_screen: Control = $EndScreen
@onready var end_label: Label = $EndScreen/Panel/Label
@onready var hint_label: Label = $HintLabel

func _ready() -> void:
	end_screen.visible = false
	EventBus.gold_changed.connect(func(g): gold_label.text = "Gold: %d" % g)
	EventBus.lives_changed.connect(func(l): lives_label.text = "Lives: %d" % l)
	EventBus.wave_started.connect(func(w): wave_label.text = "Wave %d" % (w + 1))
	gold_label.text = "Gold: %d" % GameState.gold
	lives_label.text = "Lives: %d" % GameState.lives
	wave_label.text = "Wave 1"
	if hint_label:
		hint_label.text = "Click a slot to deploy. Survive 3 waves."

func show_end_screen(victory: bool) -> void:
	end_label.text = "VICTORY" if victory else "DEFEAT"
	end_screen.visible = true
