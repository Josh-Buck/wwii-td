class_name UpgradeRegistry extends RefCounted

# All themed upgrades for each tower, hardcoded. Two branches × three tiers
# per tower. Upgrade dicts contain optional fields:
#   name, cost, desc, damage_mult, fire_rate_mult, range_mult,
#   aoe_radius_add, aura_radius_mult, aura_fire_rate_add,
#   bonus_vs_armor (mult), bonus_vs_camo (mult)
#
# Tier rule: must own previous tier in the same branch before purchasing.
# Player may purchase BOTH branches; no cap (we'll add the BTD6 "tier-3 in
# only one branch" rule once balance shakes out).

const UPGRADES: Dictionary = {
	&"patton": {
		"branch_a": {
			"name": "Armor Hunt",
			"tiers": [
				{"name": "Improved Sherman", "cost": 200,
				 "desc": "+50% damage. Patton's M4s shed their 75mm guns for high-velocity 76s.",
				 "damage_mult": 1.5},
				{"name": "76mm Upgrade", "cost": 400,
				 "desc": "+50% damage. Tungsten-core HVAP rounds defeat Panther frontal armor.",
				 "damage_mult": 1.5, "bonus_vs_armor": 1.5},
				{"name": "M26 Pershing", "cost": 800,
				 "desc": "+50% damage. AoE radius +60. The heavy tank Patton kept demanding.",
				 "damage_mult": 1.5, "aoe_radius_add": 60.0},
			],
		},
		"branch_b": {
			"name": "Blitzkrieg",
			"tiers": [
				{"name": "Forward Spirit", "cost": 150,
				 "desc": "+30% fire rate. \"Lead, follow, or get out of the way.\"",
				 "fire_rate_mult": 1.3},
				{"name": "Mobile Command", "cost": 300,
				 "desc": "+30% range. The Third Army at full operational tempo.",
				 "range_mult": 1.3},
				{"name": "Third Army Speed", "cost": 600,
				 "desc": "+50% fire rate. The Lorraine campaign — six divisions in 36 hours.",
				 "fire_rate_mult": 1.5},
			],
		},
	},
	&"eisenhower": {
		"branch_a": {
			"name": "Tactical Genius",
			"tiers": [
				{"name": "Bigger Sticks", "cost": 350,
				 "desc": "AoE radius +30. Heavy bombers re-tasked from strategic to tactical.",
				 "aoe_radius_add": 30.0},
				{"name": "Operation Husky", "cost": 700,
				 "desc": "AoE radius +40. +30% damage. The Sicily landings, 1943.",
				 "aoe_radius_add": 40.0, "damage_mult": 1.3},
				{"name": "Total Air Superiority", "cost": 1400,
				 "desc": "AoE radius +60. +50% damage. Eighth Air Force at peak.",
				 "aoe_radius_add": 60.0, "damage_mult": 1.5},
			],
		},
		"branch_b": {
			"name": "Combined Arms",
			"tiers": [
				{"name": "Faster Cycles", "cost": 350,
				 "desc": "+50% fire rate. Streamlined CAS request flow.",
				 "fire_rate_mult": 1.5},
				{"name": "Strategic Reserve", "cost": 700,
				 "desc": "+30% damage, +30% range. SHAEF's full weight behind every strike.",
				 "damage_mult": 1.3, "range_mult": 1.3},
				{"name": "D-Day Strike", "cost": 1400,
				 "desc": "+50% damage. The largest amphibious invasion in history.",
				 "damage_mult": 1.5},
			],
		},
	},
	&"churchill": {
		"branch_a": {
			"name": "Iron Lady",
			"tiers": [
				{"name": "Aura Reach", "cost": 200,
				 "desc": "+25% aura radius. The wireless reaches further.",
				 "aura_radius_mult": 1.25},
				{"name": "Speeches", "cost": 400,
				 "desc": "+25% aura radius. \"Their finest hour\" broadcast to every battery.",
				 "aura_radius_mult": 1.25},
				{"name": "We Shall Fight", "cost": 800,
				 "desc": "+30% aura radius. National morale at its peak.",
				 "aura_radius_mult": 1.3},
			],
		},
		"branch_b": {
			"name": "The Roar",
			"tiers": [
				{"name": "Stronger Voice", "cost": 200,
				 "desc": "+10% aura fire rate. \"Blood, toil, tears and sweat.\"",
				 "aura_fire_rate_add": 0.10},
				{"name": "Defiance", "cost": 400,
				 "desc": "+15% aura fire rate. The defiant 1940 stand.",
				 "aura_fire_rate_add": 0.15},
				{"name": "Their Finest Hour", "cost": 800,
				 "desc": "+25% aura fire rate. The Battle of Britain in full song.",
				 "aura_fire_rate_add": 0.25},
			],
		},
	},
	&"anne_frank": {
		"branch_a": {
			"name": "The Diary",
			"tiers": [
				{"name": "Spread the Word", "cost": 100,
				 "desc": "+25% range. Word of the achterhuis travels.",
				 "range_mult": 1.25},
				{"name": "Witnesses", "cost": 200,
				 "desc": "+25% range. Survivors and helpers add their voices.",
				 "range_mult": 1.25},
				{"name": "Voice of the Hidden", "cost": 400,
				 "desc": "+30% range. The diary in 70 languages.",
				 "range_mult": 1.30},
			],
		},
		"branch_b": {
			"name": "The Hidden",
			"tiers": [
				{"name": "Resistance Network", "cost": 100,
				 "desc": "+50% damage to camo enemies. Miep Gies and the helpers.",
				 "bonus_vs_camo": 1.5},
				{"name": "Anonymous Hands", "cost": 200,
				 "desc": "+50% damage to camo enemies. The names we never learned.",
				 "bonus_vs_camo": 1.5},
				{"name": "From the Attic", "cost": 400,
				 "desc": "+50% damage to camo enemies. +50% fire rate.",
				 "bonus_vs_camo": 1.5, "fire_rate_mult": 1.5},
			],
		},
	},
	&"montgomery": {
		"branch_a": {
			"name": "Set Piece",
			"tiers": [
				{"name": "Methodical", "cost": 200,
				 "desc": "+50% damage. Plan it. Plan it again. Then execute.",
				 "damage_mult": 1.5},
				{"name": "El Alamein", "cost": 400,
				 "desc": "+50% damage. The Eighth Army turns the desert war.",
				 "damage_mult": 1.5},
				{"name": "Crossing the Rhine", "cost": 800,
				 "desc": "+50% damage. AoE radius +30. Operation Plunder.",
				 "damage_mult": 1.5, "aoe_radius_add": 30.0},
			],
		},
		"branch_b": {
			"name": "The Plan",
			"tiers": [
				{"name": "Field Marshal", "cost": 200,
				 "desc": "+60% fire rate. The peerage and the focus.",
				 "fire_rate_mult": 1.6},
				{"name": "Operation Plunder", "cost": 400,
				 "desc": "+50% fire rate. +20% range. Across the Rhine in March '45.",
				 "fire_rate_mult": 1.5, "range_mult": 1.2},
				{"name": "21st Army Group", "cost": 800,
				 "desc": "+50% fire rate. +20% range. The full Anglo-Canadian-Polish weight.",
				 "fire_rate_mult": 1.5, "range_mult": 1.2},
			],
		},
	},
	&"pavlichenko": {
		"branch_a": {
			"name": "Belaya Smert",
			"tiers": [
				{"name": "Steady Hand", "cost": 250,
				 "desc": "+75% damage. Range training at the Kyiv military academy.",
				 "damage_mult": 1.75},
				{"name": "309 Confirmed", "cost": 500,
				 "desc": "+75% damage. The official tally at Sevastopol.",
				 "damage_mult": 1.75},
				{"name": "White Death", "cost": 1000,
				 "desc": "+100% damage. The fascists' name for her, repurposed.",
				 "damage_mult": 2.0},
			],
		},
		"branch_b": {
			"name": "Counter-sniper",
			"tiers": [
				{"name": "Spotted", "cost": 250,
				 "desc": "+60% fire rate. Patient observation, then pull.",
				 "fire_rate_mult": 1.6},
				{"name": "Pinned Down", "cost": 500,
				 "desc": "+60% fire rate. +25% range.",
				 "fire_rate_mult": 1.6, "range_mult": 1.25},
				{"name": "Behind Lines", "cost": 1000,
				 "desc": "+50% fire rate. +25% range. The 36 enemy snipers she eliminated.",
				 "fire_rate_mult": 1.5, "range_mult": 1.25},
			],
		},
	},
}

static func get_branches(tower_id: StringName) -> Dictionary:
	return UPGRADES.get(tower_id, {})

static func get_tier(tower_id: StringName, branch: StringName, tier_idx: int) -> Dictionary:
	var branches: Dictionary = UPGRADES.get(tower_id, {})
	var br: Dictionary = branches.get(branch, {})
	var tiers: Array = br.get("tiers", [])
	if tier_idx < 0 or tier_idx >= tiers.size():
		return {}
	return tiers[tier_idx]
