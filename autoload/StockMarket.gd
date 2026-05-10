extends Node

# Per-wave random walk: each wave_started, price = price * (1 + delta)
# where delta ~ N(drift, volatility). Prices reset on run_started.

const STOCK_PATHS: Array[String] = [
	"res://data/stocks/aerospace.tres",
	"res://data/stocks/munitions.tres",
	"res://data/stocks/steel.tres",
	"res://data/stocks/civilian.tres",
]

var stocks: Array = []
var prices: Dictionary = {}        ## id -> current price (float)
var prev_prices: Dictionary = {}   ## id -> price last tick (for trend arrow)

var _rng: RandomNumberGenerator

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	for path in STOCK_PATHS:
		var s: Resource = load(path)
		if s:
			stocks.append(s)
	_reset_prices()
	EventBus.wave_started.connect(_walk_prices)
	EventBus.run_started.connect(_reset_prices)

func _reset_prices() -> void:
	prices.clear()
	prev_prices.clear()
	for s in stocks:
		prices[s.id] = s.base_price
		prev_prices[s.id] = s.base_price

func _walk_prices(wave_idx: int) -> void:
	for s in stocks:
		var drift: float = s.drift_early
		if wave_idx >= s.drift_threshold_wave and s.drift_threshold_wave > 0:
			drift = s.drift_late
		elif s.drift_threshold_wave == 0:
			drift = s.drift_early
		var delta: float = _rng.randfn(drift, s.volatility)
		prev_prices[s.id] = prices.get(s.id, s.base_price)
		var new_price: float = max(1.0, prices.get(s.id, s.base_price) * (1.0 + delta))
		prices[s.id] = new_price
	EventBus.stock_prices_walked.emit()

func get_price(stock_id: StringName) -> float:
	return prices.get(stock_id, 0.0)

func get_prev_price(stock_id: StringName) -> float:
	return prev_prices.get(stock_id, 0.0)

func get_trend_symbol(stock_id: StringName) -> String:
	var cur: float = get_price(stock_id)
	var prev: float = get_prev_price(stock_id)
	if cur > prev * 1.005:
		return "▲"
	elif cur < prev * 0.995:
		return "▼"
	return "—"
