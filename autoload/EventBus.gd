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
signal boss_escaped(boss: Node, boss_id: StringName)  ## Mengele escape mechanic
signal screen_shake(intensity: float, duration: float)  ## camera trauma in px / sec
signal boss_spawned(boss: Node, boss_id: StringName, display_name: String)  ## HUD intro card
signal combo_changed(streak: int, bonus_gold: int)  ## kill-streak combo state
signal achievement_earned(id: StringName, label: String, wep: int)
signal wave_cleared(wave_index: int, bonus_gold: int, elapsed_s: float)
signal screenshot_taken(filename: String)

# Towers
signal tower_placed(tower: Node)
signal tower_sold(tower: Node, refund: int)
signal tower_selected(tower: Node)
signal tower_deselected
signal tower_selection_changed(stats: Resource)  ## active palette selection
signal tower_hovered(tower: Node)
signal tower_unhovered(tower: Node)
signal tower_clicked(tower: Node)  ## opens info panel
signal tower_buffs_changed(tower: Node)  ## adjacency recompute applied
signal map_ready(available_towers: Array)  ## map publishes its tower list to HUD
signal tower_palette_pick(idx: int)  ## HUD tells map to switch selection

# Codex
signal codex_entry_unlocked(entry_id: StringName)

# Meta
signal pause_toggled(paused: bool)
signal shop_opened(available_bonds: Array)
signal shop_closed
signal bond_purchased(bond: Resource)
signal bond_matured(bond: Resource, payout: int)
signal stock_prices_walked  ## fired after StockMarket recomputes each wave
signal shares_changed(stock: Resource, new_count: int)

# Wave start (button-driven)
signal start_wave_requested  ## HUD asks Map to start the next wave
