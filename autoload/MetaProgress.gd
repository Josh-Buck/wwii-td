extends Node

# Persistent across runs. Saved to user:// (IndexedDB on web).

var war_effort_points: int = 0
var unlocked_starting_figures: Array[StringName] = [&"patton"]
var unlocked_perks: Array[StringName] = []
var codex_seen: Array[StringName] = []

# Perk effects
const PERK_STARTING_GOLD_BONUS := &"starting_gold_50"
const PERK_EXTRA_WALL_SLOT := &"extra_wall_slot"

func starting_gold_bonus() -> int:
	return 50 if PERK_STARTING_GOLD_BONUS in unlocked_perks else 0

func extra_wall_slots() -> int:
	return 1 if PERK_EXTRA_WALL_SLOT in unlocked_perks else 0

func mark_codex_seen(entry_id: StringName) -> void:
	if entry_id in codex_seen:
		return
	codex_seen.append(entry_id)
	EventBus.codex_entry_unlocked.emit(entry_id)
	SaveSystem.save_async()

func award_war_effort(points: int) -> void:
	war_effort_points += points
	SaveSystem.save_async()

func spend_war_effort(points: int) -> bool:
	if war_effort_points < points:
		return false
	war_effort_points -= points
	SaveSystem.save_async()
	return true

func to_dict() -> Dictionary:
	return {
		"war_effort_points": war_effort_points,
		"unlocked_starting_figures": unlocked_starting_figures,
		"unlocked_perks": unlocked_perks,
		"codex_seen": codex_seen,
	}

func from_dict(d: Dictionary) -> void:
	war_effort_points = d.get("war_effort_points", 0)
	unlocked_starting_figures = d.get("unlocked_starting_figures", [&"patton"])
	unlocked_perks = d.get("unlocked_perks", [])
	codex_seen = d.get("codex_seen", [])
