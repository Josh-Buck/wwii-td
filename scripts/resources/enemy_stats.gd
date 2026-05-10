class_name EnemyStats extends Resource

@export var id: StringName
@export var display_name: String
@export var sprite: Texture2D
@export var color: Color = Color(0.7, 0.3, 0.3)  ## fallback tint for M0 placeholder draw
@export var radius: float = 14.0  ## visual + hitbox radius (M0 placeholder)

@export_group("Combat")
@export var max_hp: float = 100.0
@export var speed: float = 60.0  ## px/sec along path
@export_range(0.0, 0.95) var armor: float = 0.0  ## damage reduction multiplier
@export_flags("Ground", "Air", "Armor", "Camo") var flags: int = 1
@export var lives_lost_on_leak: int = 1

@export_group("Rewards")
@export var kill_reward: int = 5
@export var bond_reward: int = 0  ## advances War Bonds (M2)

@export_group("Lore")
@export_multiline var tooltip_lore: String = ""
@export var codex_id: StringName

func is_air() -> bool: return (flags & 2) != 0
func is_armor() -> bool: return (flags & 4) != 0
func is_camo() -> bool: return (flags & 8) != 0
