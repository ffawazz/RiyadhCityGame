class_name ChaseCamera
extends Camera3D
## Driver-style chase camera: trails the car and lags behind in corners so you
## see the car's flank during slides. C cycles Chase / Far / Hood views.

enum Mode { CHASE, FAR, HOOD }

var target: Car
var mode: int = Mode.CHASE
var _yaw: float = 0.0
var _shake: float = 0.0


func _ready() -> void:
	top_level = true
	near = 0.1
	far = 1800.0
	fov = 66.0
	current = true


func snap_to_target() -> void:
	_yaw = target.rotation.y
	_place(1.0)


func cycle_mode() -> void:
	mode = (mode + 1) % 3
	target.set_cabin_visible(mode != Mode.HOOD)


func add_shake(amount: float) -> void:
	_shake = clampf(maxf(_shake, amount), 0.0, 1.0)


func _process(delta: float) -> void:
	if target != null:
		_place(delta)


func _place(delta: float) -> void:
	var speed := target.velocity.length()
	fov = lerpf(fov, 66.0 + 20.0 * clampf(speed / Car.MAX_SPEED, 0.0, 1.0), 1.0 - exp(-4.0 * delta))
	var car_pos := target.global_position
	var shake_offset := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0.0) * _shake * 0.35
	_shake = maxf(0.0, _shake - delta * 2.0)
	if mode == Mode.HOOD:
		_yaw = target.rotation.y
		var b := Basis(Vector3.UP, _yaw)
		global_transform = Transform3D(b, car_pos + b * Vector3(0, 1.6, 0.1) + shake_offset)
		return
	# the camera lags in turns and swings out with the slide, so you see the tail come round
	var look_yaw := target.rotation.y - target.body_slip * 0.6
	_yaw = lerp_angle(_yaw, look_yaw, 1.0 - exp(-3.0 * delta))
	var behind := 8.5 if mode == Mode.CHASE else 16.0
	var height := 3.2 if mode == Mode.CHASE else 7.5
	var b2 := Basis(Vector3.UP, _yaw)
	var pos := car_pos + b2 * Vector3(0, height, behind) + shake_offset
	global_transform = Transform3D(b2, pos).looking_at(car_pos + Vector3.UP * 1.3, Vector3.UP)
