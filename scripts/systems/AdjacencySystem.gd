class_name AdjacencySystem extends RefCounted

# Per-instance buff state lives on Tower.active_buffs.
# Recompute is called only on place / sell / upgrade — never every frame.
# A tower receives a buff for each tag in its `adjacency_consumes` that
# at least one neighboring tower exposes via `adjacency_buffs`.

const RADIUS: float = 96.0
const RATE_BONUS_PER_BUFF: float = 0.20  ## +20% fire rate per active buff

static func recompute_for_tower(t: Node) -> void:
	if not is_instance_valid(t) or t.stats == null:
		return
	t.active_buffs.clear()
	var tree := t.get_tree()
	if tree == null:
		return
	for other in tree.get_nodes_in_group("towers"):
		if other == t:
			continue
		if not is_instance_valid(other) or other.stats == null:
			continue
		if t.global_position.distance_to(other.global_position) > RADIUS:
			continue
		for tag in other.stats.adjacency_buffs:
			if tag in t.stats.adjacency_consumes:
				t.active_buffs[tag] = other
	if t.has_method("apply_buffs"):
		t.apply_buffs()

static func recompute_in_radius(center: Node) -> void:
	# Recompute the placed tower and anyone within radius of it.
	if not is_instance_valid(center):
		return
	recompute_for_tower(center)
	var tree := center.get_tree()
	if tree == null:
		return
	for other in tree.get_nodes_in_group("towers"):
		if other == center or not is_instance_valid(other):
			continue
		if center.global_position.distance_to(other.global_position) <= RADIUS:
			recompute_for_tower(other)

static func recompute_after_removal(removed_pos: Vector2, tree: SceneTree) -> void:
	# Caller must have already removed the sold tower from the "towers" group
	# (Tower.sell does this) so the iteration sees only surviving towers.
	if tree == null:
		return
	for other in tree.get_nodes_in_group("towers"):
		if not is_instance_valid(other):
			continue
		if removed_pos.distance_to(other.global_position) <= RADIUS:
			recompute_for_tower(other)
