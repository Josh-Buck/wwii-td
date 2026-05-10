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

@export_group("Lore")
@export_multiline var tooltip_lore: String = ""
@export var codex_id: StringName
