class_name WarBond extends Resource

# Real-bond style: pay cost up front, locked for `maturity_waves`,
# guaranteed `payout` when it matures. Higher tiers = better return
# but more capital tied up.

@export var id: StringName
@export var display_name: String
@export var cost: int = 100
@export var payout: int = 150
@export var maturity_waves: int = 3
@export_multiline var description: String = ""
