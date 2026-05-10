class_name Stock extends Resource

# A single tradeable stock with a per-wave random walk. Price drifts by
# `drift_early` until `drift_threshold_wave` is reached, then by `drift_late`.
# That lets us model "Civilian Industries" tanking during the war and
# rebounding post-war.

@export var id: StringName
@export var display_name: String
@export var base_price: float = 100.0
@export_range(0.0, 0.5) var volatility: float = 0.10  ## std dev of pct change per wave
@export var drift_early: float = 0.02   ## mean pct change per wave (waves 1..threshold-1)
@export var drift_late: float = 0.02    ## mean pct change per wave (waves >= threshold)
@export var drift_threshold_wave: int = 0  ## wave index where drift flips
@export_multiline var description: String = ""
