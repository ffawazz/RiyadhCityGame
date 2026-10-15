class_name DriveScene
extends Node3D
## Base class for every scene where the player drives the car (3D, metres).
## Subclasses describe the map in _configure(); this class builds the world
## (ground, roads, building lots, palms), the car + chase camera, the HUD and
## the "press E to enter" logic. Map coordinates are Vector2(x, z) in metres.

const BUILDING_SHADER := """
shader_type spatial;
uniform vec4 base_color : source_color = vec4(0.8, 0.7, 0.5, 1.0);
uniform vec4 glass_color : source_color = vec4(0.25, 0.4, 0.55, 1.0);
uniform float windows = 1.0;
varying vec3 wpos;
varying vec3 wnrm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 col = base_color.rgb;
	if (windows > 0.5 && abs(wnrm.y) < 0.5 && wpos.y > 2.0) {
		float along = (abs(wnrm.x) > 0.5) ? wpos.z : wpos.x;
		vec2 cell = vec2(fract(along / 4.5), fract(wpos.y / 3.6));
		float w = step(0.2, cell.x) * step(cell.x, 0.8) * step(0.25, cell.y) * step(cell.y, 0.75);
		col = mix(col, glass_color.rgb, w);
	}
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
"""
const PALETTE := ["e8d8b0", "d9c7a0", "f0e6d0", "c9b58a", "e3c9a0", "bfa77a", "f5efe0", "d4b48c"]
const ENTER_MAX_SPEED := 9.0   # m/s - slow down to enter a place

static var _building_shader: Shader

var world_rect: Rect2 = Rect2(0, 0, 900, 700)
var roads: Array = []          # Rect2 (x, z, w, d): drivable asphalt
var blocks: Array = []         # Rect2: city cells that get filled with building lots
var reserved: Array = []       # Rect2: kept free of random lots (landmarks live here)
var zones: Array = []          # {"id": String, "pos": Vector2}
var spawns: Dictionary = {}    # spawn id -> {"pos": Vector2, "yaw": float}
var default_spawn: Dictionary = {"pos": Vector2(140, 100), "yaw": -PI / 2.0}
var fog_density: float = 0.0035
var palm_collisions: bool = true

var car: Car
var chase_cam: ChaseCamera
var _engine: EngineSound
var _active_zone: LocationZone
var _palms: Array = []
var _rng := RandomNumberGenerator.new()
var _info_label: Label
var _goals_label: Label
var _prompt_label: Label
var _speed_label: Label


# ---- override in subclasses ---------------------------------------------------

func _configure() -> void:
	pass


## Extra scenery (signs, gantries, landmarks...). Called after roads/lots exist.
func _decorate() -> void:
	pass


func _extra_info() -> String:
	return ""


# ---- helpers for subclasses ---------------------------------------------------

func add_zone(id: String, pos: Vector2, spawn_offset: Vector2 = Vector2.ZERO) -> void:
	zones.append({"id": id, "pos": pos})
	var off := spawn_offset
	if off == Vector2.ZERO:
		off = Vector2(45, 0) if pos.x < world_rect.get_center().x else Vector2(-45, 0)
	spawns[id] = {"pos": pos + off, "yaw": (-PI / 2.0) if off.x > 0.0 else (PI / 2.0)}


## A hand-placed building that also reserves its footprint so lots don't overlap it.
func add_landmark(rect: Rect2, height: float, color: Color, sign_text: String = "") -> void:
	reserved.append(rect)
	_add_building(rect, height, color, true, sign_text)


func add_palm_line(a: Vector2, b: Vector2, spacing: float) -> void:
	var length := a.distance_to(b)
	var count := int(length / spacing)
	for i in count + 1:
		var p := a.lerp(b, float(i) / maxf(1.0, float(count)))
		if not _on_road(p, 3.0):
			_palms.append(p)


## A sign gantry across a road. `facing_east` signs are read by drivers heading +X.
func add_gantry(pos: Vector2, road_width: float, text: String, facing_east: bool = true) -> void:
	var half := road_width * 0.5 + 2.0
	for s: float in [-1.0, 1.0]:
		_add_box_mesh(Vector3(pos.x, 4.0, pos.y + half * s), Vector3(0.8, 8.0, 0.8), Color.html("8d99ae"))
	_add_box_mesh(Vector3(pos.x, 7.6, pos.y), Vector3(1.0, 1.0, half * 2.0 + 0.8), Color.html("8d99ae"))
	var board := _add_box_mesh(Vector3(pos.x, 6.0, pos.y), Vector3(0.4, 3.0, road_width * 0.8), Color.html("1b7f3b"))
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 64
	lbl.pixel_size = 0.03
	lbl.outline_size = 0
	lbl.modulate = Color.WHITE
	lbl.rotation_degrees.y = -90.0 if facing_east else 90.0
	lbl.position = Vector3(-0.25 if facing_east else 0.25, 0, 0)
	board.add_child(lbl)


# ---- lifecycle ----------------------------------------------------------------

func _ready() -> void:
	_rng.seed = 7
	_configure()
	_build_environment()
	_build_ground_and_roads()
	_build_buildings()
	_decorate()
	_build_palms()
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
	_speed_label.text = "%d\nkm/h   G%d" % [kmh, car.gear] if car.forward_speed >= -0.5 else "%d\nkm/h   R" % kmh
	_info_label.text = "%s%s" % [Game.character()["name"], _extra_info()]
	if _active_zone:
		var slow := absf(car.forward_speed) <= ENTER_MAX_SPEED
		_prompt_label.text = ("Press E to enter: %s" % _active_zone.title) if slow else "Slow down to enter %s" % _active_zone.title
		if slow and Input.is_action_just_pressed("interact"):
			Router.enter_location(_active_zone.location_id)
	else:
		_prompt_label.text = ""
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
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color.html("efd9b4")
	env.fog_density = fog_density
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 150.0
	add_child(sun)


func _build_ground_and_roads() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = world_rect.size + Vector2(2400, 2400)
	ground.mesh = plane
	ground.position = Vector3(world_rect.get_center().x, -0.05, world_rect.get_center().y)
	ground.material_override = _flat(Color.html("c4ad7e"))
	add_child(ground)

	var asphalt := _flat(Color.html("3a3d42"))
	for r: Rect2 in roads:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(r.size.x, 0.1, r.size.y)
		mi.mesh = bm
		mi.position = Vector3(r.get_center().x, -0.04, r.get_center().y)
		mi.material_override = asphalt
		add_child(mi)

	# lane markings: one merged mesh for every dash + edge line
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r: Rect2 in roads:
		var horizontal := r.size.x >= r.size.y
		var length := r.size.x if horizontal else r.size.y
		var width := r.size.y if horizontal else r.size.x
		var mid := (r.get_center().y if horizontal else r.get_center().x)
		var start := (r.position.x if horizontal else r.position.y)
		var d := 0.0
		while d < length:
			_add_strip(st, horizontal, start + d, 4.0, mid, 0.25)
			d += 10.0
		for side: float in [-1.0, 1.0]:
			_add_strip(st, horizontal, start, length, mid + side * (width * 0.5 - 0.6), 0.2)
	var markings := MeshInstance3D.new()
	markings.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.html("f4f1de")
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	markings.material_override = mat
	markings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(markings)


## One white rectangle along a road: `along` start/length, centred on `across`.
func _add_strip(st: SurfaceTool, horizontal: bool, along: float, length: float, across: float, width: float) -> void:
	var y := 0.02
	var a := Vector3(along, y, across - width * 0.5) if horizontal else Vector3(across - width * 0.5, y, along)
	var b := Vector3(along + length, y, across + width * 0.5) if horizontal else Vector3(across + width * 0.5, y, along + length)
	var p := [Vector3(a.x, y, a.z), Vector3(b.x, y, a.z), Vector3(b.x, y, b.z), Vector3(a.x, y, b.z)]
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
				if _hits_reserved(lot):
					continue
				var dist := lot.get_center().distance_to(world_rect.get_center())
				var tall := clampf(1.0 - dist / 600.0, 0.1, 1.0)
				var h := _rng.randf_range(10.0, 14.0 + 38.0 * tall)
				_add_building(lot, h, Color.html(PALETTE[_rng.randi() % PALETTE.size()]), true)


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


func _building_material(color: Color, windows: bool) -> ShaderMaterial:
	if _building_shader == null:
		_building_shader = Shader.new()
		_building_shader.code = BUILDING_SHADER
	var m := ShaderMaterial.new()
	m.shader = _building_shader
	m.set_shader_parameter("base_color", color)
	m.set_shader_parameter("windows", 1.0 if windows else 0.0)
	return m


func _add_building(rect: Rect2, height: float, color: Color, windows: bool, sign_text: String = "") -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(rect.get_center().x, height * 0.5, rect.get_center().y)
	var shape := BoxShape3D.new()
	shape.size = Vector3(rect.size.x, height, rect.size.y)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = shape.size
	mi.mesh = bm
	mi.material_override = _building_material(color, windows)
	body.add_child(mi)
	if sign_text != "":
		var lbl := Label3D.new()
		lbl.text = sign_text
		lbl.font_size = 96
		lbl.pixel_size = 0.06
		lbl.outline_size = 24
		lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		lbl.position = Vector3(0, height * 0.5 + 5.0, 0)
		body.add_child(lbl)
	add_child(body)


func _add_box_mesh(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _flat(color)
	add_child(mi)
	return mi


func _flat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	return m


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
	var trunks := _multimesh(trunk_mesh, _flat(Color.html("7f5539")))
	var crowns := _multimesh(crown_mesh, _flat(Color.html("2d6a4f")))
	trunks.multimesh.instance_count = _palms.size()
	crowns.multimesh.instance_count = _palms.size()
	var palm_body := StaticBody3D.new()
	for i in _palms.size():
		var p: Vector2 = _palms[i]
		trunks.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(p.x, 3.5, p.y)))
		crowns.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(1.4, 0.7, 1.4)), Vector3(p.x, 7.4, p.y)))
		if palm_collisions:
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = 0.5
			cyl.height = 4.0
			cs.shape = cyl
			cs.position = Vector3(p.x, 2.0, p.y)
			palm_body.add_child(cs)
	add_child(palm_body)


func _multimesh(mesh: Mesh, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)
	return mmi


func _build_walls() -> void:
	var body := StaticBody3D.new()
	var r := world_rect
	var t := 10.0
	for rect in [
			Rect2(r.position.x - t, r.position.y - t, r.size.x + 2.0 * t, t),
			Rect2(r.position.x - t, r.end.y, r.size.x + 2.0 * t, t),
			Rect2(r.position.x - t, r.position.y, t, r.size.y),
			Rect2(r.end.x, r.position.y, t, r.size.y)]:
		var rr: Rect2 = rect
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(rr.size.x, 8.0, rr.size.y)
		cs.shape = box
		cs.position = Vector3(rr.get_center().x, 4.0, rr.get_center().y)
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
	car.position = Vector3(pos.x, 0.0, pos.y)
	car.rotation.y = spawn["yaw"]
	add_child(car)
	_engine = EngineSound.new()
	car.add_child(_engine)
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

	_prompt_label = _hud_label(hud, 30)
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 70)
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_label.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var help := _hud_label(hud, 16)
	help.text = "W/S gas & brake   A/D steer   SPACE handbrake   C camera   E enter   Esc menu"
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _hud_label(parent: Node, font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l
