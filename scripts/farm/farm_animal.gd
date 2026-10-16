class_name FarmAnimal
extends CharacterBody3D
## The player's farm avatar: a low-poly Duck, Goat or Chicken you walk around the farm
## (WASD / arrows, SPACE jumps). Speed and jump height depend on the animal.

const GRAVITY := 28.0

var kind: String = "duck"

var _model: Node3D
var _legs: Array[Node3D] = []
var _t: float = 0.0
var _speed: float = 7.0
var _jump: float = 7.5
var _mats: Dictionary = {}


func setup(animal_id: String) -> void:
	add_to_group("player")
	kind = animal_id
	match kind:
		"goat":
			_speed = 7.6
			_jump = 7.5 * float(Game.ANIMALS["goat"]["mods"]["jump"])
		"chicken":
			_speed = 8.2
			_jump = 7.0
		"cat":
			_speed = 8.8
			_jump = 7.5 * float(Game.ANIMALS["cat"]["mods"]["jump"])
		"hedgehog":
			_speed = 5.8
			_jump = 6.2
		_:
			_speed = 6.6
			_jump = 7.0


func _ready() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.55
	cap.height = 1.5
	cs.shape = cap
	cs.position.y = 0.8
	add_child(cs)
	_model = Node3D.new()
	_model.scale = Vector3.ONE * 1.35
	add_child(_model)
	match kind:
		"goat":
			_build_goat()
		"chicken":
			_build_chicken()
		"cat":
			_build_cat()
		"hedgehog":
			_build_hedgehog()
		_:
			_build_duck()


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("steer_left", "steer_right", "accelerate", "brake")
	var move := Vector3(input.x, 0.0, input.y)
	velocity.x = move.x * _speed
	velocity.z = move.z * _speed
	if is_on_floor():
		velocity.y = 0.0
		if Input.is_action_just_pressed("handbrake"):
			velocity.y = _jump
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	var moving := move.length() > 0.1
	if moving:
		var heading := atan2(-move.x, -move.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, heading, 1.0 - exp(-14.0 * delta))
		_t += delta * 13.0
	else:
		_t += delta * 2.0
	var bob := absf(sin(_t)) * 0.12 if moving and is_on_floor() else sin(_t) * 0.015
	_model.position.y = bob
	_model.rotation.z = sin(_t) * 0.12 if moving else 0.0
	for i in _legs.size():
		_legs[i].rotation.x = sin(_t + (PI if i % 2 == 1 else 0.0)) * (0.7 if moving else 0.0)


# ---- models -----------------------------------------------------------------

func _mat(hex: String) -> StandardMaterial3D:
	if _mats.has(hex):
		return _mats[hex]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html(hex)
	m.roughness = 0.85
	_mats[hex] = m
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, hex: String, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = _mat(hex)
	parent.add_child(mi)
	return mi


func _ball(parent: Node3D, radius: float, pos: Vector3, hex: String, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = 10
	sph.rings = 5
	mi.mesh = sph
	mi.position = pos
	mi.scale = scl
	mi.material_override = _mat(hex)
	parent.add_child(mi)
	return mi


func _leg(pos: Vector3, size: Vector3, hex: String) -> void:
	var pivot := Node3D.new()
	pivot.position = pos
	_model.add_child(pivot)
	_box(pivot, size, Vector3(0, -size.y * 0.5, 0), hex)
	_legs.append(pivot)


func _eyes(head: Node3D, z: float, y: float, spread: float) -> void:
	for sx: float in [-1.0, 1.0]:
		_ball(head, 0.045, Vector3(sx * spread, y, z), "151515")


func _build_duck() -> void:
	_ball(_model, 0.46, Vector3(0, 0.62, 0.05), "ffd60a", Vector3(1.0, 0.85, 1.3))
	for sx: float in [-1.0, 1.0]:
		_box(_model, Vector3(0.08, 0.3, 0.6), Vector3(sx * 0.46, 0.7, 0.12), "f4b400", Vector3(0, 0, sx * -8.0))
	_box(_model, Vector3(0.2, 0.25, 0.2), Vector3(0, 0.95, 0.6), "f4b400", Vector3(35, 0, 0))   # tail
	var head := Node3D.new()
	head.position = Vector3(0, 1.1, -0.5)
	_model.add_child(head)
	_ball(head, 0.28, Vector3.ZERO, "ffd60a")
	_box(head, Vector3(0.22, 0.08, 0.3), Vector3(0, -0.04, -0.3), "ff7b00")
	_eyes(head, -0.2, 0.08, 0.13)
	_leg(Vector3(-0.2, 0.3, 0.0), Vector3(0.12, 0.3, 0.12), "ff7b00")
	_leg(Vector3(0.2, 0.3, 0.0), Vector3(0.12, 0.3, 0.12), "ff7b00")
	_box(_model, Vector3(0.3, 0.04, 0.34), Vector3(-0.2, 0.02, -0.06), "ff7b00")
	_box(_model, Vector3(0.3, 0.04, 0.34), Vector3(0.2, 0.02, -0.06), "ff7b00")


func _build_goat() -> void:
	_box(_model, Vector3(0.7, 0.62, 1.3), Vector3(0, 0.95, 0.0), "ece7da")
	for lx: float in [-0.24, 0.24]:
		for lz: float in [-0.45, 0.45]:
			_leg(Vector3(lx, 0.65, lz), Vector3(0.14, 0.65, 0.14), "8d8574")
	var head := Node3D.new()
	head.position = Vector3(0, 1.4, -0.78)
	_model.add_child(head)
	_box(_model, Vector3(0.26, 0.5, 0.3), Vector3(0, 1.18, -0.62), "ece7da", Vector3(-20, 0, 0))   # neck
	_box(head, Vector3(0.36, 0.34, 0.5), Vector3.ZERO, "ece7da")
	_box(head, Vector3(0.28, 0.24, 0.24), Vector3(0, -0.06, -0.34), "d9d2c1")
	_box(head, Vector3(0.1, 0.18, 0.06), Vector3(0, -0.28, -0.28), "8d8574")                         # beard
	for sx: float in [-1.0, 1.0]:
		var horn := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.0
		cyl.bottom_radius = 0.06
		cyl.height = 0.36
		cyl.radial_segments = 6
		horn.mesh = cyl
		horn.position = Vector3(sx * 0.12, 0.34, 0.06)
		horn.rotation_degrees = Vector3(-20, 0, sx * -12.0)
		horn.material_override = _mat("6b5d45")
		head.add_child(horn)
		_box(head, Vector3(0.18, 0.06, 0.12), Vector3(sx * 0.26, 0.08, 0.04), "d9d2c1", Vector3(0, 0, sx * -25.0))   # ear
	_eyes(head, -0.25, 0.08, 0.14)
	_box(_model, Vector3(0.1, 0.18, 0.1), Vector3(0, 1.2, 0.68), "ece7da", Vector3(30, 0, 0))   # tail


func _build_chicken() -> void:
	_ball(_model, 0.44, Vector3(0, 0.82, 0.05), "fdfdfd", Vector3(1.0, 1.0, 1.15))
	for sx: float in [-1.0, 1.0]:
		_ball(_model, 0.2, Vector3(sx * 0.4, 0.8, 0.1), "e4e4e4", Vector3(0.3, 1.0, 1.1))
	for i in 3:
		_box(_model, Vector3(0.1, 0.5, 0.06), Vector3((i - 1) * 0.18, 1.05, 0.55), "f1f1f1", Vector3(-30, 0, (i - 1) * 18.0))   # tail feathers
	var head := Node3D.new()
	head.position = Vector3(0, 1.38, -0.4)
	_model.add_child(head)
	_ball(head, 0.21, Vector3.ZERO, "fdfdfd")
	for i in 3:
		_ball(head, 0.07, Vector3(0, 0.2 + (i % 2) * 0.02, -0.08 + i * 0.09), "e63946")
	_box(head, Vector3(0.1, 0.07, 0.16), Vector3(0, -0.02, -0.24), "ff9f1c")
	_box(head, Vector3(0.05, 0.12, 0.05), Vector3(0, -0.16, -0.2), "e63946")
	_eyes(head, -0.16, 0.07, 0.1)
	_leg(Vector3(-0.15, 0.42, 0.05), Vector3(0.06, 0.42, 0.06), "ff9f1c")
	_leg(Vector3(0.15, 0.42, 0.05), Vector3(0.06, 0.42, 0.06), "ff9f1c")


func _build_cat() -> void:
	_box(_model, Vector3(0.42, 0.42, 1.0), Vector3(0, 0.62, 0.0), "f4a259")
	for lx: float in [-0.14, 0.14]:
		for lz: float in [-0.35, 0.35]:
			_leg(Vector3(lx, 0.4, lz), Vector3(0.11, 0.4, 0.11), "c9772e")
	var head := Node3D.new()
	head.position = Vector3(0, 0.98, -0.62)
	_model.add_child(head)
	_box(head, Vector3(0.4, 0.34, 0.34), Vector3.ZERO, "f4a259")
	_box(head, Vector3(0.1, 0.07, 0.05), Vector3(0, -0.05, -0.19), "e56b6f")             # nose
	for sx: float in [-1.0, 1.0]:
		_box(head, Vector3(0.1, 0.16, 0.06), Vector3(sx * 0.14, 0.24, 0.0), "c9772e")     # ears
		_box(head, Vector3(0.3, 0.012, 0.012), Vector3(sx * 0.28, -0.04, -0.17), "ffffff")  # whiskers
	_eyes(head, -0.17, 0.05, 0.1)
	_box(_model, Vector3(0.1, 0.1, 0.8), Vector3(0, 1.0, 0.8), "f4a259", Vector3(-45, 0, 0))   # tail up
	for i in 3:
		_box(_model, Vector3(0.44, 0.05, 0.1), Vector3(0, 0.82, -0.2 + i * 0.25), "c9772e")      # stripes


func _build_hedgehog() -> void:
	_ball(_model, 0.55, Vector3(0, 0.55, 0.1), "6b4f3a", Vector3(1.0, 0.85, 1.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 26:   # quills
		var a := rng.randf() * TAU
		var e := rng.randf_range(0.2, 1.1)
		var pos := Vector3(sin(a) * 0.42, 0.55 + e * 0.3, 0.1 + cos(a) * 0.55)
		_box(_model, Vector3(0.07, 0.3, 0.07), pos + Vector3(0, 0.15, 0), "8a6a50", Vector3(sin(a) * 25.0, 0, -cos(a) * 25.0))
	var head := Node3D.new()
	head.position = Vector3(0, 0.45, -0.68)
	_model.add_child(head)
	_ball(head, 0.22, Vector3.ZERO, "e7c9a5", Vector3(1.0, 0.9, 1.2))
	_ball(head, 0.07, Vector3(0, -0.04, -0.28), "151515")                                 # nose
	_eyes(head, -0.18, 0.08, 0.1)
	_leg(Vector3(-0.22, 0.2, -0.3), Vector3(0.12, 0.2, 0.12), "e7c9a5")
	_leg(Vector3(0.22, 0.2, -0.3), Vector3(0.12, 0.2, 0.12), "e7c9a5")
	_leg(Vector3(-0.22, 0.2, 0.4), Vector3(0.12, 0.2, 0.12), "e7c9a5")
	_leg(Vector3(0.22, 0.2, 0.4), Vector3(0.12, 0.2, 0.12), "e7c9a5")
