extends Node

const STARTING_GOLD := 200
const STARTING_LIVES := 20

var gold: int = STARTING_GOLD
var lives: int = STARTING_LIVES
var wave_index: int = 0
var run_active: bool = false
var wave_in_progress: bool = false  ## true between wave_started and wave_ended
var held_bonds: Array = []  ## each entry: {bond: WarBond, waves_remaining: int}
var held_shares: Dictionary = {}  ## stock id -> count
var has_free_upgrade: bool = false  ## roguelike shop: consume on next upgrade
var free_tower_pending: StringName = &""  ## roguelike shop: free placement queued
var manhattan_used: bool = false  ## true after the player uses the Manhattan Project once
var manhattan_penalty: bool = false  ## halves WEP earned this run if true

# Kill-streak combo: chained kills within COMBO_WINDOW grant escalating bonus gold.
const COMBO_WINDOW: float = 1.5
const COMBO_BONUS_PER_TIER: int = 1
var _combo_count: int = 0
var _combo_last_time: float = 0.0

# Per-run statistics (reset on reset_run, displayed on end screen)
var stat_kills: int = 0
var stat_gold_from_kills: int = 0
var stat_bonds_purchased: int = 0
var stat_bond_payouts: int = 0
var stat_towers_placed: int = 0

func reset_run() -> void:
	gold = STARTING_GOLD + MetaProgress.starting_gold_bonus()
	lives = STARTING_LIVES
	wave_index = 0
	held_bonds.clear()
	held_shares.clear()
	has_free_upgrade = false
	free_tower_pending = &""
	manhattan_used = false
	manhattan_penalty = false
	stat_kills = 0
	stat_gold_from_kills = 0
	stat_bonds_purchased = 0
	stat_bond_payouts = 0
	stat_towers_placed = 0
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
	EventBus.wave_started.connect(_on_wave_started_track_index)
	EventBus.wave_ended.connect(_on_wave_ended_track_inprogress)
	EventBus.tower_placed.connect(_on_tower_placed_stats)
	EventBus.bond_purchased.connect(_on_bond_purchased_stats)
	EventBus.bond_matured.connect(_on_bond_matured_stats)

func _on_tower_placed_stats(_t: Node) -> void:
	stat_towers_placed += 1

func _on_bond_purchased_stats(_b: Resource) -> void:
	stat_bonds_purchased += 1

func _on_bond_matured_stats(_b: Resource, payout: int) -> void:
	stat_bond_payouts += payout

func _on_wave_started_track_index(idx: int) -> void:
	wave_index = idx
	wave_in_progress = true

func _on_wave_ended_track_inprogress(_idx: int) -> void:
	wave_in_progress = false

func buy_bond(bond: Resource) -> bool:
	if bond == null:
		return false
	if not spend_gold(bond.cost):
		return false
	held_bonds.append({"bond": bond, "waves_remaining": bond.maturity_waves})
	EventBus.bond_purchased.emit(bond)
	return true

func buy_bond_resource(bond: Resource) -> bool:
	return buy_bond(bond)

func buy_shares(stock: Resource, count: int) -> bool:
	if stock == null or count <= 0:
		return false
	var price: float = StockMarket.get_price(stock.id)
	var cost: int = int(ceilf(price * count))
	if not spend_gold(cost):
		return false
	held_shares[stock.id] = held_shares.get(stock.id, 0) + count
	EventBus.shares_changed.emit(stock, held_shares[stock.id])
	return true

func sell_shares(stock: Resource, count: int) -> bool:
	if stock == null or count <= 0:
		return false
	var current: int = held_shares.get(stock.id, 0)
	if current < count:
		return false
	var price: float = StockMarket.get_price(stock.id)
	var proceeds: int = int(price * count)
	held_shares[stock.id] = current - count
	add_gold(proceeds)
	EventBus.shares_changed.emit(stock, held_shares[stock.id])
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
	# Combo: chain kills inside COMBO_WINDOW grant +N bonus gold where N is
	# the new streak count. Streak resets when the window expires.
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _combo_last_time <= COMBO_WINDOW:
		_combo_count += 1
	else:
		_combo_count = 1
	_combo_last_time = now
	var bonus: int = 0
	if _combo_count >= 2:
		bonus = (_combo_count - 1) * COMBO_BONUS_PER_TIER
	add_gold(reward + bonus)
	stat_kills += 1
	stat_gold_from_kills += reward + bonus
	EventBus.combo_changed.emit(_combo_count, bonus)

func _on_enemy_reached_end(_enemy: Node) -> void:
	lose_life(1)
