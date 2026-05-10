class_name CodexEntry extends Resource

# Sourced historical entry. Linked to a tower or enemy via TowerStats.codex_id
# / EnemyStats.codex_id. Unlocks on first hover; persists in MetaProgress.

@export var id: StringName
@export var title: String
@export_multiline var body: String
@export var sources: String  ## one-line "Sources: ..."
