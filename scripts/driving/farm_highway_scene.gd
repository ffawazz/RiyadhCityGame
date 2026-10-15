class_name FarmHighwayScene
extends DriveScene
## The long road to Al-Muzahimiyah, styled after Riyadh's Qiddiya Road: a modern dual
## carriageway (3 lanes each way, concrete median with shrubs and tall lamp posts, guard
## rails, green overhead gantries, 120 km/h signs) crossing rocky desert under the layered
## limestone cliffs of the Tuwaiq escarpment. Traffic keeps right: drive east on the south
## carriageway. A slip road leads to the Baqalah pit stop; another to the farm gate.

const GATE_X := 6100.0
const LENGTH := 6200.0
const LANE_Z := 111.2            # middle lane of the eastbound (south) carriageway
const MEDIAN_TOP := 95.0
const MEDIAN_BOTTOM := 105.0

const ROCK_SHADER := """
shader_type spatial;
uniform vec4 c1 : source_color = vec4(0.72, 0.5, 0.32, 1.0);
uniform vec4 c2 : source_color = vec4(0.86, 0.68, 0.46, 1.0);
uniform vec4 cap : source_color = vec4(0.9, 0.8, 0.62, 1.0);
varying vec3 wpos;
varying vec3 wnrm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float band = step(0.5, fract(wpos.y / 7.0 + sin(wpos.x * 0.02 + wpos.z * 0.017) * 0.15));
	vec3 col = mix(c1.rgb, c2.rgb, band);
	if (wnrm.y > 0.5) { col = cap.rgb; }
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
"""


func _configure() -> void:
	world_rect = Rect2(0, 0, LENGTH, 200)
	fog_density = 0.0014
	fog_color = Color.html("f0d6ae")
	ground_color = Color.html("cfa972")
	auto_markings = false
	palm_collisions = false
	# carriageways: north (west-bound) and south (east-bound), plus the two slip roads
	roads.append(Rect2(0, 81.0, LENGTH, 14.0))
	roads.append(Rect2(0, 105.0, LENGTH, 14.0))
	roads.append(Rect2(3030, 119.0, 150, 36))      # Baqalah forecourt
	roads.append(Rect2(6030, 119.0, 170, 30))      # farm approach

	var white := Color.html("f4f1de")
	var yellow := Color.html("f2c230")
	# eastbound lanes z 105.8..116.6, westbound 83.4..94.2
	add_marking(true, 0, LENGTH, 109.4, 0.2, true, white)
	add_marking(true, 0, LENGTH, 113.0, 0.2, true, white)
	add_marking(true, 0, LENGTH, 87.0, 0.2, true, white)
	add_marking(true, 0, LENGTH, 90.6, 0.2, true, white)
	add_marking(true, 0, LENGTH, 116.6, 0.25, false, white)     # outer edge lines
	add_marking(true, 0, LENGTH, 83.4, 0.25, false, white)
	add_marking(true, 0, LENGTH, 105.8, 0.25, false, yellow)    # inner (median-side) edge lines
	add_marking(true, 0, LENGTH, 94.2, 0.25, false, yellow)

	add_zone("city_return", Vector2(60, LANE_Z), Vector2(60, 0))
	add_zone("baqalah", Vector2(3105, 137))
	add_zone("farm_gate", Vector2(6100, 134))
	spawns["city_return"] = {"pos": Vector2(120, LANE_Z), "yaw": -PI / 2.0}
	spawns["baqalah"] = {"pos": Vector2(3230, LANE_Z), "yaw": -PI / 2.0}
	spawns["farm_gate"] = {"pos": Vector2(6050, 134), "yaw": -PI / 2.0}
	default_spawn = {"pos": Vector2(140, LANE_Z), "yaw": -PI / 2.0}
	add_landmark(Rect2(3068, 162, 74, 30), 6.0, Color.html("e9d4a0"), "BAQALAH")


func _extra_info() -> String:
	return "    To farm: %.1f km" % maxf(0.0, (GATE_X - car.position.x) / 1000.0)


func _decorate() -> void:
	_build_median()
	_build_rails_and_signs()
	_build_desert()
	_build_escarpment()
	_build_farm_gate()
	# overhead gantries (eastbound view): Qiddiya Road first, then the km countdown
	add_gantry(Vector2(220, 100), 40.0, "طريق القدية\nQIDDIYA ROAD")
	for km in range(1, 6):
		add_gantry(Vector2(km * 1000.0, 100), 40.0, "المزاحمية\nAL-MUZAHIMIYAH  %d KM" % (6 - km))


func _build_median() -> void:
	# raised median, concrete barriers on both edges (solid), shrubs, tall double-arm lamps
	arch.deco(Vector3(LENGTH * 0.5, 0.08, 100.0), Vector3(LENGTH, 0.16, MEDIAN_BOTTOM - MEDIAN_TOP), Color.html("a69f8f"))
	var barrier_color := Color.html("c4beb0")
	arch.solid(Rect2(0, MEDIAN_TOP, LENGTH, 0.55), 0.9, barrier_color, 0)
	arch.solid(Rect2(0, MEDIAN_BOTTOM - 0.55, LENGTH, 0.55), 0.9, barrier_color, 0)
	var shrub_mesh := SphereMesh.new()
	shrub_mesh.radius = 0.8
	shrub_mesh.height = 1.2
	shrub_mesh.radial_segments = 6
	shrub_mesh.rings = 3
	var shrubs: Array = []
	var x := 5.0
	while x < LENGTH:
		var z := 100.0 + _rng.randf_range(-1.5, 1.5)
		shrubs.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * _rng.randf_range(0.8, 1.4)), Vector3(x, 0.6, z)))
		x += 3.5
	arch.multi(shrub_mesh, arch.flat(Color.html("5b7f45")), shrubs)
	var poles: Array = []
	var arms: Array = []
	var heads: Array = []
	var lx := 30.0
	while lx < LENGTH:
		poles.append(Transform3D(Basis.IDENTITY, Vector3(lx, 5.5, 100.0)))
		for side: float in [-1.0, 1.0]:
			arms.append(Transform3D(Basis.IDENTITY, Vector3(lx, 11.0, 100.0 + side * 3.0)))
			heads.append(Transform3D(Basis.IDENTITY, Vector3(lx, 10.8, 100.0 + side * 6.0)))
		lx += 45.0
	var pole := CylinderMesh.new()
	pole.top_radius = 0.14
	pole.bottom_radius = 0.22
	pole.height = 11.0
	pole.radial_segments = 6
	arch.multi(pole, arch.flat(Color.html("8d99ae")), poles)
	var arm := BoxMesh.new()
	arm.size = Vector3(0.18, 0.18, 6.4)
	arch.multi(arm, arch.flat(Color.html("8d99ae")), arms)
	var head := BoxMesh.new()
	head.size = Vector3(1.4, 0.25, 0.7)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color.html("fff4cc")
	glow.emission_enabled = true
	glow.emission = Color.html("ffe9a8")
	glow.emission_energy_multiplier = 0.8
	arch.multi(head, glow, heads)


func _build_rails_and_signs() -> void:
	var rail := Color.html("b8bec7")
	# steel guard rails along both outer edges, with gaps for the two slip roads
	arch.solid(Rect2(0, 80.55, LENGTH, 0.2), 0.7, rail, 0)
	arch.solid(Rect2(0, 119.3, 3030, 0.2), 0.7, rail, 0)
	arch.solid(Rect2(3180, 119.3, 2850, 0.2), 0.7, rail, 0)
	# 120 km/h limit signs on the south shoulder
	for sx in [800.0, 2600.0, 4400.0, 5600.0]:
		arch.deco(Vector3(sx, 1.6, 121.0), Vector3(0.12, 3.2, 0.12), Color.html("8d99ae"))
		var ring := arch.deco(Vector3(sx, 3.6, 121.0), Vector3(0.06, 1.3, 1.3), Color.html("d62828"))
		var disc := arch.deco(Vector3(sx - 0.05, 3.6, 121.0), Vector3(0.06, 0.95, 0.95), Color.html("fafafa"))
		var num := Label3D.new()
		num.text = "120"
		num.font_size = 64
		num.pixel_size = 0.012
		num.outline_size = 0
		num.modulate = Color.BLACK
		num.rotation_degrees.y = -90.0
		num.position = Vector3(-0.06, 0, 0)
		disc.add_child(num)
		ring.name = "Ring"


func _build_desert() -> void:
	var scrub_mesh := SphereMesh.new()
	scrub_mesh.radius = 1.0
	scrub_mesh.height = 1.4
	scrub_mesh.radial_segments = 6
	scrub_mesh.rings = 3
	var scrub: Array = []
	for i in 700:
		var z := _rng.randf_range(2.0, 76.0) if i % 2 == 0 else _rng.randf_range(124.0, 198.0)
		var s := _rng.randf_range(0.4, 1.5)
		scrub.append(Transform3D(Basis.IDENTITY.scaled(Vector3(s * 1.4, s * 0.8, s * 1.4)),
				Vector3(_rng.randf_range(0.0, LENGTH), 0.4 * s, z)))
	arch.multi(scrub_mesh, arch.flat(Color.html("7b7a3c")), scrub)
	var rock_mesh := BoxMesh.new()
	rock_mesh.size = Vector3(1.4, 0.9, 1.2)
	var rocks: Array = []
	for i in 350:
		var z2 := _rng.randf_range(2.0, 76.0) if i % 2 == 0 else _rng.randf_range(124.0, 198.0)
		var rs := _rng.randf_range(0.5, 2.2)
		rocks.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * rs),
				Vector3(_rng.randf_range(0.0, LENGTH), 0.3 * rs, z2)))
	arch.multi(rock_mesh, arch.flat(Color.html("9a7b5a")), rocks)
	# a few flat-topped acacia (talh) trees
	var trunks: Array = []
	var crowns: Array = []
	for i in 60:
		var tz := _rng.randf_range(10.0, 70.0) if i % 2 == 0 else _rng.randf_range(130.0, 190.0)
		var tx := _rng.randf_range(0.0, LENGTH)
		trunks.append(Transform3D(Basis.IDENTITY, Vector3(tx, 1.8, tz)))
		crowns.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.35, 1.0)), Vector3(tx, 4.2, tz)))
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.3
	trunk.height = 3.6
	trunk.radial_segments = 5
	arch.multi(trunk, arch.flat(Color.html("6b4f3a")), trunks)
	var crown := SphereMesh.new()
	crown.radius = 3.4
	crown.height = 6.8
	crown.radial_segments = 8
	crown.rings = 4
	arch.multi(crown, arch.flat(Color.html("6f8a3d")), crowns)


## Layered limestone cliffs of the Tuwaiq escarpment, north and south of the road.
func _build_escarpment() -> void:
	var shader := Shader.new()
	shader.code = ROCK_SHADER
	for i in 70:
		var north := i % 2 == 0
		var w := _rng.randf_range(120.0, 340.0)
		var d := _rng.randf_range(90.0, 220.0)
		var h := _rng.randf_range(35.0, 120.0)
		var cx := float(i) * 90.0 + _rng.randf_range(-40.0, 40.0)
		var cz := (-70.0 - d * 0.5 - _rng.randf_range(0.0, 140.0)) if north else (270.0 + d * 0.5 + _rng.randf_range(0.0, 140.0))
		_mesa(shader, Vector3(cx, h * 0.5 - 2.0, cz), Vector3(w, h, d))
		_mesa(shader, Vector3(cx + _rng.randf_range(-w * 0.2, w * 0.2), h + h * 0.22, cz + _rng.randf_range(-d * 0.15, d * 0.15)),
				Vector3(w * 0.55, h * 0.45, d * 0.55))


func _mesa(shader: Shader, pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("c1", Color.html(["b07a4a", "a9754a", "bf8a58"][_rng.randi() % 3]))
	m.set_shader_parameter("c2", Color.html(["d9b17f", "d2aa78", "e0bd8c"][_rng.randi() % 3]))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _build_farm_gate() -> void:
	# irrigated green fields beside the approach road
	arch.deco(Vector3(6115.0, 0.02, 175.0), Vector3(170.0, 0.06, 52.0), Color.html("6f9a4a"))
	for px in range(6050, 6190, 28):
		add_palm_at(Vector2(float(px), 153.0))
		add_palm_at(Vector2(float(px), 118.0 + 34.0))
	var gate := Color.html("e2c88f")
	for side: float in [-1.0, 1.0]:
		arch.solid(Rect2(6160.0, 134.0 + side * 12.0 - 1.5, 3.0, 3.0), 9.0, gate, 2)
	arch.deco(Vector3(6161.5, 10.0, 134.0), Vector3(3.0, 2.2, 27.0), gate)
	var lbl := Label3D.new()
	lbl.text = "مزرعة المزاحمية\nAL-MUZAHIMIYAH FARM"
	lbl.font_size = 64
	lbl.pixel_size = 0.04
	lbl.outline_size = 16
	lbl.rotation_degrees.y = -90.0
	lbl.position = Vector3(6159.8, 13.5, 134.0)
	add_child(lbl)
