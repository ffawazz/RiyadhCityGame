class_name DriveScene
extends Node3D
## Base class for every scene where the player drives the car (3D, metres).
## Subclasses describe the map in _configure(); this class builds the world
## (ground, roads, lane markings, sidewalks, building lots, palms, lamps), the car +
## chase camera, the HUD and the "press E to enter" logic.
## Map coordinates are Vector2(x, z) in metres. Architecture comes from RiyadhBuilder.

const ENTER_MAX_SPEED := 9.0   # m/s - slow down to enter a place
const SIDEWALK_COLOR := "a39d90"

var world_rect: Rect2 = Rect2(0, 0, 900, 700)
var roads: Array = []          # Rect2 (x, z, w, d): drivable asphalt
var blocks: Array = []         # Rect2: city cells that get filled with building lots
var reserved: Array = []       # Rect2: kept free of random lots (landmarks live here)
var zones: Array = []          # {"id": String, "pos": Vector2}
var spawns: Dictionary = {}    # spawn id -> {"pos": Vector2, "yaw": float}
var default_spawn: Dictionary = {"pos": Vector2(140, 100), "yaw": -PI / 2.0}
var fog_density: float = 0.0035
var fog_color: Color = Color.html("efd9b4")
var ground_color: Color = Color.html("c4ad7e")
var palm_collisions: bool = true
var flat_skip: Array = []     # road rects NOT drawn flat (the scene draws them itself)
var auto_markings: bool = true # centre dashes + edge lines for every road rect
var markings: Array = []       # custom lane lines, see add_marking()
var arch: RiyadhBuilder

var car: Car
var chase_cam: ChaseCamera
var _engine: EngineSound
var _active_zone: LocationZone
var _palms: Array = []
var _lamps: Array = []
var _rng := RandomNumberGenerator.new()
var _info_label: Label
var _goals_label: Label
var _prompt_label: Label
var _speed_label: Label
var _health_label: Label
var _toast_label: Label
var _toast_t: float = 0.0


# ---- override in subclasses ---------------------------------------------------

func _configure() -> void:
	pass


## Extra scenery (signs, landmarks, gantries...). Called after roads and lots exist.
func _decorate() -> void:
	pass


## Override to choose what stands on a lot. Default: a mid-rise block.
func _build_lot(lot: Rect2) -> void:
	arch.midrise(lot, _rng.randf_range(12.0, 28.0), arch.sand_color())


func _extra_info() -> String:
	return ""


## Ground height at (x, z). Override for hills / the roller-coaster road.
func ground_height(_x: float, _z: float) -> float:
	return 0.0


# ---- helpers for subclasses ---------------------------------------------------

func add_zone(id: String, pos: Vector2, spawn_offset: Vector2 = Vector2.ZERO) -> void:
	zones.append({"id": id, "pos": pos})
	var off := spawn_offset
	if off == Vector2.ZERO:
		off = Vector2(45, 0) if pos.x < world_rect.get_center().x else Vector2(-45, 0)
	spawns[id] = {"pos": pos + off, "yaw": (-PI / 2.0) if off.x > 0.0 else (PI / 2.0)}


## A hand-placed Najdi-style building that also reserves its footprint so no lot overlaps it.
## (Subclasses call this from _decorate/_configure-time data; the builder exists by then
## only for _decorate, so landmarks are queued and built in _build_buildings.)
func add_landmark(rect: Rect2, height: float, color: Color, sign_text: String = "") -> void:
	reserved.append(rect)
	_landmarks.append({"rect": rect, "height": height, "color": color, "text": sign_text})


func add_palm_at(p: Vector2) -> void:
	_palms.append(p)


func add_palm_line(a: Vector2, b: Vector2, spacing: float) -> void:
	var count := int(a.distance_to(b) / spacing)
	for i in count + 1:
		var p := a.lerp(b, float(i) / maxf(1.0, float(count)))
		if not _on_road(p, 3.0):
			_palms.append(p)


func add_lamp_line(a: Vector2, b: Vector2, spacing: float) -> void:
	var count := int(a.distance_to(b) / spacing)
	for i in count + 1:
		var p := a.lerp(b, float(i) / maxf(1.0, float(count)))
		if not _on_road(p, 1.0):
			_lamps.append(p)


## One painted line. `horizontal` roads run along x; `across` is that line's z (or x).
func add_marking(horizontal: bool, along: float, length: float, across: float, width: float,
		dashed: bool, color: Color = Color.html("f4f1de")) -> void:
	markings.append({"h": horizontal, "along": along, "length": length, "across": across,
			"width": width, "dashed": dashed, "color": color})


## A green overhead sign gantry across a road. Read by drivers heading +X.
func add_gantry(pos: Vector2, road_width: float, text: String) -> void:
	var half := road_width * 0.5 + 2.0
	var steel := Color.html("8d99ae")
	for side: float in [-1.0, 1.0]:
		arch.deco(Vector3(pos.x, 5.0, pos.y + half * side), Vector3(0.9, 10.0, 0.9), steel)
	arch.deco(Vector3(pos.x, 9.4, pos.y), Vector3(1.0, 1.0, half * 2.0 + 0.9), steel)
	var board := arch.deco(Vector3(pos.x, 6.6, pos.y), Vector3(0.4, 4.8, minf(road_width * 0.8, 34.0)), Color.html("1b7f3b"))
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 64
	lbl.pixel_size = 0.032
	lbl.outline_size = 0
	lbl.modulate = Color.WHITE
	lbl.rotation_degrees.y = -90.0
	lbl.position = Vector3(-0.25, 0, 0)
	board.add_child(lbl)


# ---- lifecycle ----------------------------------------------------------------

var _landmarks: Array = []

func _ready() -> void:
	_rng.seed = 7
	_configure()
	_build_environment()
	arch = RiyadhBuilder.new(self, _rng)
	_build_ground_and_roads()
	for l: Dictionary in _landmarks:
		arch.shop(l["rect"], l["height"], l["color"], l["text"])
	_build_buildings()
	_decorate()
	arch.finish()
	_build_palms()
	_build_lamps()
	_build_walls()
	_spawn_zones()
	_spawn_car()
	_build_hud()
	get_viewport().scaling_3d_scale = 0.6   # chunky low-res PS1 look


func _exit_tree() -> void:
	if is_inside_tree():
		get_viewport().scaling_3d_scale = 1.0


func _process(_delta: float) -> void:
	var kmh := int(absf(car.forward_speed) * 3.6)
	_speed_label.text = ("%d\nkm/h   G%d" % [kmh, car.gear]) if car.forward_speed >= -0.5 else ("%d\nkm/h   R" % kmh)
	_info_label.text = "%s%s" % [Game.character()["name"], _extra_info()]
	if _active_zone:
		var slow := absf(car.forward_speed) <= ENTER_MAX_SPEED
		_prompt_label.text = ("Press E to enter: %s" % _active_zone.title) if slow else ("Slow down to enter %s" % _active_zone.title)
		if slow and Input.is_action_just_pressed("interact"):
			var loc: Dictionary = Game.LOCATIONS[_active_zone.location_id]
			if loc["action"] == "repair":
				car.repair()
				_toast("Car repaired! Good as new")
			else:
				Router.enter_location(_active_zone.location_id)
	else:
		_prompt_label.text = ""
	var health := car.damage.health()
	_health_label.text = "Car: %d%%" % int(health)
	_health_label.add_theme_color_override("font_color", Color.html("80ed99") if health > 60.0 else (Color.html("ffd166") if health > 30.0 else Color.html("ff5d5d")))
	_toast_t = maxf(0.0, _toast_t - get_process_delta_time())
	_toast_label.visible = _toast_t > 0.0
	if Input.is_action_just_pressed("camera"):
		chase_cam.cycle_mode()
	if Input.is_action_just_pressed("ui_cancel"):
		Game.save_game()
		Router.go("main_menu")

	# audio / feel
	_engine.engine_hz = car.engine_hz
	_engine.load = car.throttle_amount
	_engine.screech = clampf((absf(car.lateral_speed) - 2.0) / 8.0, 0.0, 1.0)
	if car.impact > 4.0:
		_engine.thump = clampf(car.impact / 25.0, 0.1, 1.0)
		chase_cam.add_shake(clampf(car.impact / 30.0, 0.15, 1.0))
	car.impact = 0.0


# ---- world building -----------------------------------------------------------

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color.html("4f93d6")
	sky_mat.sky_horizon_color = Color.html("f2d9b0")
	sky_mat.ground_horizon_color = Color.html("f2d9b0")
	sky_mat.ground_bottom_color = Color.html("d9c79c")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.76, 0.66)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.8
	env.fog_enabled = true
	env.fog_light_color = fog_color
	env.fog_density = fog_density
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 150.0
	add_child(sun)


func _build_ground_and_roads() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = world_rect.size + Vector2(2400, 2400)
	ground.mesh = plane
	ground.position = Vector3(world_rect.get_center().x, -0.05, world_rect.get_center().y)
	ground.material_override = arch.flat(ground_color)
	add_child(ground)

	var asphalt := arch.flat(Color.html("3a3d42"))
	for r: Rect2 in roads:
		if flat_skip.has(r):
			continue
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(r.size.x, 0.1, r.size.y)
		mi.mesh = bm
		mi.position = Vector3(r.get_center().x, -0.04, r.get_center().y)
		mi.material_override = asphalt
		add_child(mi)

	# raised sidewalks around every city block
	for b: Rect2 in blocks:
		var slab := b.grow(6.0)
		var sm := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(slab.size.x, 0.12, slab.size.y)
		sm.mesh = sb
		sm.position = Vector3(slab.get_center().x, 0.05, slab.get_center().y)
		sm.material_override = arch.flat(Color.html(SIDEWALK_COLOR))
		add_child(sm)
	_build_markings()


func _build_markings() -> void:
	var all: Array = markings.duplicate()
	if auto_markings:
		var white := Color.html("f4f1de")
		for r: Rect2 in roads:
			var horizontal := r.size.x >= r.size.y
			var length := r.size.x if horizontal else r.size.y
			var width := r.size.y if horizontal else r.size.x
			var mid := r.get_center().y if horizontal else r.get_center().x
			var start := r.position.x if horizontal else r.position.y
			all.append({"h": horizontal, "along": start, "length": length, "across": mid,
					"width": 0.25, "dashed": true, "color": white})
			for side: float in [-1.0, 1.0]:
				all.append({"h": horizontal, "along": start, "length": length,
						"across": mid + side * (width * 0.5 - 0.6), "width": 0.2, "dashed": false, "color": white})
	var tools: Dictionary = {}   # colour hex -> SurfaceTool
	for m: Dictionary in all:
		var col: Color = m["color"]
		var key := col.to_html()
		if not tools.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[key] = st
		var tool: SurfaceTool = tools[key]
		var along: float = m["along"]
		var length2: float = m["length"]
		if m["dashed"]:
			var d := 0.0
			while d < length2:
				_add_strip(tool, m["h"], along + d, minf(4.0, length2 - d), m["across"], m["width"])
				d += 10.0
		else:
			_add_strip(tool, m["h"], along, length2, m["across"], m["width"])
	for key: String in tools:
		var done: SurfaceTool = tools[key]
		var mi := MeshInstance3D.new()
		mi.mesh = done.commit()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.html(key)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


## One painted rectangle along a road: `along` start/length, centred on `across`.
func _add_strip(st: SurfaceTool, horizontal: bool, along: float, length: float, across: float, width: float) -> void:
	var y := 0.02
	var x0 := along if horizontal else across - width * 0.5
	var x1 := along + length if horizontal else across + width * 0.5
	var z0 := across - width * 0.5 if horizontal else along
	var z1 := across + width * 0.5 if horizontal else along + length
	var p := [Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1)]
	st.set_normal(Vector3.UP)
	for idx in [0, 1, 2, 0, 2, 3]:
		st.add_vertex(p[idx])


func _build_buildings() -> void:
	for b: Rect2 in blocks:
		var cols := maxi(1, int(b.size.x / 60.0))
		var rows := maxi(1, int(b.size.y / 60.0))
		var cw := b.size.x / cols
		var ch := b.size.y / rows
		for i in cols:
			for j in rows:
				var lot := Rect2(b.position.x + i * cw + 4.0, b.position.y + j * ch + 4.0, cw - 8.0, ch - 8.0)
				if not _hits_reserved(lot):
					_build_lot(lot)


func _hits_reserved(r: Rect2) -> bool:
	for x: Rect2 in reserved:
		if x.intersects(r):
			return true
	return false


func _on_road(p: Vector2, margin: float) -> bool:
	for r: Rect2 in roads:
		if r.grow(margin).has_point(p):
			return true
	return false


func _build_palms() -> void:
	if _palms.is_empty():
		return
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.25
	trunk_mesh.bottom_radius = 0.4
	trunk_mesh.height = 7.0
	trunk_mesh.radial_segments = 6
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 2.6
	crown_mesh.height = 3.0
	crown_mesh.radial_segments = 8
	crown_mesh.rings = 4
	var trunks: Array = []
	var crowns: Array = []
	var palm_body := StaticBody3D.new()
	for p: Vector2 in _palms:
		trunks.append(Transform3D(Basis.IDENTITY, Vector3(p.x, 3.5, p.y)))
		crowns.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.4, 0.7, 1.4)), Vector3(p.x, 7.4, p.y)))
		if palm_collisions:
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = 0.5
			cyl.height = 4.0
			cs.shape = cyl
			cs.position = Vector3(p.x, 2.0, p.y)
			palm_body.add_child(cs)
	arch.multi(trunk_mesh, arch.flat(Color.html("7f5539")), trunks)
	arch.multi(crown_mesh, arch.flat(Color.html("2d6a4f")), crowns)
	add_child(palm_body)


func _build_lamps() -> void:
	if _lamps.is_empty():
		return
	var poles: Array = []
	var heads: Array = []
	for p: Vector2 in _lamps:
		poles.append(Transform3D(Basis.IDENTITY, Vector3(p.x, 4.5, p.y)))
		heads.append(Transform3D(Basis.IDENTITY, Vector3(p.x, 9.1, p.y)))
	var pole := CylinderMesh.new()
	pole.top_radius = 0.1
	pole.bottom_radius = 0.16
	pole.height = 9.0
	pole.radial_segments = 6
	arch.multi(pole, arch.flat(Color.html("6c757d")), poles)
	var head := BoxMesh.new()
	head.size = Vector3(1.8, 0.25, 0.5)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color.html("fff4cc")
	glow.emission_enabled = true
	glow.emission = Color.html("ffe9a8")
	glow.emission_energy_multiplier = 0.8
	arch.multi(head, glow, heads)


func _build_walls() -> void:
	var body := StaticBody3D.new()
	var r := world_rect
	var t := 10.0
	for rect: Rect2 in [
			Rect2(r.position.x - t, r.position.y - t, r.size.x + 2.0 * t, t),
			Rect2(r.position.x - t, r.end.y, r.size.x + 2.0 * t, t),
			Rect2(r.position.x - t, r.position.y, t, r.size.y),
			Rect2(r.end.x, r.position.y, t, r.size.y)]:
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(rect.size.x, 8.0, rect.size.y)
		cs.shape = box
		cs.position = Vector3(rect.get_center().x, 4.0, rect.get_center().y)
		body.add_child(cs)
	add_child(body)


func _spawn_zones() -> void:
	for z: Dictionary in zones:
		var zone := LocationZone.new()
		zone.setup(z["id"], z["pos"])
		zone.car_entered.connect(func(zn: LocationZone) -> void: _active_zone = zn)
		zone.car_exited.connect(func(zn: LocationZone) -> void:
			if _active_zone == zn:
				_active_zone = null)
		add_child(zone)


func _spawn_car() -> void:
	var spawn: Dictionary = spawns.get(Game.spawn_id, default_spawn)
	var pos: Vector2 = spawn["pos"]
	car = Car.new()
	car.ground_fn = ground_height
	car.position = Vector3(pos.x, ground_height(pos.x, pos.y), pos.y)
	car.rotation.y = spawn["yaw"]
	add_child(car)
	_engine = EngineSound.new()
	car.add_child(_engine)
	for child in get_children():
		if child is Traffic:
			(child as Traffic).player = car
	car.crashed.connect(_on_crash)
	chase_cam = ChaseCamera.new()
	chase_cam.target = car
	add_child(chase_cam)
	chase_cam.snap_to_target()


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	_info_label = _hud_label(hud, 24)
	_info_label.position = Vector2(16, 10)

	var minimap := Minimap.new(self)
	minimap.position = Vector2(16, 50)
	hud.add_child(minimap)

	_goals_label = _hud_label(hud, 20)
	_goals_label.text = "Today:\n" + "\n".join(Game.daily_lines())
	_goals_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_goals_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	_speed_label = _hud_label(hud, 44)
	_speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_speed_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	_speed_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_speed_label.grow_vertical = Control.GROW_DIRECTION_BEGIN

	_health_label = _hud_label(hud, 24)
	_health_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 20)
	_health_label.position.y -= 150.0
	_health_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN

	_toast_label = _hud_label(hud, 34)
	_toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 110)
	_toast_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_label.visible = false

	_prompt_label = _hud_label(hud, 30)
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 70)
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_label.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var help := _hud_label(hud, 16)
	help.text = "W/S gas & brake   A/D steer   SPACE handbrake   C camera   E enter   Esc menu"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _toast(text: String) -> void:
	_toast_label.text = text
	_toast_t = 2.5


func _on_crash(strength: float) -> void:
	var health := car.damage.health()
	if health < 25.0:
		_toast("The car is wrecked! Visit Mazda Service or go home to repair it")
	elif strength > 12.0:
		_toast("CRASH!")


func _hud_label(parent: Node, font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l
