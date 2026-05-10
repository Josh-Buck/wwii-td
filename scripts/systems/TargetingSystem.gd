class_name TargetingSystem extends RefCounted

# Stateless picker. Each enemy must expose:
#   progress: float        (0..1 along the path)
#   hp: float
#   global_position: Vector2
#   is_camo() -> bool

const FIRST: StringName = &"first"
const LAST: StringName = &"last"
const STRONG: StringName = &"strong"
const CLOSE: StringName = &"close"
const CAMO: StringName = &"camo"

static func pick(targets: Array, mode: StringName, from: Vector2) -> Node:
	if targets.is_empty():
		return null
	match mode:
		FIRST:
			var best: Node = targets[0]
			for e in targets:
				if e.progress > best.progress:
					best = e
			return best
		LAST:
			var best: Node = targets[0]
			for e in targets:
				if e.progress < best.progress:
					best = e
			return best
		STRONG:
			var best: Node = targets[0]
			for e in targets:
				if e.hp > best.hp:
					best = e
			return best
		CLOSE:
			var best: Node = targets[0]
			var best_d: float = from.distance_to(best.global_position)
			for e in targets:
				var d := from.distance_to(e.global_position)
				if d < best_d:
					best = e
					best_d = d
			return best
		CAMO:
			for e in targets:
				if e.has_method("is_camo") and e.is_camo():
					return e
			return targets[0]
	return targets[0]
