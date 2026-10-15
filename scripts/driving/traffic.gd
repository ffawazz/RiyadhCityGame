class_name Traffic
extends Node3D
## Ambient traffic: AI cars on lanes, plus working traffic lights for the city grid.
## Lanes are straight; cars loop back to the start of their lane when they reach the end.
## Traffic keeps right, like in Saudi Arabia.

const CYCLE := 40.0   # seconds: east-west green, yellow, north-south green, yellow
const COLORS := ["f2f2f2", "f2f2f2", "f2f2f2", "c9ccd1", "c9ccd1", "2b2d31", "2b2d31", "7b8088", "1f3b73", "9b1c1c", "e9d8a6", "3a3f47"]
const KINDS := ["sedan", "sedan", "suv", "suv", "pickup", "van"]

var scene: DriveScene
var player: Car
var lights: bool = false
var lanes: Array = []

var _t: float = 0.0
var _rng := RandomNumberGenerator.new()
var _signal_mats: Dictionary = {}   # "ew_red" ... "ns_green" -> StandardMaterial3D


func _init(drive_scene: DriveScene) -> void:
	scene = drive_scene
	_rng.seed = 99


## axis 0 = lane runs along x (z is `fixed`), axis 1 = runs along z (x is `fixed`).
## `stops` are stop-line coordinates along the lane (city intersections).
func add_lane(axis: int, dir: int, fixed: float, start: float, end: float, stops: Array,
		cruise: float, count: int, avoid_along: Vector2 = Vector2(-1.0, -1.0)) -> void:
	var lane := {"axis": axis, "dir": dir, "fixed": fixed, "start": start, "end": end,
			"stops": stops, "cars": []}
	lanes.append(lane)
	var span := end - start
	for i in count:
		var s := start + span * (float(i) + _rng.randf_range(0.15, 0.85)) / float(count)
		if avoid_along.x >= 0.0 and s > avoid_along.x and s < avoid_along.y:
			continue
		var car := TrafficCar.new()
		scene.add_child(car)
		car.setup(self, lane, s, KINDS[_rng.randi() % KINDS.size()], Color.html(COLORS[_rng.randi() % COLORS.size()]),
				cruise * _rng.randf_range(0.9, 1.1))
		(lane["cars"] as Array).append(car)


## 0 = red, 1 = yellow, 2 = green for traffic travelling along `axis`.
func phase_state(axis: int) -> int:
	var t := fposmod(_t, CYCLE)
	if axis == 0:
		return 2 if t < 17.0 else (1 if t < 20.0 else 0)
	return 2 if (t >= 20.0 and t < 37.0) else (1 if t >= 37.0 else 0)


func is_go(axis: int, dist: float, speed: float) -> bool:
	match phase_state(axis):
		2:
			return true
		1:
			return dist < speed * 1.0   # too close to stop comfortably: keep going
	return false


func _process(delta: float) -> void:
	_t += delta
	if _signal_mats.is_empty():
		return
	for axis_name in ["ew", "ns"]:
		var st := phase_state(0 if axis_name == "ew" else 1)
		_set_lamp(axis_name + "_red", st == 0)
		_set_lamp(axis_name + "_yellow", st == 1)
		_set_lamp(axis_name + "_green", st == 2)


func _set_lamp(key: String, on: bool) -> void:
	var m: StandardMaterial3D = _signal_mats[key]
	m.emission_energy_multiplier = 3.0 if on else 0.05


## Traffic lights at every intersection of the city grid.
func build_signals(xs: Array, zs: Array, road_half: float) -> void:
	lights = true
	var colors := {"red": Color.html("ff3030"), "yellow": Color.html("ffc830"), "green": Color.html("38ff7a")}
	for axis_name in ["ew", "ns"]:
		for c: String in colors:
			var m := StandardMaterial3D.new()
			m.albedo_color = colors[c]
			m.emission_enabled = true
			m.emission = colors[c]
			m.emission_energy_multiplier = 0.05
			_signal_mats["%s_%s" % [axis_name, c]] = m
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color.html("3a3f47")
	var off := road_half + 2.2
	for x: float in xs:
		for z: float in zs:
			for corner: Vector2 in [Vector2(off, -off), Vector2(-off, off)]:
				_signal_post(Vector3(x + corner.x, 0.0, z + corner.y), pole_mat)


func _signal_post(p: Vector3, pole_mat: Material) -> void:
	var post := Node3D.new()
	post.position = p
	scene.add_child(post)
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.13
	pm.bottom_radius = 0.17
	pm.height = 5.0
	pm.radial_segments = 6
	pole.mesh = pm
	pole.position.y = 2.5
	pole.material_override = pole_mat
	post.add_child(pole)
	var housing := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.7, 2.3, 0.7)
	housing.mesh = hm
	housing.position.y = 5.6
	housing.material_override = pole_mat
	post.add_child(housing)
	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.2
	lamp_mesh.height = 0.4
	lamp_mesh.radial_segments = 6
	lamp_mesh.rings = 3
	var levels := {"red": 6.3, "yellow": 5.6, "green": 4.9}
	for face in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var axis_name := "ew" if absf(face.x) > 0.5 else "ns"
		for c: String in levels:
			var lamp := MeshInstance3D.new()
			lamp.mesh = lamp_mesh
			lamp.position = Vector3(face.x * 0.38, levels[c], face.z * 0.38)
			lamp.material_override = _signal_mats["%s_%s" % [axis_name, c]]
			post.add_child(lamp)
