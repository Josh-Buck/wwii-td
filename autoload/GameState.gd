extends Node

const STARTING_GOLD := 200
const STARTING_LIVES := 20

var gold: int = STARTING_GOLD
var lives: int = STARTING_LIVES
var wave_index: int = 0
var run_active: bool = false
var held_bonds: Array = []  ## each entry: {bond: WarBond, waves_remaining: int}

func reset_run() -> void:
	gold = STARTING_GOLD + MetaProgress.starting_gold_bonus()
	lives = STARTING_LIVES
	wave_index = 0
	held_bonds.clear()
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
	EventBus.wave_started.connect(_on_wave_started_for_bonds)

func buy_bond(bond: Resource) -> bool:
	if bond == null:
		return false
	if not spend_gold(bond.cost):
		return false
	held_bonds.append({"bond": bond, "waves_remaining": bond.maturity_waves})
	EventBus.bond_purchased.emit(bond)
	return true

func _on_wave_started_for_bonds(_wave_idx: int) -> void:
	var matured: Array = []
	for entry in held_bonds:
		entry.waves_remaining -= 1
		if entry.waves_remaining <= 0:
			matured.append(entry)
	for entry in matured:
		add_gold(entry.bond.payout)
		EventBus.bond_matured.emit(entry.bond, entry.bond.payout)
		held_bonds.erase(entry)

func _on_enemy_killed(_enemy: Node, reward: int) -> void:
	add_gold(reward)

func _on_enemy_reached_end(_enemy: Node) -> void:
	lose_life(1)
