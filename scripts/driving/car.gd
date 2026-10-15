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
var airborne: bool = false
var ground_fn: Callable = Callable()   # (x, z) -> ground height; set by the drive scene
var vy: float = 0.0
var _slope_pitch: float = 0.0
const GRAVITY := 12.0

## Saudi number plate (letters HXD). The Arabic row uses the Saudi plate letter
## equivalents (H = ه, X = ص, D = د). Change PLATE_NUMBER to your real digits.
const PLATE_LETTERS := "H X D"
const PLATE_LETTERS_AR := "ه ص د"
const PLATE_NUMBER := "1234"
const PLATE_NUMBER_AR := "١٢٣٤"

var _visual: Node3D
var _cabin_group: Node3D     # pillars, roof, glass: hidden in the hood view
var _people_group: Node3D    # driver, passengers and seats: hidden in the hood view
var _front_wheels: Array[Node3D] = []
var _spinners: Array[Node3D] = []
var _brake_mat: StandardMaterial3D
var _wheel_pivot: Node3D     # steering wheel, turns with the driver's input
var _heads: Array[Node3D] = []
var _dad_head: Node3D


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
	_cabin_group.visible = v
	_people_group.visible = v


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
	_update_height(delta)
	impact = maxf(impact, speed_before - velocity.length())
	forward_speed = velocity.dot(-global_transform.basis.z)
	if absf(forward_speed) < 0.08 and throttle == 0.0:
		forward_speed = 0.0

	_update_engine(forward_speed)
	_update_visuals(delta, throttle, brake)


## Follows the ground height; crests launch the car (roller-coaster road), landings thump.
func _update_height(delta: float) -> void:
	if not ground_fn.is_valid():
		position.y = 0.0
		return
	var gy: float = ground_fn.call(position.x, position.z)
	var prev := position.y
	vy = clampf(vy - GRAVITY * delta, -40.0, 40.0)
	var ny := prev + vy * delta
	if ny <= gy:
		if airborne and vy < -4.0:
			impact = maxf(impact, -vy * 1.4)   # landing thump + camera shake
		airborne = false
		vy = clampf((gy - prev) / maxf(delta, 0.0001), -40.0, 14.0)
		ny = gy
	else:
		airborne = ny > gy + 0.2
	position.y = ny
	if not airborne:
		var fwd := -global_transform.basis.z
		var front: float = ground_fn.call(position.x + fwd.x * 1.6, position.z + fwd.z * 1.6)
		var rear: float = ground_fn.call(position.x - fwd.x * 1.6, position.z - fwd.z * 1.6)
		_slope_pitch = lerpf(_slope_pitch, atan2(front - rear, 3.2), 0.4)


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
	_visual.rotation.x = lerpf(_visual.rotation.x, accel_pitch + _slope_pitch, 1.0 - exp(-8.0 * delta))
	_visual.rotation.z = lerpf(_visual.rotation.z, roll, 1.0 - exp(-8.0 * delta))
	for w in _front_wheels:
		w.rotation.y = -steer * 0.5
	for sp in _spinners:
		sp.rotation.x -= forward_speed / 0.4 * delta
	_wheel_pivot.get_child(0).rotation.y = -steer * 1.6
	_dad_head.rotation.y = lerpf(_dad_head.rotation.y, -steer * 0.45, 1.0 - exp(-6.0 * delta))
	for h in _heads:
		h.rotation.z = lerpf(h.rotation.z, -lateral_speed * 0.012 - steer * absf(forward_speed) * 0.003, 1.0 - exp(-5.0 * delta))
	_brake_mat.emission_energy_multiplier = 3.0 if (brake > 0.0 and forward_speed > 0.5) else 0.4


# --- model: low-poly 2019 Mazda CX-9 (Deep Crystal Blue) with the whole family -------

const BODY_COLOR := "1f4fa3"
const TRIM_DARK := "17191d"
const CHROME := "c9ced6"

func _build_model() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	_cabin_group = Node3D.new()
	_visual.add_child(_cabin_group)
	_people_group = Node3D.new()
	_people_group.position.y = 0.1   # seat everyone a little higher so they show above the beltline
	_visual.add_child(_people_group)
	var body := _mat(Color.html(BODY_COLOR), 0.35, 0.35)
	var dark := _mat(Color.html(TRIM_DARK), 0.0, 0.7)
	var chrome := _mat(Color.html(CHROME), 0.8, 0.25)
	var glass := _mat(Color(0.35, 0.5, 0.62, 0.28), 0.0, 0.1, 0.0, true)

	# lower body, sloped hood, bumpers
	_add(_visual, Vector3(1.95, 0.62, 5.0), Vector3(0, 0.69, 0), body)
	_add(_visual, Vector3(1.9, 0.16, 1.6), Vector3(0, 1.04, -1.65), body, Vector3(-5, 0, 0))
	_add(_visual, Vector3(1.9, 0.26, 0.22), Vector3(0, 0.5, -2.42), dark)           # front bumper
	_add(_visual, Vector3(1.9, 0.26, 0.22), Vector3(0, 0.5, 2.42), dark)            # rear bumper
	_add(_visual, Vector3(1.8, 0.12, 4.6), Vector3(0, 0.34, 0), dark)               # underbody / sills
	# signature Mazda grille + chrome wing + badge, LED headlights
	_add(_visual, Vector3(0.95, 0.3, 0.06), Vector3(0, 0.80, -2.53), dark)
	_add(_visual, Vector3(1.0, 0.05, 0.07), Vector3(0, 0.95, -2.54), chrome)
	var badge := _add(_visual, Vector3(0.14, 0.14, 0.04), Vector3(0, 0.8, -2.58), chrome)
	badge.mesh = _cyl(0.075, 0.075, 0.04, 14)
	badge.rotation_degrees.x = 90.0
	for x: float in [-0.72, 0.72]:
		_add(_visual, Vector3(0.5, 0.11, 0.07), Vector3(x, 0.92, -2.52), _mat(Color.html("f4f8ff"), 0.0, 0.2, 2.2))
		_add(_visual, Vector3(0.14, 0.07, 0.07), Vector3(x * 1.22, 0.6, -2.5), _mat(Color.html("ffd166"), 0.0, 0.3, 1.2))  # fog light
	# tail lights (C-shape: bar + vertical piece), brake light material shared
	_brake_mat = _mat(Color.html("c1121f"), 0.0, 0.3, 0.4)
	_brake_mat.emission_enabled = true
	_brake_mat.emission = Color.html("ff1a1a")
	for x: float in [-1.0, 1.0]:
		_add(_visual, Vector3(0.14, 0.4, 0.06), Vector3(x * 0.84, 1.0, 2.52), _brake_mat)    # vertical piece
		_add(_visual, Vector3(0.3, 0.1, 0.06), Vector3(x * 0.62, 1.15, 2.52), _brake_mat)    # top arm of the "C"
		_add(_visual, Vector3(0.3, 0.1, 0.06), Vector3(x * 0.62, 0.85, 2.52), _brake_mat)    # bottom arm
	_add(_visual, Vector3(1.4, 0.05, 0.05), Vector3(0, 1.22, 2.5), chrome)          # tailgate chrome bar
	# mirrors and door shut-lines
	for x: float in [-1.05, 1.05]:
		_add(_visual, Vector3(0.2, 0.13, 0.12), Vector3(x, 1.18, -0.8), body)
		for z: float in [-0.35, 0.65, 1.7]:
			_add(_visual, Vector3(0.012, 0.55, 0.012), Vector3(x * 0.93, 0.7, z), dark)
		_add(_visual, Vector3(0.012, 0.03, 4.3), Vector3(x * 0.93, 0.98, 0.0), chrome)  # beltline chrome

	# --- greenhouse (cabin group): pillars, roof, rails, see-through glass ---------
	var cab := _cabin_group
	_add(cab, Vector3(1.8, 0.05, 1.12), Vector3(0, 1.35, -0.58), glass, Vector3(-39.5, 0, 0))   # windshield
	_add(cab, Vector3(1.78, 0.06, 2.15), Vector3(0, 1.73, 0.93), body)                          # roof
	_add(cab, Vector3(1.8, 0.05, 0.75), Vector3(0, 1.43, 2.22), glass, Vector3(50.7, 0, 0))    # rear glass
	for x: float in [-0.7, 0.7]:
		_add(cab, Vector3(0.05, 0.05, 2.1), Vector3(x, 1.79, 0.93), chrome)                     # roof rails
	for x: float in [-0.9, 0.9]:
		_add(cab, Vector3(0.07, 0.06, 1.12), Vector3(x, 1.35, -0.58), body, Vector3(-39.5, 0, 0))  # A-pillar
		_add(cab, Vector3(0.07, 0.07, 0.75), Vector3(x, 1.43, 2.22), body, Vector3(50.7, 0, 0))    # D-pillar
		_add(cab, Vector3(0.09, 0.72, 0.1), Vector3(x, 1.36, 0.62), body)                          # B-pillar
		_add(cab, Vector3(0.09, 0.72, 0.1), Vector3(x, 1.36, 1.93), body)                          # C-pillar
		_add(cab, Vector3(0.025, 0.66, 1.2), Vector3(x * 1.08, 1.34, 0.0), glass)                  # front side glass
		_add(cab, Vector3(0.025, 0.66, 1.25), Vector3(x * 1.08, 1.34, 1.28), glass)                # rear side glass

	_build_interior_and_people()
	_build_wheels()
	_add_plate(2.54, false)
	_add_plate(-2.60, true)


func _build_wheels() -> void:
	var tyre_mat := _mat(Color.html("1a1a1c"), 0.0, 0.9)
	var rim_mat := _mat(Color.html("b9c0cc"), 0.85, 0.25)
	for wx: float in [-0.99, 0.99]:
		for wz: float in [-1.55, 1.5]:
			var pivot := Node3D.new()
			pivot.position = Vector3(wx, 0.4, wz)
			_visual.add_child(pivot)
			var spinner := Node3D.new()
			pivot.add_child(spinner)
			var tyre := _add(spinner, Vector3.ONE, Vector3.ZERO, tyre_mat)
			tyre.mesh = _cyl(0.4, 0.4, 0.3, 14)
			tyre.rotation_degrees.z = 90.0
			var rim := _add(spinner, Vector3.ONE, Vector3(signf(wx) * 0.01, 0, 0), rim_mat)
			rim.mesh = _cyl(0.27, 0.27, 0.32, 12)
			rim.rotation_degrees.z = 90.0
			for a in 3:  # spokes so the spin is visible
				var spoke := _add(spinner, Vector3(0.34, 0.07, 0.5), Vector3(signf(wx) * 0.17, 0, 0), tyre_mat)
				spoke.rotation_degrees.x = a * 60.0
				spoke.scale = Vector3(0.1, 1.0, 1.0)
			_spinners.append(spinner)
			if wz < 0.0:
				_front_wheels.append(pivot)


func _build_interior_and_people() -> void:
	var p := _people_group
	var seat := _mat(Color.html("2b2b30"), 0.0, 0.9)
	var dash := _mat(Color.html("1d1d21"), 0.0, 0.8)
	_add(p, Vector3(1.75, 0.2, 0.45), Vector3(0, 1.07, -0.78), dash)                 # dashboard
	# front seats (driver on the LEFT: Saudi Arabia drives on the right)
	for x: float in [-0.45, 0.45]:
		_add(p, Vector3(0.5, 0.12, 0.5), Vector3(x, 0.66, 0.08), seat)
		_add(p, Vector3(0.5, 0.62, 0.1), Vector3(x, 1.0, 0.36), seat)
	# second-row bench
	_add(p, Vector3(1.75, 0.12, 0.5), Vector3(0, 0.66, 1.3), seat)
	_add(p, Vector3(1.75, 0.6, 0.1), Vector3(0, 0.99, 1.58), seat)
	# steering wheel (tilted toward the driver) - child 0 turns with the steering input
	_wheel_pivot = Node3D.new()
	_wheel_pivot.position = Vector3(-0.45, 1.06, -0.4)
	_wheel_pivot.rotation_degrees.x = 62.0
	p.add_child(_wheel_pivot)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.12
	torus.outer_radius = 0.18
	torus.rings = 12
	torus.ring_segments = 6
	ring.mesh = torus
	ring.material_override = dash
	_wheel_pivot.add_child(ring)

	var d := Game.CHARACTERS["daniah"]
	var s := Game.CHARACTERS["sarah"]
	var l := Game.CHARACTERS["lamia"]
	# Dad (driving): white thobe, white ghutra with a black agal
	_dad_head = _person(Vector3(-0.45, 0.72, 0.1), "f4f1ea", 0.5, 0.118, "dcae85", "", "ghutra", false)
	# Mom: black abaya and headscarf
	_person(Vector3(0.45, 0.72, 0.1), "17171a", 0.46, 0.108, "e3b992", "", "hijab", false)
	# three daughters on the back seat
	_person(Vector3(-0.62, 0.72, 1.3), d["color"], 0.40, 0.102, "e8bd95", d["hair"], "girl", true)   # Daniah (glasses)
	_person(Vector3(0.0, 0.72, 1.3), s["color"], 0.45, 0.106, "e8bd95", s["hair"], "girl", false)    # Sarah (tallest)
	_person(Vector3(0.62, 0.72, 1.3), l["color"], 0.31, 0.098, "e8bd95", l["hair"], "girl", false)   # Lamia (youngest)
	# Dad's arms reach the steering wheel
	for x: float in [-0.62, -0.28]:
		_add(p, Vector3(0.09, 0.09, 0.58), Vector3(x, 1.12, -0.17), _mat(Color.html("f4f1ea"), 0.0, 0.9), Vector3(-17, 0, 0))


## One seated person: torso + head (+ cover/hair). `base` is the seat-cushion top.
## Returns the head pivot so the car can turn / sway it.
func _person(base: Vector3, torso_hex: String, torso_h: float, head_r: float, skin_hex: String,
		hair_hex: String, style: String, glasses: bool) -> Node3D:
	var p := _people_group
	head_r *= 1.15
	var torso_mat := _mat(Color.html(torso_hex), 0.0, 0.9)
	var skin := _mat(Color.html(skin_hex), 0.0, 0.8)
	_add(p, Vector3(0.42, torso_h, 0.26), base + Vector3(0, torso_h * 0.5, 0), torso_mat)
	var head := Node3D.new()
	head.position = base + Vector3(0, torso_h + head_r * 0.9, 0)
	p.add_child(head)
	_heads.append(head)
	_ball(head, head_r * 0.95, Vector3(0, 0, -0.03), skin)
	for ex: float in [-0.04, 0.04]:
		_add(head, Vector3(0.022, 0.026, 0.01), Vector3(ex * head_r / 0.1, 0.012, -head_r * 0.95 - 0.025), _mat(Color.html("151515"), 0.0, 0.9))
	match style:
		"ghutra":
			var white := _mat(Color.html("f7f7f5"), 0.0, 0.95)
			_ball(head, head_r * 1.18, Vector3(0, head_r * 0.28, 0.035), white, Vector3(1.0, 0.85, 1.05))
			_add(head, Vector3(head_r * 0.45, head_r * 1.9, head_r * 2.0), Vector3(-head_r * 1.15, -head_r * 0.3, 0.05), white)
			_add(head, Vector3(head_r * 0.45, head_r * 1.9, head_r * 2.0), Vector3(head_r * 1.15, -head_r * 0.3, 0.05), white)
			_add(head, Vector3(head_r * 2.3, head_r * 2.0, head_r * 0.45), Vector3(0, -head_r * 0.3, head_r * 1.0), white)
			var agal := _add(head, Vector3.ONE, Vector3(0, head_r * 0.62, 0.0), _mat(Color.html("151515"), 0.0, 0.8))
			agal.mesh = _cyl(head_r * 1.2, head_r * 1.2, 0.03, 12)
		"hijab":
			var black := _mat(Color.html("16161a"), 0.0, 0.95)
			_ball(head, head_r * 1.2, Vector3(0, head_r * 0.12, 0.05), black)
			_add(head, Vector3(head_r * 2.5, head_r * 2.6, head_r * 0.7), Vector3(0, -head_r * 1.2, head_r * 0.9), black)
		"girl":
			var hair := _mat(Color.html(hair_hex), 0.0, 0.9)
			_ball(head, head_r * 1.12, Vector3(0, head_r * 0.15, 0.045), hair)
			_add(head, Vector3(head_r * 1.9, head_r * 2.6, head_r * 0.5), Vector3(0, -head_r * 0.9, head_r * 0.85), hair)   # long hair
	if glasses:
		var frame := _mat(Color.html("101010"), 0.0, 0.6)
		for ex: float in [-0.04, 0.04]:
			var lens := _add(head, Vector3.ONE, Vector3(ex * head_r / 0.1, 0.012, -head_r * 0.95 - 0.03), frame)
			var t := TorusMesh.new()
			t.inner_radius = 0.022
			t.outer_radius = 0.036
			t.rings = 10
			t.ring_segments = 4
			lens.mesh = t
			lens.rotation_degrees.x = 90.0
		_add(head, Vector3(0.03, 0.01, 0.01), Vector3(0, 0.014, -head_r * 0.95 - 0.03), frame)
	return head


## Saudi plate: white, black border, blue KSA strip, Arabic row over Latin row.
## Slightly oversized (about 1.7x real) so the letters stay legible from the chase camera.
func _add_plate(z: float, front: bool) -> void:
	var plate := Node3D.new()
	plate.position = Vector3(0, 0.55 if front else 0.82, z)
	if front:
		plate.rotation.y = PI
	_visual.add_child(plate)
	_add(plate, Vector3(0.98, 0.3, 0.02), Vector3(0, 0, 0), _mat(Color.html("1a1a1a"), 0.0, 0.6))
	_add(plate, Vector3(0.94, 0.26, 0.025), Vector3(0, 0, 0.004), _mat(Color.html("fbfbf8"), 0.0, 0.5))
	_add(plate, Vector3(0.14, 0.26, 0.03), Vector3(-0.4, 0, 0.006), _mat(Color.html("0b5ea8"), 0.0, 0.5))
	_plate_label(plate, "K\nS\nA", Vector3(-0.4, 0.0, 0.025), 38, 0.0021, Color.WHITE)
	_plate_label(plate, "%s  %s" % [PLATE_LETTERS_AR, PLATE_NUMBER_AR], Vector3(0.07, 0.065, 0.025), 60, 0.0026, Color.BLACK)
	_plate_label(plate, "%s  %s" % [PLATE_NUMBER, PLATE_LETTERS], Vector3(0.07, -0.06, 0.025), 60, 0.0026, Color.BLACK)


func _plate_label(parent: Node3D, text: String, pos: Vector3, px: int, pixel: float, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = px
	l.pixel_size = pixel
	l.outline_size = 0
	l.modulate = color
	l.double_sided = false
	l.position = pos
	parent.add_child(l)


# ---- tiny mesh/material helpers -------------------------------------------------

func _mat(color: Color, metallic: float = 0.0, rough: float = 0.8, emission: float = 0.0,
		transparent: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = rough
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _add(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _cyl(top: float, bottom: float, height: float, segments: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = segments
	return c


func _ball(parent: Node3D, radius: float, pos: Vector3, mat: Material, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := _add(parent, Vector3.ONE, pos, mat)
	mi.mesh = _sphere(radius, 10)
	mi.scale = scl
	return mi


func _sphere(radius: float, segments: int) -> SphereMesh:
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = segments
	sph.rings = maxi(3, segments / 2)
	return sph
