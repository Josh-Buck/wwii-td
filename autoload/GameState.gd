extends Node

const STARTING_GOLD := 200
const STARTING_LIVES := 20

var gold: int = STARTING_GOLD
var lives: int = STARTING_LIVES
var wave_index: int = 0
var run_active: bool = false

func reset_run() -> void:
	gold = STARTING_GOLD + MetaProgress.starting_gold_bonus()
	lives = STARTING_LIVES
	wave_index = 0
	run_active = true
	EventBus.gold_changed.emit(gold)
	EventBus.lives_changed.emit(lives)
	EventBus.run_started.emit()

func add_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	EventBus.gold_changed.emit(gold)
	return true

func lose_life(amount: int = 1) -> void:
	lives = max(0, lives - amount)
	EventBus.lives_changed.emit(lives)
	if lives == 0 and run_active:
		run_active = false
		EventBus.run_ended.emit(false)

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.enemy_reached_end.connect(_on_enemy_reached_end)

func _on_enemy_killed(_enemy: Node, reward: int) -> void:
	add_gold(reward)

func _on_enemy_reached_end(_enemy: Node) -> void:
	lose_life(1)
