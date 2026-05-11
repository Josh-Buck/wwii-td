class_name ShopRoller extends RefCounted

# Generates random one-time offers for the between-round shop. Three cards
# per visit, one reroll allowed (25g). Offer kinds:
#   - free_tower:  free placement of a random unlocked figure
#   - gold_grant:  instant gold injection
#   - free_upgrade: next upgrade purchase is free
#   - bond_deal:   special bond with better cost/payout ratio
#
# Each offer is a Dictionary that the HUD renders as a card. Activation
# logic also lives here so the HUD just dispatches by type.

const REROLL_COST: int = 25

static func roll_offers(wave_idx: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = _build_pool(wave_idx)
	pool.shuffle()
	var out: Array = []
	for i in min(3, pool.size()):
		out.append(pool[i])
	return out

static func _build_pool(wave_idx: int) -> Array:
	var pool: Array = []
	# Gold grants scale with current wave so they stay relevant late.
	var gold_amt: int = 100 + wave_idx * 25
	pool.append({
		"type": "gold_grant",
		"payload": gold_amt,
		"label": "Emergency Loan",
		"desc": "+%dg immediately. No interest, no questions." % gold_amt,
	})
	pool.append({
		"type": "free_upgrade",
		"payload": null,
		"label": "Field Promotion",
		"desc": "Your next tower upgrade is free (one use).",
	})
	# Two free-tower options drawn from unlocked figures.
	var unlocked: Array = []
	for fig_id in MetaProgress.unlocked_starting_figures:
		unlocked.append(fig_id)
	unlocked.shuffle()
	for fig_id in unlocked.slice(0, 2):
		pool.append({
			"type": "free_tower",
			"payload": fig_id,
			"label": "Volunteer: %s" % _figure_name(fig_id),
			"desc": "Free placement of %s. Click to deploy." % _figure_name(fig_id),
		})
	# Special bond — better ratio than the standard shelf.
	pool.append({
		"type": "bond_deal",
		"payload": {"cost": 150, "payout": 280, "maturity": 3, "name": "Liberty Bond"},
		"label": "Liberty Bond",
		"desc": "150g now → 280g in 3 waves (+87% vs the standard +50%).",
	})
	return pool

static func _figure_name(figure_id: StringName) -> String:
	var path := "res://data/towers/%s.tres" % String(figure_id)
	var res: Resource = load(path)
	if res and res.has_method("get") and "display_name" in res:
		return res.display_name
	return String(figure_id).capitalize()

static func activate(offer: Dictionary) -> bool:
	# Mutates GameState directly. Returns true if the offer was successfully
	# claimed (consumed by the player); the HUD removes it from the row on true.
	match offer.get("type", ""):
		"gold_grant":
			var amt: int = int(offer.get("payload", 0))
			GameState.add_gold(amt)
			return true
		"free_upgrade":
			GameState.has_free_upgrade = true
			return true
		"free_tower":
			GameState.free_tower_pending = offer.get("payload", &"")
			return true
		"bond_deal":
			var d: Dictionary = offer.get("payload", {})
			var bond := _build_bond_from_dict(d)
			if bond == null:
				return false
			if not GameState.buy_bond_resource(bond):
				return false
			return true
	return false

static func _build_bond_from_dict(d: Dictionary) -> Resource:
	var bond: Resource = load("res://scripts/resources/war_bond.gd").new()
	bond.display_name = d.get("name", "Special Bond")
	bond.cost = int(d.get("cost", 100))
	bond.payout = int(d.get("payout", 150))
	bond.maturity_waves = int(d.get("maturity", 3))
	return bond
