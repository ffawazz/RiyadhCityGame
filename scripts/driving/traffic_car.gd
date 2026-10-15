class_name TrafficCar
extends AnimatableBody3D
## An AI car that drives along one lane: keeps its distance to the car in front (and to
## the player), obeys the city's traffic lights, and loops back to the start of its lane.
## It is a solid body, so bumping into it is felt (shake + thump) like any other crash.

static var _mats: Dictionary = {}

var traffic: Traffic
var lane: Dictionary
var s: float = 0.0            # position along the lane axis
var speed: float = 0.0
var cruise: float = 15.0
var length: float = 4.6


func setup(t: Traffic, lane_data: Dictionary, start_s: float, kind: String, color: Color, cruise_speed: float) -> void:
	traffic = t
	lane = lane_data
	s = start_s
	cruise = cruise_speed
	speed = cruise_speed * 0.8
	sync_to_physics = false   # we move it from _physics_process ourselves
	_build(kind, color)
	_place(0.0)


func _physics_process(delta: float) -> void:
	var dirf := float(lane["dir"])
	var axis: int = lane["axis"]
	var target := cruise
	# --- keep distance to the car ahead in this lane ---
	var gap := 9999.0
	var ahead_speed := 0.0
	for other: TrafficCar in lane["cars"]:
		if other == self:
			continue
		var g := (other.s - s) * dirf - (other.length + length) * 0.5
		if g > -1.0 and g < gap:
			gap = g
			ahead_speed = other.speed
	# --- ... and to the player if they are ahead of us in our lane ---
	var pl := traffic.player
	if pl != null:
		var rel := Vector2(pl.position.x - position.x, pl.position.z - position.z)
		var along := (rel.x if axis == 0 else rel.y) * dirf
		var side := absf(rel.y if axis == 0 else rel.x)
		var pg := along - 2.4 - length * 0.5
		if along > 0.0 and side < 2.7 and pg < gap:
			gap = pg
			var vdir := Vector3(dirf if axis == 0 else 0.0, 0.0, dirf if axis == 1 else 0.0)
			ahead_speed = maxf(0.0, pl.velocity.dot(vdir))
	if gap < 60.0:
		if gap < 2.5:
			target = 0.0
		else:
			target = minf(target, maxf(0.0, ahead_speed + (gap - 3.0) * 0.55))
	# --- traffic lights ---
	if traffic.lights:
		for sl: float in lane["stops"]:
			var dist := (sl - s) * dirf - length * 0.5
			if dist > -0.5 and dist < 70.0 and not traffic.is_go(axis, dist, speed):
				target = minf(target, sqrt(maxf(0.0, 2.0 * 6.0 * maxf(dist - 0.8, 0.0))))
	speed = move_toward(speed, target, (3.5 if target > speed else 10.0) * delta)
	s += dirf * speed * delta
	if (dirf > 0.0 and s > float(lane["end"])) or (dirf < 0.0 and s < float(lane["start"])):
		s = float(lane["start"]) if dirf > 0.0 else float(lane["end"])
	_place(delta)


func _place(_delta: float) -> void:
	var axis: int = lane["axis"]
	var dirf := float(lane["dir"])
	var fixed: float = lane["fixed"]
	var x := s if axis == 0 else fixed
	var z := fixed if axis == 0 else s
	var yaw := 0.0
	if axis == 0:
		yaw = -PI / 2.0 if dirf > 0.0 else PI / 2.0
	else:
		yaw = PI if dirf > 0.0 else 0.0
	var gy := traffic.scene.ground_height(x, z)
	var fx := dirf if axis == 0 else 0.0
	var fz := dirf if axis == 1 else 0.0
	var front := traffic.scene.ground_height(x + fx * 1.8, z + fz * 1.8)
	var rear := traffic.scene.ground_height(x - fx * 1.8, z - fz * 1.8)
	position = Vector3(x, gy, z)
	rotation = Vector3(atan2(front - rear, 3.6), yaw, 0.0)


# ---- model ----------------------------------------------------------------------

func _build(kind: String, color: Color) -> void:
	var w := 1.8
	var body_h := 0.6
	var cabin_h := 0.55
	var cabin_len := 2.2
	var cabin_z := 0.2
	match kind:
		"suv":
			length = 4.9
			w = 2.0
			body_h = 0.8
			cabin_h = 0.7
			cabin_len = 3.1
			cabin_z = 0.35
		"pickup":
			length = 5.3
			w = 2.0
			body_h = 0.8
			cabin_h = 0.65
			cabin_len = 1.8
			cabin_z = -0.5
		"van":
			length = 5.2
			w = 2.0
			body_h = 1.5
			cabin_h = 0.5
			cabin_len = 3.6
			cabin_z = 0.2
		_:
			length = 4.6
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, body_h + cabin_h + 0.2, length)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position.y = 0.3 + shape.size.y * 0.5
	add_child(cs)
	var body := _mat(color)
	var glass := _mat(Color.html("1d2630"), 0.0, 0.2)
	var dark := _mat(Color.html("16181b"))
	_box(Vector3(w, body_h, length), Vector3(0, 0.35 + body_h * 0.5, 0), body)
	var cabin_y := 0.35 + body_h + cabin_h * 0.5
	if kind == "van":
		_box(Vector3(w * 0.98, 0.55, length * 0.7), Vector3(0, 0.35 + body_h * 0.75, 0.2), glass)   # window band
	else:
		_box(Vector3(w * 0.9, cabin_h, cabin_len), Vector3(0, cabin_y, cabin_z), glass)
		_box(Vector3(w * 0.92, 0.06, cabin_len * 0.96), Vector3(0, cabin_y + cabin_h * 0.5, cabin_z), body)   # roof
	if kind == "pickup":
		_box(Vector3(w * 0.96, 0.35, 2.0), Vector3(0, 0.35 + body_h + 0.1, 1.4), dark)               # open bed
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var wheel := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.36
			cyl.bottom_radius = 0.36
			cyl.height = 0.26
			cyl.radial_segments = 8
			wheel.mesh = cyl
			wheel.material_override = dark
			wheel.rotation_degrees.z = 90.0
			wheel.position = Vector3(sx * w * 0.5, 0.36, sz * length * 0.33)
			add_child(wheel)
	var tail := _mat(Color.html("c1121f"), 0.0, 0.4, 1.0)
	var head := _mat(Color.html("fff6d6"), 0.0, 0.3, 1.6)
	for sx: float in [-1.0, 1.0]:
		_box(Vector3(0.4, 0.14, 0.05), Vector3(sx * w * 0.36, 0.35 + body_h * 0.6, length * 0.5), tail)
		_box(Vector3(0.4, 0.14, 0.05), Vector3(sx * w * 0.36, 0.35 + body_h * 0.6, -length * 0.5), head)
	_box(Vector3(0.5, 0.12, 0.03), Vector3(0, 0.35 + body_h * 0.35, length * 0.5 + 0.02), _mat(Color.html("f4f4f0")))   # plate


func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	add_child(mi)


static func _mat(color: Color, metallic: float = 0.15, rough: float = 0.6, emission: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f_%.1f" % [color.to_html(), metallic, rough, emission]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_mats[key] = m
	return m
