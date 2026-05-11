class_name EnemyStats extends Resource

@export var id: StringName
@export var display_name: String
@export var sprite: Texture2D
@export var portrait: Texture2D  ## optional portrait/photo, drawn over the sprite
@export var color: Color = Color(0.7, 0.3, 0.3)  ## fallback tint for M0 placeholder draw
@export var radius: float = 14.0  ## visual + hitbox radius (M0 placeholder)

@export_group("Combat")
@export var max_hp: float = 100.0
@export var speed: float = 60.0  ## px/sec along path
@export_range(0.0, 0.95) var armor: float = 0.0  ## damage reduction multiplier
@export_flags("Ground", "Air", "Armor", "Camo") var flags: int = 1
@export var lives_lost_on_leak: int = 1
@export var regen_per_sec: float = 0.0  ## boss/elite trait; 0 = no regen
@export var is_boss: bool = false  ## drives larger visual + boss markers
@export var escapes_at_path_end: bool = false  ## true → no life loss on leak (Mengele)
@export var summon_interval: float = 0.0   ## seconds between reinforcement spawns; 0 = none
@export var summon_enemy_id: StringName = &""  ## enemy id to summon
@export var debuff_aura_radius: float = 0.0  ## > 0 → towers within this radius fire 50% slower
@export_range(0.0, 1.0) var debuff_aura_factor: float = 0.5  ## fire-rate scalar inside the aura

@export_group("Rewards")
@export var kill_reward: int = 5
@export var bond_reward: int = 0  ## advances War Bonds (M2)

@export_group("Lore")
@export_multiline var tooltip_lore: String = ""
@export var codex_id: StringName

func is_air() -> bool: return (flags & 2) != 0
func is_armor() -> bool: return (flags & 4) != 0
func is_camo() -> bool: return (flags & 8) != 0
