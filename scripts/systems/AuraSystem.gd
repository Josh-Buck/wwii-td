class_name AuraSystem extends RefCounted

# Aura towers project a radial buff to every tower in range, regardless of
# faction. Distinct from AdjacencySystem (which is faction-tag-matched at a
# fixed 96px). Recompute on place/sell only — never every frame.

static func recompute_for_tower(t: Node) -> void:
	if not is_instance_valid(t) or t.stats == null:
		return
	t.aura_buffs.clear()
	var tree := t.get_tree()
	if tree == null:
		return
	for other in tree.get_nodes_in_group("towers"):
		if other == t:
			continue
		if not is_instance_valid(other) or other.stats == null:
			continue
		if other.stats.aura_radius <= 0.0:
			continue
		if t.global_position.distance_to(other.global_position) > other.stats.aura_radius:
			continue
		if other.stats.aura_fire_rate_bonus > 0.0:
			t.aura_buffs[other] = {"fire_rate_bonus": other.stats.aura_fire_rate_bonus}
	if t.has_method("apply_buffs"):
		t.apply_buffs()

static func recompute_in_radius(center: Node) -> void:
	if not is_instance_valid(center):
		return
	var tree := center.get_tree()
	if tree == null:
		return
	# Find the largest aura radius in play so we know how far to scan.
	var max_aura: float = 0.0
	for tw in tree.get_nodes_in_group("towers"):
		if is_instance_valid(tw) and tw.stats != null:
			max_aura = maxf(max_aura, tw.stats.aura_radius)
	recompute_for_tower(center)
	for other in tree.get_nodes_in_group("towers"):
		if other == center or not is_instance_valid(other):
			continue
		if center.global_position.distance_to(other.global_position) <= max_aura:
			recompute_for_tower(other)

static func recompute_after_removal(removed_pos: Vector2, removed_aura_radius: float, tree: SceneTree) -> void:
	if tree == null:
		return
	var max_aura: float = removed_aura_radius
	for tw in tree.get_nodes_in_group("towers"):
		if is_instance_valid(tw) and tw.stats != null:
			max_aura = maxf(max_aura, tw.stats.aura_radius)
	for other in tree.get_nodes_in_group("towers"):
		if not is_instance_valid(other):
			continue
		if removed_pos.distance_to(other.global_position) <= max_aura:
			recompute_for_tower(other)
