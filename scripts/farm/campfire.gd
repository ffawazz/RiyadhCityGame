class_name Campfire
extends Node3D
## A cosy campfire: ring of stones, crossed logs, flickering flames, a warm light and rising sparks.

var _flames: Array[MeshInstance3D] = []
var _light: OmniLight3D
var _t: float = 0.0


func _ready() -> void:
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color("7b7f85")
	stone_mat.roughness = 1.0
	for i in 9:
		var a := float(i) / 9.0 * TAU
		var st := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.55, 0.38, 0.5)
		st.mesh = bm
		st.position = Vector3(cos(a) * 1.15, 0.19, sin(a) * 1.15)
		st.rotation.y = a
		st.material_override = stone_mat
		add_child(st)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("4a2e1a")
	for i in 3:
		var lg := MeshInstance3D.new()
		var bm2 := BoxMesh.new()
		bm2.size = Vector3(1.7, 0.2, 0.22)
		lg.mesh = bm2
		lg.position = Vector3(0, 0.32, 0)
		lg.rotation_degrees = Vector3(0, i * 60.0, 12.0)
		lg.material_override = wood
		add_child(lg)
	var cols := [Color(1.0, 0.25, 0.05, 0.9), Color(1.0, 0.55, 0.1, 0.9), Color(1.0, 0.9, 0.3, 0.9)]
	for i in 3:
		var f := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.55 - i * 0.15
		cm.height = 1.5 - i * 0.3
		cm.radial_segments = 8
		f.mesh = cm
		f.position = Vector3(0, 0.3 + cm.height * 0.5, 0)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = cols[i]
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		f.material_override = m
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(f)
		_flames.append(f)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.6, 0.25)
	_light.light_energy = 1.4
	_light.omni_range = 9.0
	_light.position = Vector3(0, 1.2, 0)
	add_child(_light)
	var sparks := CPUParticles3D.new()
	sparks.amount = 14
	sparks.lifetime = 1.6
	sparks.direction = Vector3(0, 1, 0)
	sparks.spread = 20.0
	sparks.initial_velocity_min = 1.5
	sparks.initial_velocity_max = 3.0
	sparks.gravity = Vector3(0, 0.5, 0)
	sparks.local_coords = false
	sparks.position = Vector3(0, 0.8, 0)
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 4
	sm.rings = 2
	sparks.mesh = sm
	var spm := StandardMaterial3D.new()
	spm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spm.albedo_color = Color(1.0, 0.7, 0.2)
	sparks.material_override = spm
	add_child(sparks)


func _process(delta: float) -> void:
	_t += delta
	for i in _flames.size():
		var f := _flames[i]
		var k := 1.0 + 0.18 * sin(_t * (9.0 + i * 3.0) + float(i)) + randf_range(-0.05, 0.05)
		f.scale = Vector3(1.0 + 0.1 * sin(_t * 7.0 + i), k, 1.0 + 0.1 * cos(_t * 8.0 + i))
	if _light:
		_light.light_energy = 1.3 + 0.35 * sin(_t * 13.0) + randf_range(-0.1, 0.1)
