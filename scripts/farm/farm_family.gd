class_name FarmFamily
extends Node3D
## A visiting family strolling around the farm along a loop of waypoints: Dad in a white thobe,
## Mom in a black abaya, and 1-3 kids skipping behind. Purely decorative (no collision).

var path: Array[Vector2] = []
var speed: float = 1.6
var members: Array[Node3D] = []
var _leader_i: int = 0
var _trail: Array[Vector3] = []
var _t: float = 0.0
var _legs: Array = []    # [left, right] per member


func setup(waypoints: Array[Vector2], kids: int, seed_v: int, walk_speed: float = 1.6) -> void:
	path = waypoints
	speed = walk_speed
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	members.append(_person("dad", Color("f4f1ea"), Color("f4f1ea"), 1.0, rng))
	# ladies wear colourful everyday clothes on the farm (no abaya) with a matching scarf
	var mom_cols := [Color("e63946"), Color("2a9d8f"), Color("f4a261"), Color("9b5de5"), Color("ff5d8f"), Color("457b9d"), Color("e9c46a")]
	var mc: Color = mom_cols[seed_v % mom_cols.size()]
	members.append(_person("mom", mc, mc.lightened(0.35), 0.93, rng))
	var kid_cols := [Color("ef476f"), Color("ffd166"), Color("06d6a0"), Color("b388eb")]
	for i in kids:
		members.append(_person("kid", kid_cols[(seed_v + i) % 4], Color("3a2a1e"), 0.55 + 0.08 * i, rng))
	for m in members:
		add_child(m)
	position = Vector3(path[0].x, 0.0, path[0].y)
	_leader_i = 1
	for i in members.size():
		members[i].position = Vector3(-i * 1.3, 0.0, 0.0)


func _person(role: String, body: Color, head_cover: Color, h: float, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	var skin := Color("e0ac7e") if rng.randf() < 0.5 else Color("c68e5e")
	var leg_col := Color("2b2d42")
	if role == "mom":
		leg_col = Color("3d5a80")          # jeans
	# legs hang from hip pivots so they can swing when walking and bend forward when sitting
	var pair: Array = []
	for sx: float in [-0.17, 0.17]:
		var pivot := Node3D.new()
		pivot.position = Vector3(sx, 0.85 * h, 0.0)
		n.add_child(pivot)
		_box(pivot, Vector3(0.22, 0.85 * h, 0.22), Vector3(0, -0.425 * h, 0), leg_col)
		pair.append(pivot)
	_legs.append(pair)
	_box(n, Vector3(0.7, 0.95 * h, 0.4), Vector3(0, 1.3 * h, 0), body)             # torso (thobe / blouse)
	if role == "dad":
		_box(n, Vector3(0.72, 0.9 * h, 0.42), Vector3(0, 0.55 * h, 0), body)       # long thobe
	elif role == "mom":
		_box(n, Vector3(0.78, 0.5 * h, 0.44), Vector3(0, 0.78 * h, 0), body.darkened(0.12))   # knee-length dress skirt
	_box(n, Vector3(0.14, 0.7 * h, 0.2), Vector3(-0.44, 1.3 * h, 0), body)          # arms
	_box(n, Vector3(0.14, 0.7 * h, 0.2), Vector3(0.44, 1.3 * h, 0), body)
	_box(n, Vector3(0.42, 0.42, 0.42), Vector3(0, 2.0 * h, 0), skin)                # head
	if role == "dad":
		_box(n, Vector3(0.5, 0.2, 0.5), Vector3(0, 2.3 * h, 0), Color("f8f9fa"))    # ghutra
		_box(n, Vector3(0.52, 0.06, 0.52), Vector3(0, 2.2 * h, 0), Color("111111")) # agal
	elif role == "mom":
		_box(n, Vector3(0.5, 0.5, 0.5), Vector3(0, 2.05 * h, 0.04), head_cover)     # light scarf
		_box(n, Vector3(0.32, 0.2, 0.06), Vector3(0, 2.0 * h, -0.24), skin)
	else:
		_box(n, Vector3(0.46, 0.2, 0.46), Vector3(0, 2.22 * h, 0.02), head_cover)   # hair
	return n


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	mi.material_override = m
	parent.add_child(mi)
	return mi


## A family sitting round a fire on logs. `step` is the angle between neighbours (radians).
func setup_seated(center: Vector3, kids: int, seed_v: int, angle0: float, step: float, radius: float = 3.2) -> void:
	setup([Vector2(center.x, center.z), Vector2(center.x + 1.0, center.z)], kids, seed_v, 0.0)
	position = Vector3.ZERO
	path.clear()                      # no walking
	for i in members.size():
		var m := members[i]
		var a := angle0 + float(i) * step
		var p := center + Vector3(cos(a), 0.0, sin(a)) * radius
		var to := center - p
		var h: float = 1.0 if i == 0 else (0.93 if i == 1 else 0.55 + 0.08 * float(i - 2))
		m.position = Vector3(p.x, -(0.85 * h - 0.5), p.z)
		m.rotation.y = atan2(to.x, to.z)
		var pair: Array = _legs[i]
		(pair[0] as Node3D).rotation.x = -PI / 2.0
		(pair[1] as Node3D).rotation.x = -PI / 2.0
		# the log it sits on
		var log_mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.3, 0.45, 0.6)
		log_mesh.mesh = bm
		log_mesh.position = Vector3(p.x, 0.22, p.z) - Vector3(to.x, 0.0, to.z).normalized() * 0.25
		log_mesh.rotation.y = atan2(to.x, to.z)
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color("6b4423")
		log_mesh.material_override = lm
		add_child(log_mesh)


func _process(delta: float) -> void:
	if path.size() < 2:
		return
	_t += delta
	# the leader (this node) walks to the next waypoint; the others follow its trail
	var target := Vector3(path[_leader_i].x, 0.0, path[_leader_i].y)
	var to := target - position
	to.y = 0.0
	if to.length() < 0.6:
		_leader_i = (_leader_i + 1) % path.size()
	else:
		var step := to.normalized() * speed * delta
		position += step
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 1.0 - exp(-4.0 * delta))
	_trail.push_front(global_position)
	if _trail.size() > 400:
		_trail.pop_back()
	# members: leader keeps local zero offset, others sit on the trail behind
	for i in members.size():
		var m := members[i]
		var back := int(roundf(float(i) * 1.5 / maxf(speed * delta, 0.001)))
		if i == 0:
			m.position = Vector3.ZERO
		elif _trail.size() > back:
			var gp := _trail[back] + Vector3(0.0, 0.0, 0.0)
			m.global_position = gp + Vector3(sin(float(i) * 2.0) * 0.5, 0.0, 0.0)
			var ahead := _trail[maxi(0, back - 6)]
			var d := ahead - gp
			if d.length() > 0.01:
				m.rotation.y = atan2(d.x, d.z)
		var swing := sin(_t * 7.0 + float(i)) * 0.5
		var pair: Array = _legs[i]
		(pair[0] as Node3D).rotation.x = swing
		(pair[1] as Node3D).rotation.x = -swing
		m.position.y = absf(sin(_t * 7.0 + float(i))) * 0.05
