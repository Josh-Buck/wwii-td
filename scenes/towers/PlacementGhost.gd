class_name PlacementGhost extends Node2D

var stats: Resource = null
var is_valid: bool = true

const RADIUS: float = 30.0

func _process(_delta: float) -> void:
	# Ghost follows the mouse; we need every-frame redraws so the synergy
	# lines and validity ring track the cursor.
	queue_redraw()

func set_stats(s: Resource) -> void:
	stats = s
	queue_redraw()

func set_valid(v: bool) -> void:
	if is_valid != v:
		is_valid = v
		queue_redraw()

func _draw() -> void:
	if stats == null:
		return
	var base_color: Color = stats.color
	var fill: Color = base_color
	fill.a = 0.45
	if not is_valid:
		fill = Color(1.0, 0.25, 0.25, 0.45)
	draw_circle(Vector2.ZERO, RADIUS, fill)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, base_color.darkened(0.4), 2.0)
	# Range preview ring
	var range_color: Color = Color(1, 1, 1, 0.55)
	if not is_valid:
		range_color = Color(1, 0.4, 0.4, 0.55)
	draw_arc(Vector2.ZERO, stats.range_px, 0, TAU, 64, range_color, 1.5)
	# Aura preview ring (for aura towers)
	if stats.aura_radius > 0:
		draw_arc(Vector2.ZERO, stats.aura_radius, 0, TAU, 64, Color(1, 0.95, 0.5, 0.40), 1.0)
	# Synergy preview: faint gold lines to existing same-faction towers in
	# adjacency range, so the player can plan synergy clusters.
	if not stats.adjacency_consumes.is_empty():
		var adj_r: float = AdjacencySystem.RADIUS
		for tw in get_tree().get_nodes_in_group("towers"):
			if not is_instance_valid(tw) or tw.stats == null:
				continue
			var dist: float = global_position.distance_to(tw.global_position)
			if dist > adj_r:
				continue
			# Same-faction match: stats' consumes tag is in the other's buffs
			var matches: bool = false
			for tag in stats.adjacency_consumes:
				if tag in tw.stats.adjacency_buffs:
					matches = true
					break
			if matches:
				var to_other: Vector2 = tw.global_position - global_position
				draw_line(Vector2.ZERO, to_other, Color(1.0, 0.85, 0.30, 0.55), 1.5)
	if not is_valid:
		draw_line(Vector2(-12, -12), Vector2(12, 12), Color(1, 0.2, 0.2), 3.0)
		draw_line(Vector2(-12, 12), Vector2(12, -12), Color(1, 0.2, 0.2), 3.0)
	# Cost label above the ghost — colored red if unaffordable.
	var font: Font = ThemeDB.fallback_font
	if font:
		var cost_text: String = "%dg" % stats.cost
		var can_afford: bool = GameState.gold >= stats.cost
		var col: Color = Color(1.0, 0.9, 0.4) if can_afford else Color(1.0, 0.35, 0.35)
		var fs: int = 13
		var size: Vector2 = font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var pos := Vector2(-size.x / 2.0, -RADIUS - 12.0)
		draw_string(font, pos + Vector2(1, 1), cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.7))
		draw_string(font, pos, cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
