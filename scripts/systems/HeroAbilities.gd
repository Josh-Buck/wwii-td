class_name HeroAbilities extends RefCounted

# Static dispatcher for per-tower hero abilities. Towers with stats.hero_ability_id
# set are "heroes"; their info panel shows an Activate Ability button that fires
# the matching handler below.

static func activate(ability_id: StringName, source: Node) -> bool:
	match ability_id:
		&"patton_charge":     return _patton_charge(source)
		&"churchill_finest":  return _churchill_finest(source)
		&"eisenhower_dday":   return _eisenhower_dday(source)
		&"pavlichenko_whitedeath": return _pavlichenko_whitedeath(source)
	return false

static func _patton_charge(source: Node) -> bool:
	# All Pattons on the field get +100% fire rate for 5 s. Encourages stacking.
	var tree: SceneTree = source.get_tree()
	var n: int = 0
	for t in tree.get_nodes_in_group("towers"):
		if not is_instance_valid(t) or t.stats == null:
			continue
		if t.stats.id == &"patton":
			t.apply_temp_buff(2.0, 5.0)
			n += 1
	EventBus.screen_shake.emit(5.0, 0.3)
	return n > 0

static func _churchill_finest(source: Node) -> bool:
	# All UK towers +50% fire rate for 10 s. "Their finest hour."
	var tree: SceneTree = source.get_tree()
	var n: int = 0
	for t in tree.get_nodes_in_group("towers"):
		if not is_instance_valid(t) or t.stats == null:
			continue
		if t.stats.faction == &"uk":
			t.apply_temp_buff(1.5, 10.0)
			n += 1
	return n > 0

static func _eisenhower_dday(source: Node) -> bool:
	# Big AoE strike at this Eisenhower's current target (or in front of him).
	var center: Vector2 = source.global_position
	if source.current_target and is_instance_valid(source.current_target):
		center = source.current_target.global_position
	var r: float = 140.0
	var dmg: float = 350.0
	var r2: float = r * r
	for e in source.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.global_position.distance_squared_to(center) <= r2:
			if e.has_method("take_damage"):
				e.take_damage(dmg, true)
	# Visual: piggyback the bombing-run telegraph by spawning an impact spark.
	var spark_scene: PackedScene = preload("res://scenes/effects/ImpactSpark.tscn")
	for i in 5:
		var sp: Node2D = spark_scene.instantiate()
		sp.setup(Color(1.0, 0.7, 0.3))
		var angle: float = i * TAU / 5.0
		sp.global_position = center + Vector2(cos(angle), sin(angle)) * r * 0.4
		source.get_tree().current_scene.add_child(sp)
	EventBus.screen_shake.emit(18.0, 0.7)
	AudioMan.play(&"fire_drop", 4.0)
	return true

static func _pavlichenko_whitedeath(source: Node) -> bool:
	# Next 5 shots are guaranteed pierce-armor + 2× damage. Source flag.
	source.crit_shots_remaining = 5
	return true
