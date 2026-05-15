class_name Weather extends Node2D

# Simple ambient particle system — snow on Ardennes, leaves on Normandy.
# Cheap CPU-side; no GPU particles; ~80 sprites continuously.

@export var style: StringName = &"normandy"  ## normandy | ardennes
@export var count: int = 80

var _particles: Array = []  ## {pos: Vector2, vel: Vector2, size: float, rot: float, omega: float}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	z_index = 50
	_rng.randomize()
	for i in count:
		_particles.append(_spawn(true))

func _process(delta: float) -> void:
	for p in _particles:
		p.pos += p.vel * delta
		p.rot += p.omega * delta
		# Wrap or respawn off-screen.
		if p.pos.y > 740.0 or p.pos.x < -20.0 or p.pos.x > 1300.0:
			var fresh: Dictionary = _spawn(false)
			p.pos = fresh.pos
			p.vel = fresh.vel
			p.size = fresh.size
			p.rot = fresh.rot
			p.omega = fresh.omega
	queue_redraw()

func _spawn(initial: bool) -> Dictionary:
	# Distribute initial particles across the full screen; respawns enter at top.
	var y: float
	if initial:
		y = _rng.randf_range(-40.0, 720.0)
	else:
		y = _rng.randf_range(-40.0, -10.0)
	var x: float = _rng.randf_range(-20.0, 1300.0)
	var size: float = _rng.randf_range(1.5, 3.5)
	if style == &"ardennes":
		var vy: float = _rng.randf_range(30.0, 70.0)
		var vx: float = _rng.randf_range(-12.0, 12.0)
		return {"pos": Vector2(x, y), "vel": Vector2(vx, vy), "size": size, "rot": 0.0, "omega": 0.0}
	# Normandy: leaves drift slower, rotate
	var vy_n: float = _rng.randf_range(18.0, 42.0)
	var vx_n: float = _rng.randf_range(-30.0, 30.0)
	return {
		"pos": Vector2(x, y), "vel": Vector2(vx_n, vy_n),
		"size": size, "rot": _rng.randf_range(0.0, TAU),
		"omega": _rng.randf_range(-1.5, 1.5),
	}

func _draw() -> void:
	if style == &"ardennes":
		var col := Color(0.96, 0.98, 1.0, 0.85)
		for p in _particles:
			draw_circle(p.pos, p.size, col)
		return
	# Normandy: small leaf-shaped triangle
	var leaf_col := Color(0.45, 0.36, 0.18, 0.75)
	for p in _particles:
		var s: float = p.size * 1.6
		var ang: float = p.rot
		var tip := p.pos + Vector2(cos(ang), sin(ang)) * s
		var left := p.pos + Vector2(cos(ang + 2.4), sin(ang + 2.4)) * s * 0.6
		var right := p.pos + Vector2(cos(ang - 2.4), sin(ang - 2.4)) * s * 0.6
		draw_colored_polygon(PackedVector2Array([tip, left, right]), leaf_col)
