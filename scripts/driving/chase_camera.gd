class_name ChaseCamera
extends Camera3D
## Driver-style chase camera with free orbit. It trails the car, lags in corners and swings
## out with slides. C cycles Chase / Far / Hood views. You can also move it around the car:
##   hold RIGHT MOUSE and drag, or J / L (left / right) and I / K (up / down), or the right stick
##   mouse wheel or U / O zoom in / out,  hold B to look behind,  V locks the view where it is.
## Without input it eases back behind the car after two seconds (unless locked).

enum Mode { CHASE, FAR, HOOD }

var target: Car
var mode: int = Mode.CHASE
var orbit_yaw: float = 0.0
var orbit_pitch: float = 0.0
var orbit_zoom: float = 1.0
var locked: bool = false          # V: keep the orbit view instead of drifting back
var _yaw: float = 0.0
var _shake: float = 0.0
var _idle: float = 99.0


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
	reset_orbit()


func reset_orbit() -> void:
	orbit_yaw = 0.0
	orbit_pitch = 0.0
	orbit_zoom = 1.0
	locked = false
	_idle = 99.0


func add_shake(amount: float) -> void:
	_shake = clampf(maxf(_shake, amount), 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		orbit_yaw -= motion.relative.x * 0.006
		orbit_pitch = clampf(orbit_pitch + motion.relative.y * 0.006, -0.7, 1.1)
		_idle = 0.0
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		if click.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_zoom = clampf(orbit_zoom * 0.9, 0.45, 2.6)
			_idle = 0.0
		elif click.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_zoom = clampf(orbit_zoom * 1.1, 0.45, 2.6)
			_idle = 0.0
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_V:
		locked = not locked


func _process(delta: float) -> void:
	if target == null:
		return
	_read_keys(delta)
	_place(delta)


func _read_keys(delta: float) -> void:
	var turn := 0.0
	var tilt := 0.0
	var zoom := 0.0
	if Input.is_physical_key_pressed(KEY_J):
		turn += 1.0
	if Input.is_physical_key_pressed(KEY_L):
		turn -= 1.0
	if Input.is_physical_key_pressed(KEY_I):
		tilt -= 1.0
	if Input.is_physical_key_pressed(KEY_K):
		tilt += 1.0
	if Input.is_physical_key_pressed(KEY_U):
		zoom -= 1.0
	if Input.is_physical_key_pressed(KEY_O):
		zoom += 1.0
	var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var ry := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(rx) > 0.25:
		turn -= rx
	if absf(ry) > 0.25:
		tilt += ry
	if turn != 0.0 or tilt != 0.0 or zoom != 0.0:
		orbit_yaw += turn * 2.0 * delta
		orbit_pitch = clampf(orbit_pitch + tilt * 1.4 * delta, -0.7, 1.1)
		orbit_zoom = clampf(orbit_zoom * (1.0 + zoom * 1.2 * delta), 0.45, 2.6)
		_idle = 0.0
	var behind := Input.is_physical_key_pressed(KEY_B)
	if behind:
		orbit_yaw = lerp_angle(orbit_yaw, PI, 1.0 - exp(-10.0 * delta))
		_idle = 0.0
	_idle += delta
	if not locked and not behind and _idle > 2.0:     # ease back behind the car
		var k := 1.0 - exp(-2.5 * delta)
		orbit_yaw = lerp_angle(orbit_yaw, 0.0, k)
		orbit_pitch = lerpf(orbit_pitch, 0.0, k)
		orbit_zoom = lerpf(orbit_zoom, 1.0, k)


func _place(delta: float) -> void:
	var speed := target.velocity.length()
	fov = lerpf(fov, 66.0 + 20.0 * clampf(speed / Car.MAX_SPEED, 0.0, 1.0), 1.0 - exp(-4.0 * delta))
	var car_pos := target.global_position
	var shake_offset := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0.0) * _shake * 0.35
	_shake = maxf(0.0, _shake - delta * 2.0)
	if mode == Mode.HOOD:
		_yaw = target.rotation.y
		var look := Basis(Vector3.UP, _yaw + clampf(orbit_yaw, -2.0, 2.0)) * Basis(Vector3.RIGHT, -clampf(orbit_pitch, -0.5, 0.5))
		global_transform = Transform3D(look, car_pos + Basis(Vector3.UP, _yaw) * Vector3(0, 1.6, 0.1) + shake_offset)
		return
	# the camera lags in turns and swings out with the slide, so you see the tail come round
	var look_yaw := target.rotation.y - target.body_slip * 0.6
	_yaw = lerp_angle(_yaw, look_yaw, 1.0 - exp(-3.0 * delta))
	var behind := 8.5 if mode == Mode.CHASE else 16.0
	var height := 3.2 if mode == Mode.CHASE else 7.5
	var dist := sqrt(behind * behind + height * height) * orbit_zoom
	var pitch := clampf(atan2(height, behind) + orbit_pitch, 0.05, 1.45)
	var b := Basis(Vector3.UP, _yaw + orbit_yaw)
	var pos := car_pos + b * Vector3(0, sin(pitch) * dist, cos(pitch) * dist) + shake_offset
	pos.y = maxf(pos.y, 0.6)
	global_transform = Transform3D(b, pos).looking_at(car_pos + Vector3.UP * 1.3, Vector3.UP)
