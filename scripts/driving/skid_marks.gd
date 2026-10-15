class_name SkidMarks
extends MultiMeshInstance3D
## Black tyre marks left on the road while the car slides (a ring buffer of thin quads).

const CAPACITY := 1800

var _next: int = 0
var _hidden := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO)


func _init() -> void:
	top_level = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var quad := BoxMesh.new()
	quad.size = Vector3(0.28, 0.01, 1.0)
	mm.mesh = quad
	mm.instance_count = CAPACITY
	for i in CAPACITY:
		mm.set_instance_transform(i, _hidden)
	multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.02, 0.02, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_override = mat


## A mark centred on `pos`, running along the direction of travel `dir` (xz), `length` long.
func add_mark(pos: Vector3, dir: Vector3, length: float) -> void:
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length() < 0.01:
		return
	var yaw := atan2(-flat.x, -flat.z)
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3(1.0, 1.0, maxf(length, 0.2)))
	multimesh.set_instance_transform(_next, Transform3D(basis, pos))
	_next = (_next + 1) % CAPACITY
