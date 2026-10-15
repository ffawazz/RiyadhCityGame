class_name LocationZone
extends Area3D
## A glowing light-beam on the road. When the car is inside, the drive scene
## offers "Press E to enter" and hands the location id to the Router.

signal car_entered(zone: LocationZone)
signal car_exited(zone: LocationZone)

const RADIUS := 15.0

var radius: float = RADIUS
var location_id: String = ""
var title: String = ""
var tint: Color = Color.WHITE

var _beam_mat: StandardMaterial3D
var _t: float = 0.0


func setup(id: String, pos: Vector2, zone_radius: float = RADIUS) -> void:
	radius = zone_radius
	location_id = id
	position = Vector3(pos.x, 0.0, pos.y)
	var data: Dictionary = Game.LOCATIONS[id]
	title = data["title"]
	tint = Color.html(data["color"])


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 8.0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position.y = 3.0
	add_child(cs)

	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_mat.albedo_color = Color(tint, 0.2)
	var beam := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 45.0 if radius > 10.0 else 14.0
	cyl.radial_segments = 20
	beam.mesh = cyl
	beam.position.y = cyl.height * 0.5
	beam.material_override = _beam_mat
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)

	var ring := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = radius
	disk.bottom_radius = radius
	disk.height = 0.05
	disk.radial_segments = 28
	ring.mesh = disk
	ring.position.y = 0.06
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(tint, 0.55)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

	var lbl := Label3D.new()
	lbl.text = title
	lbl.font_size = 64
	lbl.pixel_size = 0.045 if radius > 10.0 else 0.021
	lbl.outline_size = 14
	lbl.modulate = Color.WHITE
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.position.y = 16.0 if radius > 10.0 else 7.0
	add_child(lbl)

	body_entered.connect(func(body: Node3D) -> void:
		if body is Car:
			car_entered.emit(self))
	body_exited.connect(func(body: Node3D) -> void:
		if body is Car:
			car_exited.emit(self))


func _process(delta: float) -> void:
	_t += delta
	_beam_mat.albedo_color = Color(tint, 0.17 + 0.07 * sin(_t * 3.0))
