class_name FarmWorld
extends Node3D
## Al-Muzahimiyah farm, in 3D. You ARE your animal: walk (WASD, SPACE to jump) to the pool,
## the ping-pong table, the cornhole boards or the basketball hoop and press E in the light
## beam to play. The parked family CX-9 drives you home; the barn lets you change animal.

const SIZE := Vector2(180, 140)
const STATIONS := {
	"farm_swim": Vector2(35, 74),
	"farm_pingpong": Vector2(90, 48),
	"farm_cornhole": Vector2(146, 70),
	"farm_basketball": Vector2(90, 100),
	"barn": Vector2(150, 40),
	"farm_exit": Vector2(90, 126),
}

var arch: RiyadhBuilder
var animal: FarmAnimal
var cam: Camera3D
var _rng := RandomNumberGenerator.new()
var _active_zone: LocationZone
var _prompt: Label
var _palms: Array = []


func _ready() -> void:
	_rng.seed = 5
	_build_environment()
	arch = RiyadhBuilder.new(self, _rng)
	_build_ground()
	_build_walls()
	_build_stations()
	_build_decor()
	arch.finish()
	_build_palms()
	_spawn_zones()
	_spawn_animal()
	_build_hud()


func _process(delta: float) -> void:
	# third-person camera follows the animal
	var target := animal.global_position
	var want := target + Vector3(0.0, 9.5, 12.5)
	cam.global_position = cam.global_position.lerp(want, 1.0 - exp(-5.0 * delta))
	cam.look_at(target + Vector3(0.0, 1.5, 0.0))
	if _active_zone:
		_prompt.text = "Press E:  %s" % _active_zone.title
		if Input.is_action_just_pressed("interact"):
			Router.enter_location(_active_zone.location_id)
	else:
		_prompt.text = ""
	if Input.is_action_just_pressed("ui_cancel"):
		Game.save_game()
		Router.go("main_menu")


# ---- world ------------------------------------------------------------------------

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color.html("4f93d6")
	sky_mat.sky_horizon_color = Color.html("f2d9b0")
	sky_mat.ground_horizon_color = Color.html("f2d9b0")
	sky_mat.ground_bottom_color = Color.html("c8b48a")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.8, 0.7)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color.html("f0d6ae")
	env.fog_density = 0.0018
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_energy = 0.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	add_child(sun)


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(SIZE.x * 0.5, -0.5, SIZE.y * 0.5)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	cs.shape = box
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(3000.0, 3000.0)
	mi.mesh = plane
	mi.position.y = 0.5
	mi.material_override = arch.flat(Color.html("5d8f43"))
	body.add_child(mi)
	add_child(body)
	# sandy paths linking the stations
	var sand := Color.html("dcc89f")
	var spine := Vector2(90.0, 0.0)
	arch.deco(Vector3(spine.x, 0.02, 90.0), Vector3(5.0, 0.04, 80.0), sand)
	arch.deco(Vector3(62.0, 0.02, 74.0), Vector3(56.0, 0.04, 5.0), sand)
	arch.deco(Vector3(118.0, 0.02, 74.0), Vector3(56.0, 0.04, 5.0), sand)
	arch.deco(Vector3(120.0, 0.02, 42.0), Vector3(60.0, 0.04, 5.0), sand)
	arch.deco(Vector3(150.0, 0.02, 50.0), Vector3(5.0, 0.04, 28.0), sand)
	arch.deco(Vector3(90.0, 0.02, 36.0), Vector3(5.0, 0.04, 30.0), sand)
	# irrigated alfalfa fields
	arch.deco(Vector3(20.0, 0.03, 22.0), Vector3(34.0, 0.06, 30.0), Color.html("4f8f3a"))
	arch.deco(Vector3(60.0, 0.03, 20.0), Vector3(30.0, 0.06, 26.0), Color.html("5da145"))


func _build_walls() -> void:
	var h := 2.4
	var mud := Color.html("d6b98a")
	for r: Rect2 in [
			Rect2(-1.0, -1.0, SIZE.x + 2.0, 2.0), Rect2(-1.0, 0.0, 2.0, SIZE.y),
			Rect2(SIZE.x - 1.0, 0.0, 2.0, SIZE.y),
			Rect2(-1.0, SIZE.y - 1.0, 76.0, 2.0), Rect2(105.0, SIZE.y - 1.0, SIZE.x - 104.0, 2.0)]:
		arch.solid(r, h, mud, 2)
		arch.merlons(r, h)
	# entrance gate posts
	for gx: float in [76.0, 104.0]:
		arch.solid(Rect2(gx - 1.5, SIZE.y - 2.0, 3.0, 4.0), 5.0, Color.html("c9a66b"), 2)


func _build_stations() -> void:
	# --- swimming pool (solid block, water on top) ---
	var pool := Rect2(22.0, 50.0, 26.0, 16.0)
	arch.solid(pool.grow(1.2), 0.5, Color.html("f4f1de"), 0)                      # tiled rim
	var water := arch.deco(Vector3(pool.get_center().x, 0.52, pool.get_center().y), Vector3(pool.size.x, 0.06, pool.size.y), Color(0.2, 0.7, 0.95))
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.2, 0.72, 0.96, 0.82)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.1
	wm.metallic = 0.3
	water.material_override = wm
	arch.deco(Vector3(pool.get_center().x - 8.0, 1.2, pool.end.y + 0.2), Vector3(5.0, 0.2, 1.0), Color.html("8ecae6"))   # diving board
	# --- ping-pong table ---
	var table_c := Vector2(90.0, 35.0)
	var tbody := StaticBody3D.new()
	tbody.position = Vector3(table_c.x, 0.0, table_c.y)
	var tcs := CollisionShape3D.new()
	var tshape := BoxShape3D.new()
	tshape.size = Vector3(5.2, 1.7, 3.0)
	tcs.shape = tshape
	tcs.position.y = 0.85
	tbody.add_child(tcs)
	add_child(tbody)
	arch.deco(Vector3(table_c.x, 1.45, table_c.y), Vector3(4.6, 0.14, 2.6), Color.html("1b7f5c"))
	arch.deco(Vector3(table_c.x, 1.45, table_c.y), Vector3(0.06, 0.15, 2.6), Color.html("f4f1de"))          # centre line
	arch.deco(Vector3(table_c.x, 1.72, table_c.y), Vector3(0.05, 0.34, 2.8), Color.html("f1faee"))          # net
	for sx: float in [-2.0, 2.0]:
		for sz: float in [-1.0, 1.0]:
			arch.deco(Vector3(table_c.x + sx, 0.72, table_c.y + sz), Vector3(0.12, 1.44, 0.12), Color.html("495057"))
	arch.deco(Vector3(table_c.x - 1.4, 1.6, table_c.y + 0.4), Vector3(0.5, 0.04, 0.4), Color.html("e63946"), 20.0)   # paddle
	# --- cornhole boards ---
	for bx: float in [140.0, 152.0]:
		var board := arch.deco(Vector3(bx, 0.5, 60.0), Vector3(1.6, 0.12, 2.6), Color.html("b08968"))
		board.rotation_degrees.x = -12.0
		arch.deco(Vector3(bx, 0.62, 60.0 + (-0.35 if bx < 146.0 else 0.35)), Vector3(0.55, 0.14, 0.55), Color.html("2b2d42")).rotation_degrees.x = -12.0   # the hole
		arch.deco(Vector3(bx, 0.2, 60.0 + 1.1), Vector3(1.4, 0.4, 0.1), Color.html("6c584c"))
	arch.deco(Vector3(146.0, 0.12, 62.0), Vector3(0.35, 0.18, 0.35), Color.html("e63946"))                    # a bean bag
	arch.deco(Vector3(147.3, 0.12, 63.4), Vector3(0.35, 0.18, 0.35), Color.html("118ab2"))
	# --- basketball court ---
	arch.deco(Vector3(90.0, 0.03, 100.0), Vector3(24.0, 0.06, 15.0), Color.html("c9783b"))
	var hoop := Node3D.new()
	hoop.position = Vector3(90.0, 0.0, 93.5)
	add_child(hoop)
	var pole := arch.deco(Vector3(90.0, 2.0, 92.4), Vector3(0.3, 4.0, 0.3), Color.html("6c757d"))
	arch.deco(Vector3(90.0, 3.8, 93.0), Vector3(3.2, 2.0, 0.12), Color.html("f1faee"))
	arch.deco(Vector3(90.0, 3.1, 93.9), Vector3(1.0, 0.1, 1.0), Color.html("e63946"))
	pole.name = "HoopPole"
	var ball := MeshInstance3D.new()
	var bs := SphereMesh.new()
	bs.radius = 0.35
	bs.height = 0.7
	ball.mesh = bs
	ball.position = Vector3(86.0, 0.35, 102.0)
	ball.material_override = arch.flat(Color.html("e76f51"))
	add_child(ball)
	# --- the barn (change animal) ---
	arch.solid(Rect2(134.0, 14.0, 34.0, 22.0), 9.0, Color.html("c9a66b"), 2)
	arch.merlons(Rect2(134.0, 14.0, 34.0, 22.0), 9.0)
	arch.deco(Vector3(150.0, 3.5, 36.2), Vector3(8.0, 7.0, 0.3), Color.html("5c3d2e"))
	arch.label("BARN", Vector3(150.0, 15.0, 25.0), 96, 0.07)
	# --- the family car parked at the gate ---
	var car := Car.new()
	car.set_physics_process(false)
	car.position = Vector3(70.0, 0.0, 128.0)
	car.rotation.y = -PI / 2.0 + 0.25
	add_child(car)


func _build_decor() -> void:
	# a few camels near the barn
	for i in 3:
		_camel(Vector3(120.0 + i * 7.0, 0.0, 22.0 + (i % 2) * 6.0), _rng.randf() * TAU)
	# hay bales and a water tank
	for i in 5:
		var bale := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.9
		cyl.bottom_radius = 0.9
		cyl.height = 1.4
		cyl.radial_segments = 10
		bale.mesh = cyl
		bale.position = Vector3(165.0 - i * 2.2, 0.9, 48.0)
		bale.rotation_degrees.z = 90.0
		bale.material_override = arch.flat(Color.html("e0b84c"))
		add_child(bale)
	var tank := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = 2.4
	tc.bottom_radius = 2.4
	tc.height = 3.0
	tc.radial_segments = 12
	tank.mesh = tc
	tank.position = Vector3(18.0, 5.5, 100.0)
	tank.material_override = arch.flat(Color.html("dee2e6"))
	add_child(tank)
	for sx: float in [-1.5, 1.5]:
		for sz: float in [-1.5, 1.5]:
			arch.deco(Vector3(18.0 + sx, 2.0, 100.0 + sz), Vector3(0.3, 4.0, 0.3), Color.html("6c757d"))
	# palm groves
	for i in 70:
		var p := Vector2(_rng.randf_range(4.0, SIZE.x - 4.0), _rng.randf_range(4.0, SIZE.y - 6.0))
		var near_station := false
		for s: Vector2 in STATIONS.values():
			if s.distance_to(p) < 24.0:
				near_station = true
		if not near_station and p.distance_to(Vector2(90.0, 80.0)) > 8.0:
			_palms.append(p)


func _camel(pos: Vector3, yaw: float) -> void:
	var c := Node3D.new()
	c.position = pos
	c.rotation.y = yaw
	add_child(c)
	var fur := Color.html("c79a5a")
	_cb(c, Vector3(1.2, 1.4, 3.0), Vector3(0, 2.2, 0), fur)
	_cb(c, Vector3(0.9, 0.7, 0.9), Vector3(0, 3.2, 0.2), fur)                  # hump
	_cb(c, Vector3(0.5, 1.8, 0.5), Vector3(0, 3.0, -1.7), fur, Vector3(25, 0, 0))   # neck
	_cb(c, Vector3(0.55, 0.5, 0.9), Vector3(0, 3.9, -2.2), fur)                # head
	for sx: float in [-0.4, 0.4]:
		for sz: float in [-1.0, 1.0]:
			_cb(c, Vector3(0.22, 1.6, 0.22), Vector3(sx, 0.8, sz), fur.darkened(0.1))


func _cb(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = arch.flat(color)
	parent.add_child(mi)


func _build_palms() -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.25
	trunk.bottom_radius = 0.4
	trunk.height = 7.0
	trunk.radial_segments = 6
	var crown := SphereMesh.new()
	crown.radius = 2.6
	crown.height = 3.0
	crown.radial_segments = 8
	crown.rings = 4
	var trunks: Array = []
	var crowns: Array = []
	for p: Vector2 in _palms:
		trunks.append(Transform3D(Basis.IDENTITY, Vector3(p.x, 3.5, p.y)))
		crowns.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.4, 0.7, 1.4)), Vector3(p.x, 7.4, p.y)))
	arch.multi(trunk, arch.flat(Color.html("7f5539")), trunks)
	arch.multi(crown, arch.flat(Color.html("2d6a4f")), crowns)


func _spawn_zones() -> void:
	for id: String in STATIONS:
		var zone := LocationZone.new()
		zone.setup(id, STATIONS[id], 6.5)
		zone.car_entered.connect(func(zn: LocationZone) -> void: _active_zone = zn)
		zone.car_exited.connect(func(zn: LocationZone) -> void:
			if _active_zone == zn:
				_active_zone = null)
		add_child(zone)


func _spawn_animal() -> void:
	animal = FarmAnimal.new()
	animal.setup(Game.animal_id)
	var start := Vector2(90.0, 116.0)
	if STATIONS.has(Game.spawn_id):
		var s: Vector2 = STATIONS[Game.spawn_id]
		start = s + Vector2(0.0, 22.0 if s.y < 100.0 else -22.0)
		start.y = clampf(start.y, 8.0, SIZE.y - 8.0)
	animal.position = Vector3(start.x, 0.2, start.y)
	add_child(animal)
	cam = Camera3D.new()
	cam.top_level = true
	cam.far = 1500.0
	cam.fov = 62.0
	add_child(cam)
	cam.global_position = animal.position + Vector3(0.0, 9.5, 12.5)
	cam.make_current()


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var info := _label(hud, 26)
	info.text = "%s the %s  -  Al-Muzahimiyah Farm" % [Game.character()["name"], Game.animal()["name"]]
	info.position = Vector2(16, 10)
	var help := _label(hud, 18)
	help.text = "WASD walk   SPACE jump   E play   Walk into a glowing circle to play a game!   Esc menu"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt = _label(hud, 32)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 70)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _label(parent: Node, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l
