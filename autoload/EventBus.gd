extends Node

# Run / state
signal gold_changed(new_amount: int)
signal lives_changed(new_amount: int)
signal wave_started(wave_index: int)
signal wave_ended(wave_index: int)
signal run_started
signal run_ended(victory: bool)

# Combat
signal enemy_killed(enemy: Node, reward: int)
signal enemy_reached_end(enemy: Node)
signal enemy_hovered(enemy: Node)
signal enemy_unhovered(enemy: Node)

# Towers
signal tower_placed(tower: Node)
signal tower_sold(tower: Node, refund: int)
signal tower_selected(tower: Node)
signal tower_deselected
signal tower_selection_changed(stats: Resource)  ## active palette selection
signal tower_hovered(tower: Node)
signal tower_unhovered(tower: Node)
signal tower_clicked(tower: Node)  ## opens info panel

# Codex
signal codex_entry_unlocked(entry_id: StringName)
