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
	members.append(_person("mom", Color("1d1d22"), Color("1d1d22"), 0.93, rng))
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
	var legs := Node3D.new()
	n.add_child(legs)
	var l := _box(n, Vector3(0.22, 0.85 * h, 0.22), Vector3(-0.17, 0.42 * h, 0), Color("2b2d42") if role != "mom" else body)
	var r := _box(n, Vector3(0.22, 0.85 * h, 0.22), Vector3(0.17, 0.42 * h, 0), Color("2b2d42") if role != "mom" else body)
	_legs.append([l, r])
	_box(n, Vector3(0.7, 0.95 * h, 0.4), Vector3(0, 1.3 * h, 0), body)             # torso (thobe / abaya)
	if role == "dad" or role == "mom":
		_box(n, Vector3(0.72, 0.9 * h, 0.42), Vector3(0, 0.55 * h, 0), body)       # long robe
	_box(n, Vector3(0.14, 0.7 * h, 0.2), Vector3(-0.44, 1.3 * h, 0), body)          # arms
	_box(n, Vector3(0.14, 0.7 * h, 0.2), Vector3(0.44, 1.3 * h, 0), body)
	_box(n, Vector3(0.42, 0.42, 0.42), Vector3(0, 2.0 * h, 0), skin)                # head
	if role == "dad":
		_box(n, Vector3(0.5, 0.2, 0.5), Vector3(0, 2.3 * h, 0), Color("f8f9fa"))    # ghutra
		_box(n, Vector3(0.52, 0.06, 0.52), Vector3(0, 2.2 * h, 0), Color("111111")) # agal
	elif role == "mom":
		_box(n, Vector3(0.5, 0.52, 0.5), Vector3(0, 2.05 * h, 0.04), head_cover)    # hijab
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
