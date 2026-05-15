class_name UpgradeRegistry extends RefCounted

# Two themed branches × three tiers per tower. Each tier compounds with its
# branch; T1 enables T2 enables T3. Damage / fire-rate multipliers are
# tuned so a fully-upgraded tower beats spamming bases of the same gold cost,
# AND adds special effects (pierce / AoE / slow / instakill) that spam can't
# replicate.
#
# Optional fields per tier dict:
#   name, cost, desc, damage_mult, fire_rate_mult, range_mult,
#   aoe_radius_add, aura_radius_mult, aura_fire_rate_add,
#   bonus_vs_armor, bonus_vs_camo, pierce_armor, knockback,
#   slow_factor, slow_duration, instakill_below_hp, extra_targets

const UPGRADES: Dictionary = {
	&"patton": {
		"branch_a": {
			"name": "Armor Hunt",
			"tiers": [
				{"name": "Improved Sherman", "cost": 200,
				 "desc": "+75% damage. M4s shed their 75s for high-velocity 76mm guns.",
				 "damage_mult": 1.75},
				{"name": "76mm HVAP", "cost": 400,
				 "desc": "+85% damage. +75% vs armor. Pierces armor.",
				 "damage_mult": 1.85, "bonus_vs_armor": 1.75, "pierce_armor": true},
				{"name": "M26 Pershing", "cost": 800,
				 "desc": "+100% damage. AoE radius +80. The heavy tank Patton kept demanding.",
				 "damage_mult": 2.0, "aoe_radius_add": 80.0},
			],
		},
		"branch_b": {
			"name": "Blitzkrieg",
			"tiers": [
				{"name": "Forward Spirit", "cost": 150,
				 "desc": "+50% fire rate. \"Lead, follow, or get out of the way.\"",
				 "fire_rate_mult": 1.5},
				{"name": "Mobile Command", "cost": 300,
				 "desc": "+40% range. The Third Army at full operational tempo.",
				 "range_mult": 1.4},
				{"name": "Third Army Speed", "cost": 600,
				 "desc": "+75% fire rate. The Lorraine campaign — six divisions in 36 hours.",
				 "fire_rate_mult": 1.75},
			],
		},
	},
	&"eisenhower": {
		"branch_a": {
			"name": "Tactical Genius",
			"tiers": [
				{"name": "Bigger Sticks", "cost": 350,
				 "desc": "AoE radius +40. +30% damage. Heavy bombers tactical.",
				 "aoe_radius_add": 40.0, "damage_mult": 1.3},
				{"name": "Operation Husky", "cost": 700,
				 "desc": "AoE radius +60. +50% damage. The Sicily landings, 1943.",
				 "aoe_radius_add": 60.0, "damage_mult": 1.5},
				{"name": "Air Superiority", "cost": 1400,
				 "desc": "AoE radius +100. +75% damage. Eighth Air Force at peak.",
				 "aoe_radius_add": 100.0, "damage_mult": 1.75},
			],
		},
		"branch_b": {
			"name": "Combined Arms",
			"tiers": [
				{"name": "Faster Cycles", "cost": 350,
				 "desc": "+75% fire rate. Streamlined CAS request flow.",
				 "fire_rate_mult": 1.75},
				{"name": "Strategic Reserve", "cost": 700,
				 "desc": "+50% damage, +40% range. SHAEF's full weight behind every strike.",
				 "damage_mult": 1.5, "range_mult": 1.4},
				{"name": "D-Day Strike", "cost": 1400,
				 "desc": "+75% damage. AoE knocks enemies 60 px back. The largest amphibious invasion in history.",
				 "damage_mult": 1.75, "knockback": 60.0},
			],
		},
	},
	&"churchill": {
		"branch_a": {
			"name": "Iron Lady",
			"tiers": [
				{"name": "Aura Reach", "cost": 200,
				 "desc": "+35% aura radius. The wireless reaches further.",
				 "aura_radius_mult": 1.35},
				{"name": "Speeches", "cost": 400,
				 "desc": "+35% aura radius. \"Their finest hour\" broadcast to every battery.",
				 "aura_radius_mult": 1.35},
				{"name": "We Shall Fight", "cost": 800,
				 "desc": "+50% aura radius. National morale at its peak.",
				 "aura_radius_mult": 1.5},
			],
		},
		"branch_b": {
			"name": "The Roar",
			"tiers": [
				{"name": "Stronger Voice", "cost": 200,
				 "desc": "+15% aura fire rate. \"Blood, toil, tears and sweat.\"",
				 "aura_fire_rate_add": 0.15},
				{"name": "Defiance", "cost": 400,
				 "desc": "+20% aura fire rate. The defiant 1940 stand.",
				 "aura_fire_rate_add": 0.20},
				{"name": "Their Finest Hour", "cost": 800,
				 "desc": "+35% aura fire rate. The Battle of Britain in full song.",
				 "aura_fire_rate_add": 0.35},
			],
		},
	},
	&"anne_frank": {
		"branch_a": {
			"name": "The Diary",
			"tiers": [
				{"name": "Spread the Word", "cost": 100,
				 "desc": "+30% range. +50% damage. Word of the achterhuis travels.",
				 "range_mult": 1.30, "damage_mult": 1.5},
				{"name": "Witnesses", "cost": 200,
				 "desc": "+30% range. +50% damage. Survivors and helpers add their voices.",
				 "range_mult": 1.30, "damage_mult": 1.5},
				{"name": "Voice of the Hidden", "cost": 400,
				 "desc": "+40% range. +75% damage. The diary in 70 languages.",
				 "range_mult": 1.40, "damage_mult": 1.75},
			],
		},
		"branch_b": {
			"name": "The Hidden",
			"tiers": [
				{"name": "Resistance Network", "cost": 100,
				 "desc": "+100% damage to camo enemies. Miep Gies and the helpers.",
				 "bonus_vs_camo": 2.0},
				{"name": "Anonymous Hands", "cost": 200,
				 "desc": "+75% damage to camo enemies. +50% fire rate. The names we never learned.",
				 "bonus_vs_camo": 1.75, "fire_rate_mult": 1.5},
				{"name": "From the Attic", "cost": 400,
				 "desc": "+75% damage to camo enemies. +75% fire rate.",
				 "bonus_vs_camo": 1.75, "fire_rate_mult": 1.75},
			],
		},
	},
	&"montgomery": {
		"branch_a": {
			"name": "Set Piece",
			"tiers": [
				{"name": "Methodical", "cost": 200,
				 "desc": "+75% damage. Plan it. Plan it again. Then execute.",
				 "damage_mult": 1.75},
				{"name": "El Alamein", "cost": 400,
				 "desc": "+85% damage. The Eighth Army turns the desert war.",
				 "damage_mult": 1.85},
				{"name": "Crossing the Rhine", "cost": 800,
				 "desc": "+100% damage. AoE radius +50. Operation Plunder.",
				 "damage_mult": 2.0, "aoe_radius_add": 50.0},
			],
		},
		"branch_b": {
			"name": "The Plan",
			"tiers": [
				{"name": "Field Marshal", "cost": 200,
				 "desc": "+75% fire rate. The peerage and the focus.",
				 "fire_rate_mult": 1.75},
				{"name": "Operation Plunder", "cost": 400,
				 "desc": "+60% fire rate. +30% range. Across the Rhine in March '45.",
				 "fire_rate_mult": 1.6, "range_mult": 1.3},
				{"name": "21st Army Group", "cost": 800,
				 "desc": "+60% fire rate. +30% range. The full Anglo-Canadian-Polish weight.",
				 "fire_rate_mult": 1.6, "range_mult": 1.3},
			],
		},
	},
	&"pavlichenko": {
		"branch_a": {
			"name": "Belaya Smert",
			"tiers": [
				{"name": "Steady Hand", "cost": 250,
				 "desc": "+85% damage. Range training at the Kyiv military academy.",
				 "damage_mult": 1.85},
				{"name": "309 Confirmed", "cost": 500,
				 "desc": "+85% damage. The official tally at Sevastopol.",
				 "damage_mult": 1.85},
				{"name": "White Death", "cost": 1000,
				 "desc": "+100% damage. Instantly kills targets below 80 HP.",
				 "damage_mult": 2.0, "instakill_below_hp": 80.0},
			],
		},
		"branch_b": {
			"name": "Counter-sniper",
			"tiers": [
				{"name": "Spotted", "cost": 250,
				 "desc": "+75% fire rate. Patient observation, then pull.",
				 "fire_rate_mult": 1.75},
				{"name": "Pinned Down", "cost": 500,
				 "desc": "+60% fire rate. +30% range. Slows targets to 40% speed for 2.5s.",
				 "fire_rate_mult": 1.6, "range_mult": 1.3,
				 "slow_factor": 0.4, "slow_duration": 2.5},
				{"name": "Behind Lines", "cost": 1000,
				 "desc": "+50% fire rate. +30% range. Hits 3 extra targets per shot.",
				 "fire_rate_mult": 1.5, "range_mult": 1.3, "extra_targets": 3},
			],
		},
	},
	&"audie_murphy": {
		"branch_a": {
			"name": "To Hell and Back",
			"tiers": [
				{"name": "Battle Hardened", "cost": 200,
				 "desc": "+85% damage. The most-decorated US soldier of the war.",
				 "damage_mult": 1.85},
				{"name": "Holtzwihr Stand", "cost": 400,
				 "desc": "+85% damage. +50% fire rate. Single-handed against six tanks.",
				 "damage_mult": 1.85, "fire_rate_mult": 1.5},
				{"name": "Medal of Honor", "cost": 800,
				 "desc": "+100% damage. AoE +40. Pierces armor.",
				 "damage_mult": 2.0, "aoe_radius_add": 40.0, "pierce_armor": true},
			],
		},
		"branch_b": {
			"name": "Veteran",
			"tiers": [
				{"name": "Trigger Pull", "cost": 200,
				 "desc": "+75% fire rate.",
				 "fire_rate_mult": 1.75},
				{"name": "Held Lines", "cost": 400,
				 "desc": "+60% fire rate. +30% range.",
				 "fire_rate_mult": 1.6, "range_mult": 1.3},
				{"name": "Last Man Up", "cost": 800,
				 "desc": "+60% fire rate. Instakills enemies below 80 HP.",
				 "fire_rate_mult": 1.6, "instakill_below_hp": 80.0},
			],
		},
	},
	&"fdr": {
		"branch_a": {
			"name": "New Deal",
			"tiers": [
				{"name": "WPA", "cost": 150,
				 "desc": "+2 gold/sec. Recovery, relief, reform.",
				 "gold_per_sec_add": 2.0},
				{"name": "Lend-Lease", "cost": 300,
				 "desc": "+3 gold/sec. Materiel to UK and USSR before US entry.",
				 "gold_per_sec_add": 3.0},
				{"name": "Four Freedoms", "cost": 600,
				 "desc": "+5 gold/sec. The 1941 message to Congress.",
				 "gold_per_sec_add": 5.0},
			],
		},
		"branch_b": {
			"name": "Fireside Chats",
			"tiers": [
				{"name": "Confidence", "cost": 200,
				 "desc": "+30% aura fire rate to nearby US towers.",
				 "aura_fire_rate_add": 0.30, "aura_radius_mult": 1.0},
				{"name": "Day of Infamy", "cost": 400,
				 "desc": "+25% aura range.",
				 "aura_radius_mult": 1.25},
				{"name": "Arsenal of Democracy", "cost": 800,
				 "desc": "+25% aura fire rate. +25% aura range.",
				 "aura_fire_rate_add": 0.25, "aura_radius_mult": 1.25},
			],
		},
	},
	&"bletchley": {
		"branch_a": {
			"name": "Hut 8",
			"tiers": [
				{"name": "Bombe Speed", "cost": 200,
				 "desc": "+50% aura fire rate radius. The Bombe machines crank faster.",
				 "aura_radius_mult": 1.5},
				{"name": "Enigma Cracked", "cost": 400,
				 "desc": "+40% aura fire rate to nearby towers.",
				 "aura_fire_rate_add": 0.40},
				{"name": "Ultra Intelligence", "cost": 800,
				 "desc": "+40% aura fire rate. +50% aura range.",
				 "aura_fire_rate_add": 0.40, "aura_radius_mult": 1.5},
			],
		},
		"branch_b": {
			"name": "The Codebreakers",
			"tiers": [
				{"name": "Banburismus", "cost": 200,
				 "desc": "Reveals 2 waves ahead (already revealed 1).",
				 "extra_wave_preview": 1},
				{"name": "Tunny", "cost": 400,
				 "desc": "Reveals 3 waves ahead.",
				 "extra_wave_preview": 2},
				{"name": "Colossus", "cost": 800,
				 "desc": "Reveals 4 waves ahead. The world's first electronic computer.",
				 "extra_wave_preview": 3},
			],
		},
	},
	&"airborne_101": {
		"branch_a": {
			"name": "Screaming Eagles",
			"tiers": [
				{"name": "Bazooka Teams", "cost": 250,
				 "desc": "+85% damage. Pierces armor.",
				 "damage_mult": 1.85, "pierce_armor": true},
				{"name": "Carentan", "cost": 500,
				 "desc": "+75% damage. AoE +30.",
				 "damage_mult": 1.75, "aoe_radius_add": 30.0},
				{"name": "Bastogne Stand", "cost": 1000,
				 "desc": "+100% damage. AoE +50. \"NUTS!\"",
				 "damage_mult": 2.0, "aoe_radius_add": 50.0},
			],
		},
		"branch_b": {
			"name": "Pathfinders",
			"tiers": [
				{"name": "Drop Zone", "cost": 200,
				 "desc": "+75% fire rate.",
				 "fire_rate_mult": 1.75},
				{"name": "Market Garden", "cost": 400,
				 "desc": "+60% fire rate. +30% range.",
				 "fire_rate_mult": 1.6, "range_mult": 1.3},
				{"name": "Eagle's Nest", "cost": 800,
				 "desc": "+60% fire rate. Knocks enemies 40 px back.",
				 "fire_rate_mult": 1.6, "knockback": 40.0},
			],
		},
	},
	&"zhukov": {
		"branch_a": {
			"name": "Steamroller",
			"tiers": [
				{"name": "Deep Battle", "cost": 250,
				 "desc": "+85% damage. Soviet operational doctrine.",
				 "damage_mult": 1.85},
				{"name": "Bagration", "cost": 500,
				 "desc": "+85% damage. AoE +40. Army Group Centre destroyed.",
				 "damage_mult": 1.85, "aoe_radius_add": 40.0},
				{"name": "Berlin Offensive", "cost": 1000,
				 "desc": "+100% damage. AoE +60. Pierces armor.",
				 "damage_mult": 2.0, "aoe_radius_add": 60.0, "pierce_armor": true},
			],
		},
		"branch_b": {
			"name": "Stalingrad",
			"tiers": [
				{"name": "Defense in Depth", "cost": 250,
				 "desc": "+50% fire rate. +30% range.",
				 "fire_rate_mult": 1.5, "range_mult": 1.3},
				{"name": "Uranus", "cost": 500,
				 "desc": "+60% fire rate. Slows enemies hit (60% speed, 2s).",
				 "fire_rate_mult": 1.6, "slow_factor": 0.6, "slow_duration": 2.0},
				{"name": "Operation Mars", "cost": 1000,
				 "desc": "+75% fire rate. Slows hit enemies to 40% for 2.5s.",
				 "fire_rate_mult": 1.75, "slow_factor": 0.4, "slow_duration": 2.5},
			],
		},
	},
	&"rosie": {
		"branch_a": {
			"name": "Industry",
			"tiers": [
				{"name": "Swing Shift", "cost": 150,
				 "desc": "+2 gold/sec. \"We Can Do It!\"",
				 "gold_per_sec_add": 2.0},
				{"name": "Liberty Ships", "cost": 300,
				 "desc": "+3 gold/sec. One every four days at Kaiser Yards.",
				 "gold_per_sec_add": 3.0},
				{"name": "Arsenal of Democracy", "cost": 600,
				 "desc": "+5 gold/sec.",
				 "gold_per_sec_add": 5.0},
			],
		},
		"branch_b": {
			"name": "Solidarity",
			"tiers": [
				{"name": "Union Hall", "cost": 200,
				 "desc": "+30% aura fire rate.",
				 "aura_fire_rate_add": 0.30},
				{"name": "Riveters", "cost": 400,
				 "desc": "+30% aura range.",
				 "aura_radius_mult": 1.30},
				{"name": "Six Million Strong", "cost": 800,
				 "desc": "+25% aura fire rate. +30% aura range.",
				 "aura_fire_rate_add": 0.25, "aura_radius_mult": 1.30},
			],
		},
	},
	&"lemay": {
		"branch_a": {
			"name": "Strategic Bombing",
			"tiers": [
				{"name": "Tight Formation", "cost": 350,
				 "desc": "+75% damage. AoE +30.",
				 "damage_mult": 1.75, "aoe_radius_add": 30.0},
				{"name": "Incendiaries", "cost": 700,
				 "desc": "+75% damage. AoE +50.",
				 "damage_mult": 1.75, "aoe_radius_add": 50.0},
				{"name": "March 1945", "cost": 1400,
				 "desc": "+100% damage. AoE +80. The Tokyo firebombing.",
				 "damage_mult": 2.0, "aoe_radius_add": 80.0},
			],
		},
		"branch_b": {
			"name": "Twentieth Air Force",
			"tiers": [
				{"name": "B-29 Range", "cost": 350,
				 "desc": "+50% range. +30% fire rate.",
				 "range_mult": 1.5, "fire_rate_mult": 1.3},
				{"name": "Pathfinder", "cost": 700,
				 "desc": "+50% damage. +40% range.",
				 "damage_mult": 1.5, "range_mult": 1.4},
				{"name": "Saturation", "cost": 1400,
				 "desc": "+75% fire rate. Knocks enemies 50 px back.",
				 "fire_rate_mult": 1.75, "knockback": 50.0},
			],
		},
	},
	&"tuskegee": {
		"branch_a": {
			"name": "Red Tails",
			"tiers": [
				{"name": "Escort Honor", "cost": 200,
				 "desc": "+85% damage. The bomber crews who asked for them by name.",
				 "damage_mult": 1.85},
				{"name": "332nd Fighter Group", "cost": 400,
				 "desc": "+85% damage. +30% range.",
				 "damage_mult": 1.85, "range_mult": 1.3},
				{"name": "Distinguished Unit", "cost": 800,
				 "desc": "+100% damage. AoE +40.",
				 "damage_mult": 2.0, "aoe_radius_add": 40.0},
			],
		},
		"branch_b": {
			"name": "Double V",
			"tiers": [
				{"name": "Cadet Training", "cost": 200,
				 "desc": "+75% fire rate.",
				 "fire_rate_mult": 1.75},
				{"name": "Anzio", "cost": 400,
				 "desc": "+60% fire rate. +30% range.",
				 "fire_rate_mult": 1.6, "range_mult": 1.3},
				{"name": "Lonely Eagles", "cost": 800,
				 "desc": "+60% fire rate. Pierces armor.",
				 "fire_rate_mult": 1.6, "pierce_armor": true},
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
