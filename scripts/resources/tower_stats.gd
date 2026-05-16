class_name TowerStats extends Resource

# Static definition of a tower / figure. Per-instance state (level, targeting
# priority, accumulated bonds) lives on the Tower node, not here.

@export var id: StringName
@export var display_name: String
@export var faction: StringName  ## &"us", &"uk", &"ussr", &"resistance"
@export var portrait: Texture2D
@export var icon: Texture2D
@export var color: Color = Color(0.8, 0.8, 0.9)  ## fallback tint for M0 placeholder draw

@export_group("Combat")
@export var cost: int = 100
@export var damage: float = 10.0
@export var fire_rate: float = 1.0  ## shots per second
@export var range_px: float = 160.0
@export var aoe_radius: float = 0.0  ## > 0 → projectile damages all enemies within this radius on impact
@export var projectile: PackedScene
@export_flags("Ground", "Air", "Armor", "Camo") var can_hit: int = 1
@export var default_targeting: StringName = &"first"  ## first / last / strong / close / camo

@export_group("Synergy")
@export var adjacency_buffs: Array[StringName] = []  ## tags this tower grants to neighbors
@export var adjacency_consumes: Array[StringName] = []  ## tags this tower benefits from
@export var aura_radius: float = 0.0  ## > 0 → tower projects an aura buff to all towers in radius
@export var aura_fire_rate_bonus: float = 0.0  ## additive multiplier (e.g., 0.15 = +15%)

@export_group("Specials")
@export var gold_per_sec: float = 0.0  ## passive eco generation while alive
@export var provides_wave_preview: bool = false  ## enables the next-wave HUD panel
@export_range(0.0, 1.0) var slow_aura_factor: float = 0.0  ## enemies in aura_radius move at this fraction of speed (0 = no slow)
@export var is_air_unit: bool = false  ## true → no ground footprint; can be placed over path and overlapping ground towers

@export_group("Hero Ability")
@export var hero_ability_id: StringName = &""  ## empty = no ability; e.g. patton_charge / churchill_finest / eisenhower_dday / pavlichenko_whitedeath
@export var hero_ability_label: String = ""    ## button label
@export var hero_ability_desc: String = ""     ## tooltip + intro text
@export var hero_ability_cooldown: float = 30.0

@export_group("Lore")
@export_multiline var tooltip_lore: String = ""
@export var codex_id: StringName
