extends Node

# Persistent across runs. Saved to user:// (IndexedDB on web).

var war_effort_points: int = 0
var unlocked_starting_figures: Array[StringName] = [&"patton", &"eisenhower", &"churchill", &"anne_frank", &"maginot_bunker"]
var figure_ranks: Dictionary = {}  ## StringName -> int (0..MAX_RANK)
var unlocked_perks: Array[StringName] = []
var codex_seen: Array[StringName] = []
var achievements_earned: Array[StringName] = []
var tutorial_seen: bool = false
# Lifetime stats (across all runs)
var lifetime_kills: int = 0
var lifetime_runs: int = 0
var lifetime_victories: int = 0
var lifetime_bosses_killed: int = 0
var highest_wave: int = 0
var highest_combo: int = 0
# High scores: dictionary "<map_id>_<difficulty>" -> Array[int] of top-3 scores (descending).
var high_scores: Dictionary = {}

# id -> {label, desc, wep, check}. check is evaluated at signal points.
const ACHIEVEMENTS: Dictionary = {
	&"first_blood":      {"label": "First Blood",      "desc": "Kill your first enemy.",                      "wep": 1},
	&"hundred_down":     {"label": "Hundred Down",     "desc": "Kill 100 enemies in one run.",                "wep": 3},
	&"boss_fall":        {"label": "Boss Fall",        "desc": "Defeat a named boss.",                        "wep": 5},
	&"hitler_falls":     {"label": "VE Day",           "desc": "Defeat Hitler at wave 15.",                   "wep": 20},
	&"combo_10":         {"label": "Streak x10",       "desc": "Reach a kill combo of 10.",                   "wep": 5},
	&"fully_upgraded":   {"label": "Fully Decorated",  "desc": "Fully upgrade both branches of a tower.",     "wep": 5},
	&"gold_hoarder":     {"label": "Gold Hoarder",     "desc": "Hold 2000 gold at once.",                     "wep": 4},
	&"codex_chain":      {"label": "Manhattan Read",   "desc": "Read all four Manhattan codex entries.",      "wep": 5},
	&"first_recruit":    {"label": "Roll Call",        "desc": "Recruit your first figure.",                  "wep": 2},
	&"first_promotion":  {"label": "Field Promotion",  "desc": "Promote a figure to Rank 2.",                 "wep": 3},
	&"endless_5":        {"label": "Beyond the End",   "desc": "Reach Endless +5.",                           "wep": 10},
}

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
	grant_achievement(&"first_recruit")
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
	if r + 1 >= 2:
		grant_achievement(&"first_promotion")
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
	# Manhattan codex chain achievement.
	var chain: Array[StringName] = [&"oppenheimer", &"trinity", &"hiroshima", &"nagasaki"]
	var all_seen: bool = true
	for c in chain:
		if c not in codex_seen:
			all_seen = false
			break
	if all_seen:
		grant_achievement(&"codex_chain")
	SaveSystem.save_async()

func grant_achievement(id: StringName) -> bool:
	if id in achievements_earned:
		return false
	if not ACHIEVEMENTS.has(id):
		return false
	achievements_earned.append(id)
	var entry: Dictionary = ACHIEVEMENTS[id]
	war_effort_points += int(entry.get("wep", 0))
	EventBus.achievement_earned.emit(id, entry.get("label", ""), int(entry.get("wep", 0)))
	SaveSystem.save_async()
	return true

func award_war_effort(points: int) -> void:
	war_effort_points += points
	SaveSystem.save_async()

func record_score(map_id: String, difficulty: int, score: int) -> int:
	# Stores top-3 scores for the (map, difficulty) pair. Returns the rank
	# achieved (1, 2, 3) or 0 if the score didn't break top-3.
	var key: String = "%s_%d" % [map_id, difficulty]
	var list: Array = high_scores.get(key, [])
	list.append(score)
	list.sort()
	list.reverse()
	while list.size() > 3:
		list.pop_back()
	high_scores[key] = list
	SaveSystem.save_async()
	var rank: int = list.find(score) + 1
	return rank if rank <= 3 else 0

func get_top_scores(map_id: String, difficulty: int) -> Array:
	var key: String = "%s_%d" % [map_id, difficulty]
	return high_scores.get(key, [])

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
		"achievements_earned": achievements_earned,
		"tutorial_seen": tutorial_seen,
		"lifetime_kills": lifetime_kills,
		"lifetime_runs": lifetime_runs,
		"lifetime_victories": lifetime_victories,
		"lifetime_bosses_killed": lifetime_bosses_killed,
		"highest_wave": highest_wave,
		"highest_combo": highest_combo,
		"high_scores": high_scores,
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
	achievements_earned.clear()
	for a in d.get("achievements_earned", []):
		achievements_earned.append(StringName(a))
	tutorial_seen = d.get("tutorial_seen", false)
	lifetime_kills = d.get("lifetime_kills", 0)
	lifetime_runs = d.get("lifetime_runs", 0)
	lifetime_victories = d.get("lifetime_victories", 0)
	lifetime_bosses_killed = d.get("lifetime_bosses_killed", 0)
	highest_wave = d.get("highest_wave", 0)
	highest_combo = d.get("highest_combo", 0)
	high_scores = d.get("high_scores", {})
