class_name Tower extends Node2D

@export var stats: TowerStats

const _PRIORITY_CYCLE: Array[StringName] = [
	TargetingSystem.FIRST,
	TargetingSystem.LAST,
	TargetingSystem.STRONG,
	TargetingSystem.CLOSE,
]

var targeting_mode: StringName = TargetingSystem.FIRST  ## overridden from stats in _ready
var targets_in_range: Array = []
var active_buffs: Dictionary = {}  ## adjacency tag -> source tower
var aura_buffs: Dictionary = {}    ## source tower -> {fire_rate_bonus: float}
var owning_slot: Node = null   ## set by Map on placement; cleared on sell
var hovered: bool = false   ## drives range-preview visibility in _draw
var selected: bool = false  ## set by HUD when info panel pinned to this tower
var upgrade_a_tier: int = 0  ## branch A tiers purchased (0..3)
var upgrade_b_tier: int = 0  ## branch B tiers purchased (0..3)
var total_invested: int = 0  ## base cost + all upgrade costs (for sell refund)
var _eco_timer: Timer = null
var _gold_accumulator: float = 0.0

const _PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/Projectile.tscn")

@onready var range_area: Area2D = $RangeArea
@onready var range_collision: CollisionShape2D = $RangeArea/CollisionShape2D
@onready var hover_area: Area2D = $HoverArea
@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	if stats == null:
		push_error("Tower spawned without TowerStats")
		return
	# Keep towers responsive to clicks/hovers even when the tree is paused
	# so the player can read codex / buy / sell during pause for planning.
	# Fire timer is forced PAUSABLE so towers still stop shooting on pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("towers")
	# Air units sit visually above ground towers so clicks pick them first.
	if stats.is_air_unit:
		z_index = 5
	# Drop-in animation: pop from 30% scale up to full, with a tiny overshoot.
	scale = Vector2(0.3, 0.3)
	var drop_tween := create_tween()
	drop_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	drop_tween.tween_property(self, "scale", Vector2.ONE, 0.10).set_ease(Tween.EASE_OUT)
	if stats.default_targeting != &"":
		targeting_mode = stats.default_targeting
	if stats.provides_wave_preview:
		add_to_group("wave_preview_providers")
		EventBus.tower_placed.emit(self)  ## ensure HUD refresh on first add
	if stats.gold_per_sec > 0.0:
		_eco_timer = Timer.new()
		_eco_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
		_eco_timer.wait_time = 1.0
		_eco_timer.one_shot = false
		_eco_timer.timeout.connect(_on_eco_tick)
		add_child(_eco_timer)
		_eco_timer.start()
	if stats.slow_aura_factor > 0.0 and stats.aura_radius > 0.0:
		var slow_timer := Timer.new()
		slow_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
		slow_timer.wait_time = 0.25
		slow_timer.one_shot = false
		slow_timer.timeout.connect(_on_slow_aura_tick)
		add_child(slow_timer)
		slow_timer.start()
	# Refresh fire timer periodically so enemy debuff auras (Hitler) update live.
	var refresh_timer := Timer.new()
	refresh_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	refresh_timer.wait_time = 0.4
	refresh_timer.one_shot = false
	refresh_timer.timeout.connect(_refresh_fire_timer)
	add_child(refresh_timer)
	refresh_timer.start()
	# Always assign a fresh shape per tower so range tweaks don't leak
	# across instances via a shared scene-level sub_resource.
	if range_collision:
		var shape := CircleShape2D.new()
		shape.radius = effective_range()
		range_collision.shape = shape
	fire_timer.wait_time = 1.0 / max(0.0001, effective_fire_rate())
	fire_timer.one_shot = false
	fire_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	if not fire_timer.timeout.is_connected(_on_fire_tick):
		fire_timer.timeout.connect(_on_fire_tick)
	fire_timer.start()
	range_area.body_entered.connect(_on_target_entered)
	range_area.body_exited.connect(_on_target_exited)
	range_area.area_entered.connect(_on_target_area_entered)
	range_area.area_exited.connect(_on_target_area_exited)
	hover_area.mouse_entered.connect(_on_hover_entered)
	hover_area.mouse_exited.connect(_on_hover_exited)
	hover_area.input_event.connect(_on_hover_input)
	queue_redraw()

func _on_hover_entered() -> void:
	hovered = true
	queue_redraw()
	EventBus.tower_hovered.emit(self)

func _on_hover_exited() -> void:
	hovered = false
	queue_redraw()
	EventBus.tower_unhovered.emit(self)

func _on_hover_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[Tower] click registered: ", stats.id if stats else "<no stats>")
		EventBus.tower_clicked.emit(self)

func cycle_targeting_mode() -> StringName:
	var idx := _PRIORITY_CYCLE.find(targeting_mode)
	targeting_mode = _PRIORITY_CYCLE[(idx + 1) % _PRIORITY_CYCLE.size()]
	return targeting_mode

func sell() -> void:
	if stats == null:
		queue_free()
		return
	var base_invested: int = stats.cost + total_invested
	var refund := int(base_invested * 0.75)
	if owning_slot and is_instance_valid(owning_slot) and owning_slot.has_method("clear_tower"):
		owning_slot.clear_tower()
	GameState.add_gold(refund)
	# Leave the towers group BEFORE emitting tower_sold so adjacency
	# recompute on the remaining towers doesn't see this one.
	remove_from_group("towers")
	if is_in_group("wave_preview_providers"):
		remove_from_group("wave_preview_providers")
	EventBus.tower_sold.emit(self, refund)
	queue_free()

func _refresh_fire_timer() -> void:
	if fire_timer:
		fire_timer.wait_time = 1.0 / max(0.0001, effective_fire_rate())

func _on_slow_aura_tick() -> void:
	if stats == null or stats.slow_aura_factor <= 0.0:
		return
	var r2: float = stats.aura_radius * stats.aura_radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.global_position.distance_squared_to(global_position) <= r2:
			if e.has_method("apply_slow"):
				e.apply_slow(stats.slow_aura_factor, 0.4)

func _on_eco_tick() -> void:
	if stats == null:
		return
	var rate: float = effective_gold_per_sec()
	if rate <= 0.0:
		return
	# Eco towers only earn during active waves — not while shopping or
	# while the player has the start-wave button up. Mirrors how war
	# economies actually work.
	if not GameState.wave_in_progress:
		return
	_gold_accumulator += rate
	if _gold_accumulator >= 1.0:
		var add_gold: int = int(_gold_accumulator)
		GameState.add_gold(add_gold)
		_gold_accumulator -= add_gold

func effective_gold_per_sec() -> float:
	if stats == null:
		return 0.0
	var rate: float = stats.gold_per_sec
	for step in _active_upgrade_steps():
		rate += step.get("gold_per_sec_add", 0.0)
	return rate

func _active_upgrade_steps() -> Array:
	var steps: Array = []
	if stats == null:
		return steps
	for i in upgrade_a_tier:
		var step := UpgradeRegistry.get_tier(stats.id, &"branch_a", i)
		if not step.is_empty():
			steps.append(step)
	for i in upgrade_b_tier:
		var step := UpgradeRegistry.get_tier(stats.id, &"branch_b", i)
		if not step.is_empty():
			steps.append(step)
	return steps

func effective_damage() -> float:
	if stats == null:
		return 1.0
	var dmg := stats.damage
	for step in _active_upgrade_steps():
		dmg *= step.get("damage_mult", 1.0)
	dmg *= MetaProgress.damage_bonus_for(stats.id)
	return dmg

func effective_fire_rate() -> float:
	if stats == null:
		return 1.0
	var rate := stats.fire_rate
	for step in _active_upgrade_steps():
		rate *= step.get("fire_rate_mult", 1.0)
	rate *= MetaProgress.fire_rate_bonus_for(stats.id)
	var multiplier := 1.0 + AdjacencySystem.RATE_BONUS_PER_BUFF * active_buffs.size()
	for source in aura_buffs.values():
		multiplier += source.get("fire_rate_bonus", 0.0)
	# Enemy debuff auras (e.g., Hitler) slow tower fire rate inside their radius.
	var debuff: float = _enemy_debuff_factor()
	return rate * multiplier * debuff

func _enemy_debuff_factor() -> float:
	var factor: float = 1.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.stats == null:
			continue
		if e.stats.debuff_aura_radius <= 0.0:
			continue
		if global_position.distance_squared_to(e.global_position) <= e.stats.debuff_aura_radius * e.stats.debuff_aura_radius:
			factor = min(factor, e.stats.debuff_aura_factor)
	return factor

func effective_range() -> float:
	if stats == null:
		return 100.0
	var r := stats.range_px
	for step in _active_upgrade_steps():
		r *= step.get("range_mult", 1.0)
	return r

func effective_aoe_radius() -> float:
	if stats == null:
		return 0.0
	var aoe := stats.aoe_radius
	for step in _active_upgrade_steps():
		aoe += step.get("aoe_radius_add", 0.0)
	return aoe

func effective_aura_radius() -> float:
	if stats == null:
		return 0.0
	var r := stats.aura_radius
	for step in _active_upgrade_steps():
		r *= step.get("aura_radius_mult", 1.0)
	return r

func effective_aura_fire_rate_bonus() -> float:
	if stats == null:
		return 0.0
	var b := stats.aura_fire_rate_bonus
	for step in _active_upgrade_steps():
		b += step.get("aura_fire_rate_add", 0.0)
	return b

func damage_for_target(enemy: Node) -> float:
	var dmg := effective_damage()
	if enemy and enemy.stats:
		for step in _active_upgrade_steps():
			if enemy.stats.is_armor():
				dmg *= step.get("bonus_vs_armor", 1.0)
			if enemy.stats.is_camo():
				dmg *= step.get("bonus_vs_camo", 1.0)
	return dmg

func purchase_upgrade(branch: StringName, tier_idx: int) -> bool:
	if stats == null:
		return false
	var current_tier: int = upgrade_a_tier if branch == &"branch_a" else upgrade_b_tier
	if tier_idx != current_tier:
		return false  # must purchase tiers in order
	var step := UpgradeRegistry.get_tier(stats.id, branch, tier_idx)
	if step.is_empty():
		return false
	var cost: int = step.get("cost", 0)
	if GameState.has_free_upgrade:
		GameState.has_free_upgrade = false
	elif not GameState.spend_gold(cost):
		return false
	else:
		total_invested += cost
	if branch == &"branch_a":
		upgrade_a_tier += 1
	else:
		upgrade_b_tier += 1
	if upgrade_a_tier >= 3 and upgrade_b_tier >= 3:
		MetaProgress.grant_achievement(&"fully_upgraded")
	apply_buffs()
	# Refresh the placed tower's range collision since range may have changed.
	if range_collision and range_collision.shape is CircleShape2D:
		range_collision.shape.radius = effective_range()
	queue_redraw()
	return true

func apply_buffs() -> void:
	if fire_timer:
		fire_timer.wait_time = 1.0 / max(0.0001, effective_fire_rate())
	queue_redraw()
	EventBus.tower_buffs_changed.emit(self)

func _on_target_entered(body: Node) -> void:
	if body is Enemy and not body in targets_in_range:
		targets_in_range.append(body)

func _on_target_exited(body: Node) -> void:
	targets_in_range.erase(body)

func _on_target_area_entered(area: Node) -> void:
	var p = area.get_parent()
	if p is Enemy and not p in targets_in_range:
		targets_in_range.append(p)

func _on_target_area_exited(area: Node) -> void:
	var p = area.get_parent()
	if p:
		targets_in_range.erase(p)

func _on_fire_tick() -> void:
	targets_in_range = targets_in_range.filter(func(e): return is_instance_valid(e) and not e.dead)
	if targets_in_range.is_empty():
		return
	var n: int = 1 + _effective_extra_targets()
	if n <= 1:
		var target = TargetingSystem.pick(targets_in_range, targeting_mode, global_position)
		if target == null:
			return
		_fire_at(target)
		return
	# Multi-target: fire one projectile at each of the top N targets.
	var picked := _pick_top_n_targets(n)
	for t in picked:
		_fire_at(t)

func _effective_extra_targets() -> int:
	var n: int = 0
	for step in _active_upgrade_steps():
		n += step.get("extra_targets", 0)
	return n

func _pick_top_n_targets(n: int) -> Array:
	var sorted: Array = targets_in_range.duplicate()
	match targeting_mode:
		&"first":
			sorted.sort_custom(func(a, b): return a.progress > b.progress)
		&"last":
			sorted.sort_custom(func(a, b): return a.progress < b.progress)
		&"strong":
			sorted.sort_custom(func(a, b): return a.hp > b.hp)
		&"close":
			var p: Vector2 = global_position
			sorted.sort_custom(func(a, b):
				return p.distance_squared_to(a.global_position) < p.distance_squared_to(b.global_position))
		&"camo":
			sorted.sort_custom(func(a, b):
				var ac: bool = a.has_method("is_camo") and a.is_camo()
				var bc: bool = b.has_method("is_camo") and b.is_camo()
				if ac != bc:
					return ac
				return a.progress > b.progress)
	return sorted.slice(0, min(n, sorted.size()))

func _fire_at(target: Node) -> void:
	if not is_instance_valid(target):
		return
	_spawn_muzzle_flash()
	_play_recoil(target)
	var projectile := _PROJECTILE_SCENE.instantiate()
	var opts: Dictionary = {
		"aoe": effective_aoe_radius(),
		"color": stats.color,
		"style": _projectile_style(),
		"slow_factor": _effective_slow_factor(),
		"slow_duration": _effective_slow_duration(),
		"knockback": _effective_knockback(),
		"pierce_armor": _effective_pierce_armor(),
		"instakill_below_hp": _effective_instakill_threshold(),
	}
	projectile.setup(target, damage_for_target(target), opts)
	projectile.global_position = global_position
	var container := _find_projectiles_container()
	if container:
		container.add_child(projectile)
	else:
		get_parent().add_child(projectile)

var _rest_position: Vector2 = Vector2.ZERO
var _rest_position_set: bool = false
var _recoil_tween: Tween = null

func _play_recoil(target: Node) -> void:
	if not is_instance_valid(target):
		return
	if not _rest_position_set:
		_rest_position = position
		_rest_position_set = true
	var dir: Vector2 = (global_position - target.global_position).normalized()
	var style := _projectile_style()
	var kick: float = 5.0
	match style:
		&"shell": kick = 9.0
		&"drop":  kick = 11.0
		&"laser": kick = 3.0
	if _recoil_tween and _recoil_tween.is_valid():
		_recoil_tween.kill()
	_recoil_tween = create_tween()
	_recoil_tween.set_parallel(true)
	_recoil_tween.tween_property(self, "position", _rest_position + dir * kick, 0.06)
	_recoil_tween.tween_property(self, "scale", Vector2(1.06, 0.94), 0.06)
	_recoil_tween.chain()
	_recoil_tween.tween_property(self, "position", _rest_position, 0.18).set_ease(Tween.EASE_OUT)
	_recoil_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_OUT)

func _projectile_style() -> StringName:
	if stats == null:
		return &"bullet"
	match stats.id:
		&"pavlichenko": return &"laser"   ## sniper instant beam
		&"patton": return &"shell"        ## tank shell
		&"eisenhower": return &"shell"    ## artillery
		&"airborne_101": return &"shell"  ## bazooka
		&"montgomery": return &"shell"    ## artillery
		&"zhukov": return &"shell"        ## Soviet artillery
		&"audie_murphy": return &"bullet" ## rifle
		&"lemay": return &"drop"          ## bombs
		&"b17": return &"drop"            ## bomber payload
		&"spitfire": return &"bullet"     ## .303 machine guns
		&"mustang": return &"bullet"      ## .50 cal
		&"tuskegee": return &"bullet"     ## fighter MG
	return &"bullet"

func _effective_slow_factor() -> float:
	var f: float = 1.0
	for step in _active_upgrade_steps():
		var s: float = step.get("slow_factor", 1.0)
		if s < f:
			f = s
	return f

func _effective_slow_duration() -> float:
	var d: float = 0.0
	for step in _active_upgrade_steps():
		var sd: float = step.get("slow_duration", 0.0)
		if sd > d:
			d = sd
	return d

func _effective_knockback() -> float:
	var k: float = 0.0
	for step in _active_upgrade_steps():
		k += step.get("knockback", 0.0)
	return k

func _effective_pierce_armor() -> bool:
	for step in _active_upgrade_steps():
		if step.get("pierce_armor", false):
			return true
	return false

func _effective_instakill_threshold() -> float:
	var threshold: float = 0.0
	for step in _active_upgrade_steps():
		threshold = maxf(threshold, step.get("instakill_below_hp", 0.0))
	return threshold

func _find_projectiles_container() -> Node:
	var n: Node = get_parent()
	while n:
		var c: Node = n.get_node_or_null("Projectiles")
		if c:
			return c
		n = n.get_parent()
	return null

func _spawn_muzzle_flash() -> void:
	var scene: PackedScene = preload("res://scenes/effects/FireFlash.tscn")
	var fx: Node2D = scene.instantiate()
	if stats:
		fx.setup(stats.color.lightened(0.3))
	fx.global_position = global_position
	var parent: Node = get_tree().current_scene
	if parent:
		parent.add_child(fx)

const TOWER_RADIUS: float = 30.0

func _draw() -> void:
	if stats == null:
		return
	# Air units: cast a shadow ellipse below to read as 'flying'.
	# Ground units: small sandbag-style base plate for visual weight.
	if stats.is_air_unit:
		draw_set_transform(Vector2(4, TOWER_RADIUS + 6), 0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, TOWER_RADIUS * 0.9, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		# Base plate: stacked dark ellipse + ring suggesting sandbags / earthwork.
		draw_set_transform(Vector2(0, TOWER_RADIUS + 4), 0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, TOWER_RADIUS + 4, Color(0.18, 0.16, 0.12, 0.55))
		draw_arc(Vector2.ZERO, TOWER_RADIUS + 4, 0, TAU, 24, Color(0.36, 0.30, 0.20, 0.85), 1.5)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# Range preview (drawn under everything else when hovered or selected).
	if hovered or selected:
		var r := effective_range()
		draw_circle(Vector2.ZERO, r, Color(0.85, 0.78, 0.4, 0.08))
		draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(0.95, 0.85, 0.50, 0.7), 2.0)
		# Dashed inner ring for readability.
		var dash_count: int = 32
		for i in dash_count:
			var a0: float = TAU * float(i) / dash_count
			var a1: float = a0 + TAU / dash_count * 0.5
			draw_arc(Vector2.ZERO, r - 4, a0, a1, 4, Color(0.95, 0.85, 0.50, 0.45), 1.0)
	# Selection halo: bright cyan ring + outer ring so the picked tower is obvious.
	if selected:
		draw_arc(Vector2.ZERO, TOWER_RADIUS + 4.0, 0, TAU, 32, Color(0.4, 0.9, 1.0, 0.9), 3.0)
		draw_arc(Vector2.ZERO, TOWER_RADIUS + 10.0, 0, TAU, 32, Color(0.4, 0.9, 1.0, 0.45), 2.0)
	if stats.portrait != null:
		_draw_portrait()
	else:
		# Placeholder visual: faction-colored disc with last-name initials.
		draw_circle(Vector2.ZERO, TOWER_RADIUS, stats.color)
		draw_arc(Vector2.ZERO, TOWER_RADIUS, 0, TAU, 32, stats.color.darkened(0.4), 2.0)
		_draw_initials()
	# Synergy indicator: golden ring when at least one adjacency buff is active.
	if active_buffs.size() > 0 or aura_buffs.size() > 0:
		draw_arc(Vector2.ZERO, TOWER_RADIUS + 8.0, 0, TAU, 32, Color(1.0, 0.85, 0.3, 0.85), 2.5)
	# Synergy lines to adjacency buff sources.
	for source in active_buffs.values():
		if is_instance_valid(source):
			var to_source: Vector2 = source.global_position - global_position
			draw_line(Vector2.ZERO, to_source, Color(1.0, 0.85, 0.3, 0.55), 1.5)
	# Aura projection: faint persistent ring on towers that emit auras.
	if stats.aura_radius > 0.0:
		draw_circle(Vector2.ZERO, stats.aura_radius, Color(1.0, 0.95, 0.5, 0.04))
		draw_arc(Vector2.ZERO, stats.aura_radius, 0, TAU, 64, Color(1.0, 0.95, 0.5, 0.30), 1.0)
	# Faction flag stripe always shows (over portrait or placeholder).
	_draw_flag_stripe(stats.faction)
	# Rank insignia for purchased upgrades — pips along the top edge per branch.
	_draw_rank_insignia()

func _draw_rank_insignia() -> void:
	if upgrade_a_tier == 0 and upgrade_b_tier == 0:
		return
	var y: float = -TOWER_RADIUS - 4.0
	# Branch A on the left, B on the right.
	_draw_pip_row(Vector2(-TOWER_RADIUS + 6, y), upgrade_a_tier, Color(0.95, 0.78, 0.32))
	_draw_pip_row(Vector2(TOWER_RADIUS - 6, y), upgrade_b_tier, Color(0.65, 0.85, 0.95), -1)

func _draw_pip_row(origin: Vector2, tier: int, col: Color, direction: int = 1) -> void:
	if tier <= 0:
		return
	if tier >= 3:
		# Tier 3 → star instead of pips.
		_draw_star(origin + Vector2(direction * 4, 0), 5.0, col)
		return
	var spacing: float = 5.0
	for i in tier:
		var p := origin + Vector2(direction * (i * spacing), 0)
		draw_circle(p, 2.2, Color(0, 0, 0, 0.6))
		draw_circle(p, 1.6, col)

func _draw_star(center: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a: float = -PI / 2.0 + i * PI / 5.0
		var rr: float = r if i % 2 == 0 else r * 0.45
		pts.append(center + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.7), 1.0)

func _draw_portrait() -> void:
	var tex: Texture2D = stats.portrait
	if tex == null:
		return
	var tex_size: Vector2 = tex.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	var max_dim: float = maxf(tex_size.x, tex_size.y)
	# Scale so the portrait fills the tower disc — face takes up most of the icon.
	var scale: float = (TOWER_RADIUS * 2.0) / max_dim
	var draw_size: Vector2 = tex_size * scale
	draw_texture_rect(tex, Rect2(-draw_size / 2.0, draw_size), false)
	draw_arc(Vector2.ZERO, TOWER_RADIUS + 1.0, 0, TAU, 32, stats.color.darkened(0.4), 2.0)

func _draw_initials() -> void:
	if stats == null or stats.display_name == "":
		return
	var text: String = _short_initials()
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var fs: int = 13
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	# draw_string anchors at baseline; offset y so text vertically centers near 0.
	var pos := Vector2(-size.x / 2.0, size.y / 4.0)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.08, 0.08, 0.08))

func _short_initials() -> String:
	var parts := stats.display_name.split(" ", false)
	if parts.is_empty():
		return stats.display_name.substr(0, 3).to_upper()
	return parts[-1].substr(0, 3).to_upper()

func _draw_flag_stripe(faction: StringName) -> void:
	# Small banner above the tower disc: 7px tall, 38px wide, perched above
	var x: float = -19.0
	var y: float = TOWER_RADIUS * -1.0 - 10.0
	var w: float = 38.0
	var h: float = 7.0
	match faction:
		&"us":
			# 3 horizontal stripes: red, white, blue (simplified)
			draw_rect(Rect2(x, y, w, h / 3.0), Color(0.78, 0.10, 0.16))
			draw_rect(Rect2(x, y + h / 3.0, w, h / 3.0), Color.WHITE)
			draw_rect(Rect2(x, y + 2.0 * h / 3.0, w, h / 3.0), Color(0.05, 0.13, 0.39))
		&"uk":
			# Union flag approximation: blue background, white cross, red centerline
			draw_rect(Rect2(x, y, w, h), Color(0.05, 0.13, 0.39))
			draw_rect(Rect2(x, y + h / 2.0 - 1.0, w, 2.0), Color.WHITE)
			draw_rect(Rect2(x + w / 2.0 - 1.0, y, 2.0, h), Color.WHITE)
			draw_rect(Rect2(x + w / 2.0 - 0.5, y, 1.0, h), Color(0.78, 0.10, 0.16))
		&"ussr":
			# Solid red banner
			draw_rect(Rect2(x, y, w, h), Color(0.72, 0.04, 0.04))
		&"resistance":
			# French tricolor
			draw_rect(Rect2(x, y, w / 3.0, h), Color(0.05, 0.13, 0.39))
			draw_rect(Rect2(x + w / 3.0, y, w / 3.0, h), Color.WHITE)
			draw_rect(Rect2(x + 2.0 * w / 3.0, y, w / 3.0, h), Color(0.78, 0.10, 0.16))
		_:
			pass
