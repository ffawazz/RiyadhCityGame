class_name FarmCritter
extends Node3D
## Decorative farm animals that wander on their own: cats that dash about, hedgehogs that waddle
## (and curl into a ball when you get close), goats in their pen and hens in the coop run.
## No collision - they just add life to the farm.

var kind: String = "cat"
var bounds: Rect2 = Rect2(5, 5, 170, 130)
var avoid: Array[Rect2] = []
var speed: float = 3.0
var _target := Vector2.ZERO
var _pause: float = 0.0
var _t: float = 0.0
var _curled: float = 0.0
var _model: Node3D
var _legs: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()
var _sprint: float = 0.0


func setup(k: String, area: Rect2, seed_v: int, avoid_rects: Array[Rect2] = []) -> void:
	kind = k
	bounds = area
	avoid = avoid_rects
	_rng.seed = seed_v
	match kind:
		"cat":
			speed = 3.2
		"hedgehog":
			speed = 1.1
		"goat":
			speed = 1.0
		_:
			speed = 1.2
	position = Vector3(_rng.randf_range(area.position.x, area.end.x), 0.0, _rng.randf_range(area.position.y, area.end.y))
	_pick_target()


func _ready() -> void:
	_model = Node3D.new()
	add_child(_model)
	match kind:
		"cat":
			_build_cat()
		"hedgehog":
			_build_hedgehog()
		"goat":
			_build_goat()
		_:
			_build_hen()


func _pick_target() -> void:
	for i in 12:
		var p := Vector2(_rng.randf_range(bounds.position.x, bounds.end.x), _rng.randf_range(bounds.position.y, bounds.end.y))
		var ok := true
		for r: Rect2 in avoid:
			if r.has_point(p):
				ok = false
		if ok:
			_target = p
			return
	_target = bounds.get_center()


func _process(delta: float) -> void:
	_t += delta
	var here := Vector2(position.x, position.z)
	# hedgehogs curl up when someone comes close
	var scared := false
	if kind == "hedgehog":
		for n in get_tree().get_nodes_in_group("player"):
			if n is Node3D and (n as Node3D).global_position.distance_to(global_position) < 5.0:
				scared = true
	_curled = move_toward(_curled, 1.0 if scared else 0.0, delta * 4.0)
	_model.scale = Vector3(1.0, 1.0 - 0.25 * _curled, 1.0 - 0.3 * _curled)
	if _curled > 0.5:
		return
	if _pause > 0.0:
		_pause -= delta
		_swing_legs(0.0)
		return
	var to := _target - here
	if to.length() < 0.7:
		_pause = _rng.randf_range(0.5, 2.5) if kind != "cat" else _rng.randf_range(0.2, 1.6)
		_sprint = 0.0
		_pick_target()
		return
	var v := speed
	if kind == "cat":
		_sprint = maxf(_sprint, 1.0) if _rng.randf() < 0.01 else _sprint
		v = speed * (2.2 if _sprint > 0.0 else 1.0)
		_sprint = maxf(0.0, _sprint - delta * 0.4)
	var step := to.normalized() * v * delta
	position += Vector3(step.x, 0.0, step.y)
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.y), 1.0 - exp(-8.0 * delta))
	_swing_legs(v)
	_model.position.y = absf(sin(_t * 2.0 * v)) * 0.05 * minf(v, 3.0)


func _swing_legs(v: float) -> void:
	for i in _legs.size():
		_legs[i].rotation.x = sin(_t * 3.5 * maxf(v, 0.1) + (PI if i % 2 else 0.0)) * (0.7 if v > 0.1 else 0.0)


# ---- models -----------------------------------------------------------------

func _box(parent: Node3D, size: Vector3, pos: Vector3, hex: String, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html(hex)
	m.roughness = 0.9
	mi.material_override = m
	parent.add_child(mi)
	return mi


func _leg(pos: Vector3, size: Vector3, hex: String) -> void:
	var pivot := Node3D.new()
	pivot.position = pos
	_model.add_child(pivot)
	_box(pivot, size, Vector3(0, -size.y * 0.5, 0), hex)
	_legs.append(pivot)


func _build_cat() -> void:
	var fur: String = ["f4a259", "6c757d", "2b2d42", "f1faee", "bc6c25"][_rng.randi() % 5]
	var dark := Color.html(fur).darkened(0.3).to_html(false)
	_box(_model, Vector3(0.36, 0.34, 0.85), Vector3(0, 0.5, 0), fur)
	for lx: float in [-0.12, 0.12]:
		for lz: float in [-0.28, 0.28]:
			_leg(Vector3(lx, 0.34, lz), Vector3(0.09, 0.34, 0.09), dark)
	var head := Node3D.new()
	head.position = Vector3(0, 0.78, -0.5)
	_model.add_child(head)
	_box(head, Vector3(0.32, 0.28, 0.28), Vector3.ZERO, fur)
	for sx: float in [-1.0, 1.0]:
		_box(head, Vector3(0.08, 0.13, 0.05), Vector3(sx * 0.11, 0.2, 0.0), dark)
		_box(head, Vector3(0.05, 0.05, 0.03), Vector3(sx * 0.08, 0.04, -0.15), "ffe66d")
	_box(_model, Vector3(0.08, 0.08, 0.7), Vector3(0, 0.8, 0.62), fur, Vector3(-40, 0, 0))   # tail


func _build_hedgehog() -> void:
	var body := _box(_model, Vector3(0.6, 0.42, 0.78), Vector3(0, 0.3, 0.05), "6b4f3a")
	for i in 14:
		var a := float(i) / 14.0 * TAU
		_box(_model, Vector3(0.07, 0.22, 0.07), Vector3(sin(a) * 0.26, 0.5, 0.05 + cos(a) * 0.33), "8a6a50", Vector3(sin(a) * 30.0, 0, -cos(a) * 30.0))
	_box(_model, Vector3(0.26, 0.24, 0.3), Vector3(0, 0.26, -0.5), "e7c9a5")
	_box(_model, Vector3(0.07, 0.07, 0.07), Vector3(0, 0.26, -0.67), "151515")
	body.rotation_degrees.x = 0.0
	_leg(Vector3(-0.2, 0.14, -0.2), Vector3(0.1, 0.14, 0.1), "e7c9a5")
	_leg(Vector3(0.2, 0.14, 0.3), Vector3(0.1, 0.14, 0.1), "e7c9a5")


func _build_goat() -> void:
	_box(_model, Vector3(0.5, 0.45, 0.95), Vector3(0, 0.75, 0), "ece7da")
	for lx: float in [-0.17, 0.17]:
		for lz: float in [-0.33, 0.33]:
			_leg(Vector3(lx, 0.52, lz), Vector3(0.1, 0.52, 0.1), "8d8574")
	var head := Node3D.new()
	head.position = Vector3(0, 1.05, -0.58)
	_model.add_child(head)
	_box(head, Vector3(0.26, 0.26, 0.36), Vector3.ZERO, "ece7da")
	_box(head, Vector3(0.05, 0.14, 0.05), Vector3(-0.07, 0.2, 0.05), "6b5d45")
	_box(head, Vector3(0.05, 0.14, 0.05), Vector3(0.07, 0.2, 0.05), "6b5d45")


func _build_hen() -> void:
	var col: String = ["fdfdfd", "c1673a", "e9c46a"][_rng.randi() % 3]
	var body := _box(_model, Vector3(0.4, 0.4, 0.5), Vector3(0, 0.45, 0), col)
	body.rotation_degrees.x = -8.0
	_box(_model, Vector3(0.22, 0.24, 0.22), Vector3(0, 0.78, -0.2), col)
	_box(_model, Vector3(0.1, 0.06, 0.12), Vector3(0, 0.76, -0.36), "ff9f1c")
	_box(_model, Vector3(0.05, 0.1, 0.12), Vector3(0, 0.95, -0.2), "e63946")
	_box(_model, Vector3(0.1, 0.28, 0.06), Vector3(0, 0.62, 0.3), col, Vector3(-30, 0, 0))
	_leg(Vector3(-0.08, 0.26, 0.0), Vector3(0.04, 0.26, 0.04), "ff9f1c")
	_leg(Vector3(0.08, 0.26, 0.0), Vector3(0.04, 0.26, 0.04), "ff9f1c")
