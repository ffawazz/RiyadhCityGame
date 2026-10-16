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
	"farm_archery": Vector2(125, 112),
	"farm_swing": Vector2(48, 104),
	"farm_moto": Vector2(160, 100),
	"farm_lemons": Vector2(60, 28),
	"farm_goatfeed": Vector2(105, 18),
	"farm_eggs": Vector2(166, 74),
	"farm_sand": Vector2(28, 122),
	"farm_trampoline": Vector2(68, 110),
	"farm_slide": Vector2(32, 106),
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
var families: Array[FarmFamily] = []
var critters: Array[FarmCritter] = []
var _swing_nodes: Array = []
var _map: FarmMap
var _t: float = 0.0


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
	_spawn_families()
	_spawn_critters()
	_build_hud()


func _process(delta: float) -> void:
	_t += delta
	for sw: Node3D in _swing_nodes:
		sw.rotation.x = sin(_t * 1.8 + sw.position.x) * 0.5
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
	sun.shadow_enabled = not TouchPad.enabled   # phones: no shadows, keeps the frame rate up
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
	_build_archery()
	_build_swing()
	_build_moto()
	_build_lemons()
	_build_goat_pen()
	_build_coop()
	_build_sandpit()
	_build_trampoline()
	_build_slide()
	# --- the barn (change animal) ---
	arch.solid(Rect2(134.0, 14.0, 34.0, 22.0), 9.0, Color.html("c9a66b"), 2)
	arch.merlons(Rect2(134.0, 14.0, 34.0, 22.0), 9.0)
	arch.deco(Vector3(150.0, 3.5, 36.2), Vector3(8.0, 7.0, 0.3), Color.html("5c3d2e"))
	arch.label("BARN", Vector3(150.0, 15.0, 25.0), 96, 0.07)
	# --- the family car parked at the gate ---
	var car := Car.new()
	car.set_physics_process(false)
	car.remove_from_group("player")   # it is only a prop: it must not trigger the activity circles
	car.position = Vector3(70.0, 0.0, 128.0)
	car.rotation.y = -PI / 2.0 + 0.25
	add_child(car)


func _build_archery() -> void:
	var c := Vector2(125.0, 101.0)
	# shooting shelf with bottles (sand / water / pepsi / cola) and a flag showing the wind
	arch.deco(Vector3(c.x, 1.05, c.y), Vector3(9.0, 0.2, 1.4), Color.html("8b5e34"))
	for lx: float in [-4.0, 4.0]:
		arch.deco(Vector3(c.x + lx, 0.5, c.y), Vector3(0.3, 1.0, 1.0), Color.html("6f4518"))
	var liquids := ["d9b26a", "9fd8f5", "1d3f8f", "3b1a10"]
	for i in 8:
		var bx := c.x - 3.5 + i
		var col := Color.html(liquids[i % 4])
		arch.deco(Vector3(bx, 1.6, c.y), Vector3(0.4, 0.9, 0.4), col)
		arch.deco(Vector3(bx, 2.2, c.y), Vector3(0.16, 0.35, 0.16), Color(0.9, 0.95, 1.0))
	arch.deco(Vector3(c.x, 1.0, c.y + 11.0), Vector3(7.0, 0.1, 0.5), Color.html("f4f1de"))      # shooting line
	arch.deco(Vector3(c.x + 6.0, 2.5, c.y + 5.0), Vector3(0.12, 5.0, 0.12), Color.html("495057"))
	arch.deco(Vector3(c.x + 6.8, 4.6, c.y + 5.0), Vector3(1.4, 0.7, 0.05), Color.html("e63946"))


func _build_swing() -> void:
	var c := Vector3(48.0, 0.0, 95.0)
	for sz: float in [-1.6, 1.6]:
		arch.deco(c + Vector3(-3.6, 1.8, sz), Vector3(0.2, 3.8, 0.2), Color.html("e63946"), 0.0).rotation_degrees.z = 8.0
		arch.deco(c + Vector3(3.6, 1.8, sz), Vector3(0.2, 3.8, 0.2), Color.html("e63946"), 0.0).rotation_degrees.z = -8.0
	arch.deco(c + Vector3(0.0, 3.7, 0.0), Vector3(7.6, 0.25, 0.25), Color.html("c1121f"))
	for i in 2:
		var piv := Node3D.new()
		piv.position = c + Vector3(-1.5 + i * 3.0, 3.6, 0.0)
		add_child(piv)
		_swing_nodes.append(piv)
		for rz: float in [-0.35, 0.35]:
			var rope := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.05, 2.6, 0.05)
			rope.mesh = bm
			rope.position = Vector3(0.0, -1.3, rz)
			rope.material_override = arch.flat(Color.html("343a40"))
			piv.add_child(rope)
		var seat := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.5, 0.1, 0.9)
		seat.mesh = sm
		seat.position = Vector3(0.0, -2.6, 0.0)
		seat.material_override = arch.flat(Color.html("ffd166"))
		piv.add_child(seat)


func _build_moto() -> void:
	var c := Vector3(160.0, 0.0, 90.0)
	# dirt ramp
	var ramp := arch.deco(c + Vector3(0.0, 0.9, -3.0), Vector3(6.0, 0.4, 7.0), Color.html("a66a3b"))
	ramp.rotation_degrees.x = 16.0
	arch.deco(c + Vector3(0.0, 0.06, 4.0), Vector3(8.0, 0.1, 14.0), Color.html("b5895a"))     # dirt track patch
	# a parked dirt bike
	var bike := Node3D.new()
	bike.position = c + Vector3(-5.0, 0.0, 6.0)
	bike.rotation.y = 0.7
	add_child(bike)
	for wz: float in [-0.7, 0.7]:
		var w := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.38
		cm.bottom_radius = 0.38
		cm.height = 0.18
		cm.radial_segments = 12
		w.mesh = cm
		w.rotation_degrees.z = 90.0
		w.position = Vector3(0.0, 0.38, wz)
		w.material_override = arch.flat(Color.html("212529"))
		bike.add_child(w)
	_cb(bike, Vector3(0.25, 0.3, 1.0), Vector3(0, 0.95, 0.0), Color.html("e63946"))
	_cb(bike, Vector3(0.28, 0.12, 0.7), Vector3(0, 1.1, -0.35), Color.html("212529"))
	_cb(bike, Vector3(0.5, 0.06, 0.06), Vector3(0, 1.3, 0.55), Color.html("212529"))


func _build_lemons() -> void:
	var c := Vector3(60.0, 0.0, 28.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 6:
		var tp := c + Vector3(-9.0 + (i % 3) * 9.0, 0.0, -5.0 + (i / 3) * 10.0)
		var trunk := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.25
		tm.bottom_radius = 0.35
		tm.height = 2.2
		trunk.mesh = tm
		trunk.position = tp + Vector3(0, 1.1, 0)
		trunk.material_override = arch.flat(Color.html("7f5539"))
		add_child(trunk)
		var crown := MeshInstance3D.new()
		var cm := SphereMesh.new()
		cm.radius = 2.0
		cm.height = 3.6
		crown.mesh = cm
		crown.position = tp + Vector3(0, 3.4, 0)
		crown.material_override = arch.flat(Color.html("2d6a4f"))
		add_child(crown)
		for j in 7:
			var a := rng.randf() * TAU
			var lm := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.28
			sm.height = 0.56
			lm.mesh = sm
			lm.scale = Vector3(1.0, 0.8, 1.0)
			lm.position = tp + Vector3(cos(a) * 1.8, 3.0 + rng.randf() * 1.4, sin(a) * 1.8)
			lm.material_override = arch.flat(Color.html("ffe14d"))
			add_child(lm)
	arch.deco(c + Vector3(0, 0.9, 7.0), Vector3(1.6, 0.8, 1.0), Color.html("a47148"))        # lemon crate
	arch.deco(c + Vector3(0, 1.4, 7.0), Vector3(1.4, 0.2, 0.8), Color.html("ffe14d"))


func _build_goat_pen() -> void:
	var c := Vector2(105.0, 18.0)
	var half := Vector2(9.0, 6.0)
	for sx: float in [-1.0, 1.0]:
		arch.deco(Vector3(c.x + sx * half.x, 0.7, c.y), Vector3(0.25, 1.4, half.y * 2.0), Color.html("8b5e34"))
	for sz: float in [-1.0, 1.0]:
		arch.deco(Vector3(c.x, 0.7, c.y + sz * half.y), Vector3(half.x * 2.0, 1.4, 0.25), Color.html("8b5e34"))
	arch.deco(Vector3(c.x, 0.04, c.y), Vector3(half.x * 2.0, 0.08, half.y * 2.0), Color.html("c9b27a"))   # straw floor
	arch.deco(Vector3(c.x + 6.5, 1.0, c.y - 3.0), Vector3(2.4, 2.0, 1.6), Color.html("a47148"))            # trough
	arch.deco(Vector3(c.x + 6.5, 1.95, c.y - 3.0), Vector3(2.2, 0.2, 1.4), Color.html("e0b84c"))           # hay in it


func _build_coop() -> void:
	var c := Vector3(172.0, 0.0, 66.0)
	arch.deco(c + Vector3(0, 1.5, 0), Vector3(6.0, 3.0, 5.0), Color.html("b5651d"))
	var roof := arch.deco(c + Vector3(0, 3.5, 0), Vector3(7.0, 0.5, 6.0), Color.html("8d0801"))
	roof.rotation_degrees.z = 0.0
	arch.deco(c + Vector3(-3.05, 1.2, 0), Vector3(0.1, 1.2, 1.2), Color.html("2b2d42"))             # little door
	for i in 3:
		arch.deco(c + Vector3(-3.05, 2.4, -1.5 + i * 1.5), Vector3(0.1, 0.4, 0.8), Color.html("ffe66d"))   # windows
	# chicken run (fenced)
	for sz: float in [-1.0, 1.0]:
		arch.deco(Vector3(163.0, 0.5, c.z + sz * 6.0), Vector3(10.0, 1.0, 0.12), Color.html("8b5e34"))
	arch.deco(Vector3(158.0, 0.5, c.z), Vector3(0.12, 1.0, 12.0), Color.html("8b5e34"))


func _build_sandpit() -> void:
	var c := Vector3(28.0, 0.0, 122.0)
	arch.deco(c + Vector3(0, 0.15, 0), Vector3(10.0, 0.3, 10.0), Color.html("8b5e34"))
	arch.deco(c + Vector3(0, 0.32, 0), Vector3(9.2, 0.1, 9.2), Color.html("f0d58c"))
	# a sandcastle, bucket and spade
	arch.deco(c + Vector3(-1.5, 0.7, -1.0), Vector3(2.0, 0.8, 2.0), Color.html("e9c46a"))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			arch.deco(c + Vector3(-1.5 + sx * 0.8, 1.3, -1.0 + sz * 0.8), Vector3(0.5, 0.7, 0.5), Color.html("e9c46a"))
	arch.deco(c + Vector3(-1.5, 1.6, -1.0), Vector3(0.1, 1.0, 0.1), Color.html("e63946"))
	arch.deco(c + Vector3(2.0, 0.55, 1.5), Vector3(0.6, 0.6, 0.6), Color.html("ff5d8f"))           # bucket
	arch.deco(c + Vector3(3.0, 0.4, 0.8), Vector3(0.15, 0.1, 1.0), Color.html("3a86ff"), 25.0)     # spade


func _build_trampoline() -> void:
	var c := Vector3(68.0, 0.0, 110.0)
	var mat := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 3.0
	cm.bottom_radius = 3.0
	cm.height = 0.2
	cm.radial_segments = 20
	mat.mesh = cm
	mat.position = c + Vector3(0, 1.0, 0)
	mat.material_override = arch.flat(Color.html("1d3557"))
	add_child(mat)
	var rim := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 2.95
	rm.outer_radius = 3.35
	rm.rings = 20
	rm.ring_segments = 8
	rim.mesh = rm
	rim.position = c + Vector3(0, 1.05, 0)
	rim.material_override = arch.flat(Color.html("e63946"))
	add_child(rim)
	for i in 6:
		var a := float(i) / 6.0 * TAU
		arch.deco(c + Vector3(cos(a) * 3.1, 0.5, sin(a) * 3.1), Vector3(0.15, 1.0, 0.15), Color.html("495057"))
	# safety net poles
	for i in 8:
		var a := float(i) / 8.0 * TAU
		arch.deco(c + Vector3(cos(a) * 3.6, 1.9, sin(a) * 3.6), Vector3(0.1, 3.6, 0.1), Color.html("ffbe0b"))


func _build_slide() -> void:
	var c := Vector3(32.0, 0.0, 100.0)
	arch.deco(c + Vector3(0, 2.6, -1.5), Vector3(2.4, 0.2, 2.4), Color.html("f94144"))                 # platform
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			arch.deco(c + Vector3(sx * 1.1, 1.3, -1.5 + sz * 1.1), Vector3(0.14, 2.6, 0.14), Color.html("495057"))
	# ladder on the back
	for i in 6:
		arch.deco(c + Vector3(0, 0.45 + i * 0.42, -3.0), Vector3(1.6, 0.1, 0.1), Color.html("ffbe0b"))
	for sx: float in [-0.8, 0.8]:
		arch.deco(c + Vector3(sx, 1.4, -3.0), Vector3(0.1, 2.9, 0.1), Color.html("ffbe0b"))
	# the slide itself: a tilted blue ramp with side rails
	var ramp := arch.deco(c + Vector3(0, 1.45, 2.4), Vector3(1.6, 0.14, 5.6), Color.html("48cae4"))
	ramp.rotation_degrees.x = 24.0
	for sx: float in [-0.85, 0.85]:
		var rail := arch.deco(c + Vector3(sx, 1.7, 2.4), Vector3(0.1, 0.35, 5.6), Color.html("f94144"))
		rail.rotation_degrees.x = 24.0


func _spawn_critters() -> void:
	var avoid: Array[Rect2] = [
		Rect2(18, 46, 34, 24), Rect2(86, 31, 8, 8), Rect2(133, 12, 36, 24), Rect2(76, 90, 28, 20),
		Rect2(24, 94, 16, 16), Rect2(44, 92, 8, 14), Rect2(20, 96, 8, 10), Rect2(66, 107, 6, 6), Rect2(22, 117, 12, 10)]
	var whole := Rect2(6, 6, SIZE.x - 12, SIZE.y - 22)
	for i in 5:
		var cat := FarmCritter.new()
		cat.setup("cat", whole, 100 + i, avoid)
		add_child(cat)
		critters.append(cat)
	var spots: Array[Rect2] = [Rect2(8, 8, 40, 36), Rect2(110, 76, 30, 20), Rect2(50, 56, 24, 24), Rect2(120, 110, 30, 20), Rect2(70, 40, 12, 18)]
	for i in 6:
		var hog := FarmCritter.new()
		hog.setup("hedgehog", spots[i % spots.size()], 200 + i, avoid)
		add_child(hog)
		critters.append(hog)
	for i in 3:
		var goat := FarmCritter.new()
		goat.setup("goat", Rect2(97, 14, 16, 8), 300 + i)
		add_child(goat)
		critters.append(goat)
	for i in 4:
		var hen := FarmCritter.new()
		hen.setup("hen", Rect2(159, 62, 9, 9), 400 + i)
		add_child(hen)
		critters.append(hen)


func _spawn_families() -> void:
	# loops along the sandy paths, avoiding the pool, court and tables
	var loops: Array = [
		[Vector2(64, 78), Vector2(116, 78), Vector2(116, 88), Vector2(64, 88)],
		[Vector2(100, 44), Vector2(140, 44), Vector2(150, 54), Vector2(120, 54)],
		[Vector2(86, 122), Vector2(86, 112), Vector2(70, 108), Vector2(70, 122)],
		[Vector2(30, 30), Vector2(70, 30), Vector2(70, 12), Vector2(30, 12)],
		[Vector2(112, 124), Vector2(150, 124), Vector2(150, 112), Vector2(112, 112)],
	]
	var kids := [2, 1, 3, 2, 1]
	for i in loops.size():
		var wp: Array[Vector2] = []
		for v: Vector2 in loops[i]:
			wp.append(v)
		var fam := FarmFamily.new()
		fam.setup(wp, kids[i], i + 3, 1.3 + 0.15 * i)
		add_child(fam)
		families.append(fam)


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
	info.text = "%s is %s the %s  -  Al-Muzahimiyah Farm" % [Game.character()["name"], Game.animal()["name"], Game.animal()["species"]]
	info.position = Vector2(16, 10)
	var help := _label(hud, 18)
	help.text = "Joystick walk   JUMP   E play   MAP big map   Walk into a glowing circle to play a game!" if TouchPad.enabled else "WASD walk   SPACE jump   E play   M big map   Walk into a glowing circle to play a game!   Esc menu"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_map = FarmMap.new()
	_map.world = self
	hud.add_child(_map)
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
