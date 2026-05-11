extends Node

# Persistent across runs. Saved to user:// (IndexedDB on web).

var war_effort_points: int = 0
var unlocked_starting_figures: Array[StringName] = [&"patton", &"eisenhower", &"churchill", &"anne_frank", &"maginot_bunker"]
var figure_ranks: Dictionary = {}  ## StringName -> int (0..MAX_RANK)
var unlocked_perks: Array[StringName] = []
var codex_seen: Array[StringName] = []

const MAX_RANK: int = 3

# Recruit costs in War Effort points. Tiered by power level.
const RECRUIT_COSTS: Dictionary = {
	&"montgomery": 5,
	&"audie_murphy": 6,
	&"rosie": 6,
	&"airborne_101": 8,
	&"tuskegee": 8,
	&"spitfire": 9,
	&"fdr": 10,
	&"bletchley": 10,
	&"zhukov": 12,
	&"lemay": 14,
	&"mustang": 16,
	&"pavlichenko": 18,
	&"b17": 22,
}

# Per-rank promotion cost; each rank gives +8% damage, +5% fire rate.
const PROMOTE_COST_BY_RANK: Array[int] = [4, 8, 14]
const DAMAGE_PER_RANK: float = 0.08
const FIRE_RATE_PER_RANK: float = 0.05

const PERK_STARTING_GOLD_BONUS := &"starting_gold"
const PERK_EXTRA_WALL_SLOT := &"extra_wall_slot"

const PERK_COSTS: Dictionary = {
	&"starting_gold": 10,
	&"extra_wall_slot": 15,
}

const PERK_LABELS: Dictionary = {
	&"starting_gold": "+100 starting gold",
	&"extra_wall_slot": "+1 wall slot per map",
}

func starting_gold_bonus() -> int:
	return 100 if PERK_STARTING_GOLD_BONUS in unlocked_perks else 0

func extra_wall_slots() -> int:
	return 1 if PERK_EXTRA_WALL_SLOT in unlocked_perks else 0

func is_unlocked(figure_id: StringName) -> bool:
	return figure_id in unlocked_starting_figures

func rank_of(figure_id: StringName) -> int:
	return int(figure_ranks.get(figure_id, 0))

func next_promote_cost(figure_id: StringName) -> int:
	var r := rank_of(figure_id)
	if r >= MAX_RANK:
		return -1
	return PROMOTE_COST_BY_RANK[r]

func damage_bonus_for(figure_id: StringName) -> float:
	return 1.0 + DAMAGE_PER_RANK * rank_of(figure_id)

func fire_rate_bonus_for(figure_id: StringName) -> float:
	return 1.0 + FIRE_RATE_PER_RANK * rank_of(figure_id)

func recruit_figure(figure_id: StringName) -> bool:
	if is_unlocked(figure_id):
		return false
	var cost: int = int(RECRUIT_COSTS.get(figure_id, 0))
	if cost <= 0:
		return false
	if not spend_war_effort(cost):
		return false
	unlocked_starting_figures.append(figure_id)
	SaveSystem.save_async()
	return true

func promote_figure(figure_id: StringName) -> bool:
	if not is_unlocked(figure_id):
		return false
	var r := rank_of(figure_id)
	if r >= MAX_RANK:
		return false
	var cost := PROMOTE_COST_BY_RANK[r]
	if not spend_war_effort(cost):
		return false
	figure_ranks[figure_id] = r + 1
	SaveSystem.save_async()
	return true

func unlock_perk(perk_id: StringName) -> bool:
	if perk_id in unlocked_perks:
		return false
	var cost: int = PERK_COSTS.get(perk_id, 0)
	if not spend_war_effort(cost):
		return false
	unlocked_perks.append(perk_id)
	SaveSystem.save_async()
	return true

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
		"figure_ranks": figure_ranks,
		"unlocked_perks": unlocked_perks,
		"codex_seen": codex_seen,
	}

func from_dict(d: Dictionary) -> void:
	war_effort_points = d.get("war_effort_points", 0)
	unlocked_starting_figures.clear()
	for fig_id in [&"patton", &"eisenhower", &"churchill", &"anne_frank", &"maginot_bunker"]:
		unlocked_starting_figures.append(fig_id)
	var loaded_figs: Array = d.get("unlocked_starting_figures", [])
	for fig in loaded_figs:
		var sn := StringName(fig)
		if sn not in unlocked_starting_figures:
			unlocked_starting_figures.append(sn)
	figure_ranks = d.get("figure_ranks", {})
	unlocked_perks = d.get("unlocked_perks", [])
	codex_seen = d.get("codex_seen", [])
