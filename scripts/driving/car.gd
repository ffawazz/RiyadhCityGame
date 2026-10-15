class_name Car
extends CharacterBody3D
## The family's blue 2019 Mazda CX-9, arcade-realistic 3D driving in the spirit of
## the original PlayStation "Driver": heavy-ish chase-cam car, big handbrake slides.
##
## The car faces -Z. Heading changes through a bicycle steering model; the velocity
## vector is kept separate from the heading, so turning fast or pulling the
## handbrake makes the car genuinely slide sideways before the tyres bite again.

const MAX_SPEED := 50.0      # m/s (~180 km/h)
const MAX_REVERSE := 9.0
const ACCEL := 11.0
const BRAKE := 30.0
const WHEELBASE := 3.0
const GRIP := 9.0            # how fast sideways slip is killed (1/s)
const DRIFT_GRIP := 2.2      # ...with the handbrake on
const GEAR_START := [0.0, 9.0, 19.0, 30.0, 41.0]
const GEAR_END := [11.0, 21.0, 32.0, 43.0, 52.0]

var steer: float = 0.0             # -1..1 (smoothed), +1 = right
var forward_speed: float = 0.0     # m/s along the nose (negative = reversing)
var lateral_speed: float = 0.0     # m/s sideways (slide)
var gear: int = 1
var engine_hz: float = 40.0        # engine firing frequency for the sound
var throttle_amount: float = 0.0
var sliding: bool = false
var impact: float = 0.0            # last collision strength; the scene reads + clears it

var _visual: Node3D
var _cabin: MeshInstance3D
var _front_wheels: Array[Node3D] = []
var _brake_mat: StandardMaterial3D


func _init() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.3, 4.9)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.85, 0)
	add_child(cs)
	_build_model()


func set_cabin_visible(v: bool) -> void:
	_cabin.visible = v


func _physics_process(delta: float) -> void:
	var throttle := Input.get_action_strength("accelerate")
	var brake := Input.get_action_strength("brake")
	var hand := Input.is_action_pressed("handbrake")
	throttle_amount = throttle

	# smooth steering (returns to centre quicker than it turns in)
	var steer_in := Input.get_axis("steer_left", "steer_right")
	var rate := 7.0 if (steer_in == 0.0 or signf(steer_in) != signf(steer)) else 3.5
	steer = move_toward(steer, steer_in, rate * delta)

	# --- heading (bicycle model): turn rate grows with speed, steering lock shrinks ---
	var speed_frac := clampf(absf(forward_speed) / MAX_SPEED, 0.0, 1.0)
	var lock := lerpf(0.62, 0.11, speed_frac)
	var yaw_rate := -(forward_speed / WHEELBASE) * tan(steer * lock)
	if hand:
		yaw_rate *= 1.25
	rotation.y += yaw_rate * delta

	# --- re-express the (unchanged) velocity in the new heading axes ---
	var fwd := -global_transform.basis.z
	var right := global_transform.basis.x
	forward_speed = velocity.dot(fwd)
	lateral_speed = velocity.dot(right)

	# --- engine / brakes / drag ---
	if throttle > 0.0:
		forward_speed += ACCEL * throttle * clampf(1.0 - forward_speed / MAX_SPEED, 0.0, 1.0) * delta
	if brake > 0.0:
		if forward_speed > 0.5:
			forward_speed = maxf(0.0, forward_speed - BRAKE * brake * delta)
		else:
			forward_speed = maxf(-MAX_REVERSE, forward_speed - 7.0 * brake * delta)
	if throttle == 0.0 and brake == 0.0:
		forward_speed = move_toward(forward_speed, 0.0, (1.8 + 0.05 * absf(forward_speed)) * delta)
	if hand:
		forward_speed = move_toward(forward_speed, 0.0, 4.0 * delta)

	# --- tyre grip: sideways slip decays; less grip when hard-cornering fast or on handbrake ---
	var grip := DRIFT_GRIP if hand else GRIP * (1.0 - 0.45 * speed_frac * absf(steer))
	lateral_speed *= exp(-grip * delta)
	forward_speed = move_toward(forward_speed, 0.0, absf(lateral_speed) * 0.12 * delta)
	sliding = absf(lateral_speed) > 3.0

	velocity = fwd * forward_speed + right * lateral_speed
	velocity.y = 0.0
	var speed_before := velocity.length()
	move_and_slide()
	position.y = 0.0
	impact = maxf(impact, speed_before - velocity.length())
	forward_speed = velocity.dot(-global_transform.basis.z)
	if absf(forward_speed) < 0.08 and throttle == 0.0:
		forward_speed = 0.0

	_update_engine(forward_speed)
	_update_visuals(delta, throttle, brake)


func _update_engine(fs: float) -> void:
	var sp := absf(fs)
	gear = 1
	for i in GEAR_START.size():
		if sp >= float(GEAR_START[i]):
			gear = i + 1
	var g := gear - 1
	var frac := clampf((sp - float(GEAR_START[g])) / (float(GEAR_END[g]) - float(GEAR_START[g])), 0.0, 1.0)
	var rpm := 900.0 + frac * 4600.0 + throttle_amount * 400.0
	engine_hz = rpm / 60.0 * 3.0  # V6: three firings per revolution


func _update_visuals(delta: float, throttle: float, brake: float) -> void:
	var accel_pitch := (brake * 0.025) - (throttle * 0.012 * (1.0 - absf(forward_speed) / MAX_SPEED))
	var roll := -steer * absf(forward_speed) / MAX_SPEED * 0.07 - lateral_speed * 0.004
	_visual.rotation.x = lerpf(_visual.rotation.x, accel_pitch, 1.0 - exp(-8.0 * delta))
	_visual.rotation.z = lerpf(_visual.rotation.z, roll, 1.0 - exp(-8.0 * delta))
	for w in _front_wheels:
		w.rotation.y = -steer * 0.5
	_brake_mat.emission_energy_multiplier = 3.0 if (brake > 0.0 and forward_speed > 0.5) else 0.4


# --- model: simple low-poly blocks in the PS1 spirit ----------------------------

func _build_model() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var blue := Color.html("1b4fa0")
	_box(Vector3(1.9, 0.75, 4.9), Vector3(0, 0.75, 0), blue)                      # lower body
	_box(Vector3(1.8, 0.28, 1.4), Vector3(0, 1.0, -1.7), Color.html("2463c4"))     # hood bulge
	_cabin = _box(Vector3(1.75, 0.72, 2.7), Vector3(0, 1.45, 0.35), Color.html("5f87ad"))  # glass cabin
	_cabin.add_child(_mesh_box(Vector3(1.8, 0.1, 2.75), Vector3(0, 0.38, 0), Color.html("163d7a")))  # roof
	_box(Vector3(1.8, 0.4, 0.2), Vector3(0, 0.9, 2.4), Color.html("163d7a"))        # rear lip
	for x in [-0.7, 0.7]:
		_box(Vector3(0.45, 0.2, 0.08), Vector3(x, 0.85, -2.46), Color.html("fff3b0"), 2.5)  # headlights
	_brake_mat = StandardMaterial3D.new()
	_brake_mat.albedo_color = Color.html("d62828")
	_brake_mat.emission_enabled = true
	_brake_mat.emission = Color.html("ff1a1a")
	_brake_mat.emission_energy_multiplier = 0.4
	for x in [-0.7, 0.7]:
		var tl := _mesh_box(Vector3(0.5, 0.2, 0.08), Vector3(x, 0.9, 2.46), Color.WHITE)
		tl.material_override = _brake_mat
		_visual.add_child(tl)
	for wx in [-0.98, 0.98]:
		for wz in [-1.55, 1.5]:
			var pivot := Node3D.new()
			pivot.position = Vector3(wx, 0.38, wz)
			var tyre := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.38
			cyl.bottom_radius = 0.38
			cyl.height = 0.32
			cyl.radial_segments = 10
			tyre.mesh = cyl
			tyre.rotation_degrees.z = 90.0
			tyre.material_override = _flat(Color.html("1d1d1f"))
			pivot.add_child(tyre)
			_visual.add_child(pivot)
			if wz < 0.0:
				_front_wheels.append(pivot)


func _flat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


func _mesh_box(size: Vector3, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _flat(color, emission)
	return mi


func _box(size: Vector3, pos: Vector3, color: Color, emission: float = 0.0) -> MeshInstance3D:
	var mi := _mesh_box(size, pos, color, emission)
	_visual.add_child(mi)
	return mi
