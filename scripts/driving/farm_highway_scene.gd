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

## The "roller coaster" road: a bumpy stretch of rolling humps just before the farm.
const BUMP_X0 := 5000.0
const BUMP_X1 := 5700.0
const BUMP_WAVELENGTH := 50.0
const BUMP_AMPLITUDE := 2.0
const BUMP_Z0 := 74.0            # embankment foot (north)
const BUMP_Z1 := 126.0           # embankment foot (south)

## The big downhill: the road climbs a long ridge and then plunges down a steep slope just
## before the Baqalah pit stop - the best part of the ride.
const SLOPE_X0 := 2150.0
const SLOPE_CREST := 2600.0
const SLOPE_X1 := 2900.0
const SLOPE_H := 40.0
const SLOPE_Z0 := 14.0           # embankment foot (north)
const SLOPE_Z1 := 186.0          # embankment foot (south)

## Al-Kharrarah Park slip road (south side), halfway between the Baqalah and the roller coaster.
const PARK_X := 4105.0

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


func _flat_segs() -> Array:
	return [Vector2(0.0, SLOPE_X0), Vector2(SLOPE_X1, BUMP_X0), Vector2(BUMP_X1, LENGTH)]


func _in_hills(x: float) -> bool:
	return (x > SLOPE_X0 - 6.0 and x < SLOPE_X1 + 6.0) or (x > BUMP_X0 - 6.0 and x < BUMP_X1 + 6.0)


func _configure() -> void:
	damage_enabled = false          # the farm road is a happy ride: bumps never damage the car
	world_rect = Rect2(0, 0, LENGTH, 200)
	fog_density = 0.0014
	fog_color = Color.html("f0d6ae")
	ground_color = Color.html("cfa972")
	auto_markings = false
	palm_collisions = false
	# carriageways: north (west-bound) and south (east-bound), plus the two slip roads.
	# The bumpy section is drawn separately (see _build_bumpy_road), so flat road skips it.
	for z0: float in [81.0, 105.0]:
		for seg: Vector2 in _flat_segs():
			roads.append(Rect2(seg.x, z0, seg.y - seg.x, 14.0))
		for hv: Vector2 in [Vector2(BUMP_X0, BUMP_X1), Vector2(SLOPE_X0, SLOPE_X1)]:
			var hilly := Rect2(hv.x, z0, hv.y - hv.x, 14.0)
			roads.append(hilly)
			flat_skip.append(hilly)
	roads.append(Rect2(3030, 119.0, 150, 36))      # Baqalah forecourt
	roads.append(Rect2(PARK_X - 75.0, 119.0, 150, 36))   # Al-Kharrarah Park slip road
	roads.append(Rect2(6030, 119.0, 170, 30))      # farm approach

	var white := Color.html("f4f1de")
	var yellow := Color.html("f2c230")
	for seg: Vector2 in _flat_segs():
		var len := seg.y - seg.x
		# eastbound lanes z 105.8..116.6, westbound 83.4..94.2
		for zl: float in [109.4, 113.0, 87.0, 90.6]:
			add_marking(true, seg.x, len, zl, 0.2, true, white)
		for zl: float in [116.6, 83.4]:
			add_marking(true, seg.x, len, zl, 0.25, false, white)     # outer edge lines
		for zl: float in [105.8, 94.2]:
			add_marking(true, seg.x, len, zl, 0.25, false, yellow)    # inner (median-side) edge lines

	add_zone("city_return", Vector2(60, LANE_Z), Vector2(60, 0))
	add_zone("baqalah", Vector2(3105, 137))
	add_zone("kharrarah", Vector2(PARK_X, 137))
	spawns["kharrarah"] = {"pos": Vector2(PARK_X + 150.0, LANE_Z), "yaw": -PI / 2.0}
	add_zone("farm_gate", Vector2(6100, 134))
	spawns["city_return"] = {"pos": Vector2(120, LANE_Z), "yaw": -PI / 2.0}
	spawns["baqalah"] = {"pos": Vector2(3230, LANE_Z), "yaw": -PI / 2.0}
	spawns["farm_gate"] = {"pos": Vector2(6050, 134), "yaw": -PI / 2.0}
	default_spawn = {"pos": Vector2(140, LANE_Z), "yaw": -PI / 2.0}
	add_landmark(Rect2(3068, 162, 74, 30), 6.0, Color.html("e9d4a0"), "BAQALAH")
	add_landmark(Rect2(PARK_X - 40.0, 163, 80, 20), 5.0, Color.html("b7e4c7"), "AL-KHARRARAH PARK")


## The roller-coaster section: smooth humps (always above the desert floor), with sloped
## embankments at the sides. Everything that drives here (player + traffic) follows it.
func ground_height(x: float, z: float) -> float:
	if x > SLOPE_X0 and x < SLOPE_X1 and z > SLOPE_Z0 and z < SLOPE_Z1:
		var prof := smoothstep(SLOPE_X0, SLOPE_CREST, x) if x < SLOPE_CREST else 1.0 - smoothstep(SLOPE_CREST, SLOPE_X1, x)
		var side_s := clampf(minf(z - SLOPE_Z0, SLOPE_Z1 - z) / (81.0 - SLOPE_Z0), 0.0, 1.0)
		return SLOPE_H * prof * side_s
	if x <= BUMP_X0 or x >= BUMP_X1 or z <= BUMP_Z0 or z >= BUMP_Z1:
		return 0.0
	var ease_in_out := clampf(minf(x - BUMP_X0, BUMP_X1 - x) / 40.0, 0.0, 1.0)
	var wave := 0.5 - 0.5 * cos(TAU * (x - BUMP_X0) / BUMP_WAVELENGTH)
	var side := clampf(minf(z - BUMP_Z0, BUMP_Z1 - z) / 7.0, 0.0, 1.0)
	return BUMP_AMPLITUDE * ease_in_out * wave * side


func _extra_info() -> String:
	return "    To farm: %.1f km" % maxf(0.0, (GATE_X - car.position.x) / 1000.0)


func _decorate() -> void:
	_build_median()
	_build_bumpy_road()
	_build_rails_and_signs()
	_build_traffic()
	_build_desert()
	_build_escarpment()
	_build_farm_gate()
	# overhead gantries (eastbound view): Qiddiya Road first, then the km countdown
	add_gantry(Vector2(220, 100), 40.0, "طريق القدية\nQIDDIYA ROAD")
	for km in range(1, 6):
		if km == 5:
			continue   # the roller-coaster warning gantry takes this spot
		add_gantry(Vector2(km * 1000.0, 100), 40.0, "المزاحمية\nAL-MUZAHIMIYAH  %d KM" % (6 - km))
	add_gantry(Vector2(BUMP_X0 - 160.0, 100), 40.0, "طريق الرولركوستر\nROLLER COASTER ROAD  80")
	add_gantry(Vector2(SLOPE_X0 - 150.0, 100), 40.0, "انحدار شديد\nSTEEP DOWNHILL AHEAD!")
	add_gantry(Vector2(PARK_X - 220.0, 100), 40.0, "منتزه الخرارة\nAL-KHARRARAH PARK  >>")


func _build_median() -> void:
	# raised median, concrete barriers on both edges (solid), shrubs, tall double-arm lamps
	var barrier_color := Color.html("c4beb0")
	for seg: Vector2 in _flat_segs():
		arch.deco(Vector3((seg.x + seg.y) * 0.5, 0.08, 100.0), Vector3(seg.y - seg.x, 0.16, MEDIAN_BOTTOM - MEDIAN_TOP), Color.html("a69f8f"))
		arch.solid(Rect2(seg.x, MEDIAN_TOP, seg.y - seg.x, 0.55), 0.9, barrier_color, 0)
		arch.solid(Rect2(seg.x, MEDIAN_BOTTOM - 0.55, seg.y - seg.x, 0.55), 0.9, barrier_color, 0)
	var shrub_mesh := SphereMesh.new()
	shrub_mesh.radius = 0.8
	shrub_mesh.height = 1.2
	shrub_mesh.radial_segments = 6
	shrub_mesh.rings = 3
	var shrubs: Array = []
	var x := 5.0
	while x < LENGTH:
		if _in_hills(x):
			x += 3.5
			continue
		var z := 100.0 + _rng.randf_range(-1.5, 1.5)
		shrubs.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * _rng.randf_range(0.8, 1.4)), Vector3(x, 0.6, z)))
		x += 3.5
	arch.multi(shrub_mesh, arch.flat(Color.html("5b7f45")), shrubs)
	var poles: Array = []
	var arms: Array = []
	var heads: Array = []
	var lx := 30.0
	while lx < LENGTH:
		if _in_hills(lx):
			lx += 45.0
			continue
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
	# steel guard rails along both outer edges, with gaps for the slip roads
	for seg: Vector2 in _flat_segs():
		arch.solid(Rect2(seg.x, 80.55, seg.y - seg.x, 0.2), 0.7, rail, 0)
	for seg: Vector2 in [Vector2(0.0, SLOPE_X0), Vector2(SLOPE_X1, 3030.0), Vector2(3180.0, PARK_X - 75.0),
			Vector2(PARK_X + 75.0, BUMP_X0), Vector2(BUMP_X1, 6030.0)]:
		arch.solid(Rect2(seg.x, 119.3, seg.y - seg.x, 0.2), 0.7, rail, 0)
	# 120 km/h limit signs on the south shoulder
	for sx in [800.0, 1900.0, 3500.0, 4600.0, 5900.0]:
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
		var sx2 := _rng.randf_range(0.0, LENGTH)
		if _in_hills(sx2):
			continue
		scrub.append(Transform3D(Basis.IDENTITY.scaled(Vector3(s * 1.4, s * 0.8, s * 1.4)),
				Vector3(sx2, 0.4 * s, z)))
	arch.multi(scrub_mesh, arch.flat(Color.html("7b7a3c")), scrub)
	var rock_mesh := BoxMesh.new()
	rock_mesh.size = Vector3(1.4, 0.9, 1.2)
	var rocks: Array = []
	for i in 350:
		var z2 := _rng.randf_range(2.0, 76.0) if i % 2 == 0 else _rng.randf_range(124.0, 198.0)
		var rs := _rng.randf_range(0.5, 2.2)
		var rx := _rng.randf_range(0.0, LENGTH)
		if _in_hills(rx):
			continue
		rocks.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * rs),
				Vector3(rx, 0.3 * rs, z2)))
	arch.multi(rock_mesh, arch.flat(Color.html("9a7b5a")), rocks)
	# a few flat-topped acacia (talh) trees
	var trunks: Array = []
	var crowns: Array = []
	for i in 60:
		var tz := _rng.randf_range(10.0, 70.0) if i % 2 == 0 else _rng.randf_range(130.0, 190.0)
		var tx := _rng.randf_range(0.0, LENGTH)
		if _in_hills(tx):
			continue
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


## A hilly section (roller coaster / big slope) as one mesh: asphalt carriageways + painted median, sloped
## sandy embankments, and lane lines that follow every hump.
func _build_hilly_road(hx0: float, hx1: float, hz0: float, hz1: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var asphalt := Color.html("3a3d42")
	var sand := Color.html("b4925f")
	var zs := [hz0, 81.0, 119.0, hz1]
	var cols := [sand, asphalt, sand]
	var step := 2.0
	var x := hx0
	while x < hx1:
		var x2 := minf(x + step, hx1)
		for k in 3:
			_bump_quad(st, x, x2, zs[k], zs[k + 1], cols[k], 0.0)
		x = x2
	var white := Color.html("f4f1de")
	var yellow := Color.html("f2c230")
	var lines := [
		[109.4, 0.2, true, white], [113.0, 0.2, true, white], [87.0, 0.2, true, white], [90.6, 0.2, true, white],
		[116.6, 0.25, false, white], [83.4, 0.25, false, white],
		[105.8, 0.25, false, yellow], [94.2, 0.25, false, yellow], [99.8, 0.2, false, yellow], [100.2, 0.2, false, yellow]]
	for ln: Array in lines:
		var zc: float = ln[0]
		var half: float = float(ln[1]) * 0.5
		var i := 0
		x = hx0
		while x < hx1:
			var x2b := minf(x + step, hx1)
			if not ln[2] or (i % 5) < 2:
				_bump_quad(st, x, x2b, zc - half, zc + half, ln[3], 0.04)
			x = x2b
			i += 1
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mi.material_override = mat
	add_child(mi)


func _build_bumpy_road() -> void:
	_build_hilly_road(BUMP_X0, BUMP_X1, BUMP_Z0, BUMP_Z1)
	_build_hilly_road(SLOPE_X0, SLOPE_X1, SLOPE_Z0, SLOPE_Z1)


func _bump_quad(st: SurfaceTool, x0: float, x1: float, z0: float, z1: float, color: Color, lift: float) -> void:
	var p := [Vector3(x0, ground_height(x0, z0) + lift, z0), Vector3(x1, ground_height(x1, z0) + lift, z0),
			Vector3(x1, ground_height(x1, z1) + lift, z1), Vector3(x0, ground_height(x0, z1) + lift, z1)]
	for idx in [0, 1, 2, 0, 2, 3]:
		st.set_color(color)
		st.add_vertex(p[idx])


## Cars on all six lanes. Inner lanes are the fast ones.
func _build_traffic() -> void:
	var traffic := Traffic.new(self)
	add_child(traffic)
	var east := [[107.6, 36.0], [111.2, 31.0], [114.8, 26.0]]
	var west := [[92.4, 36.0], [88.8, 31.0], [85.2, 26.0]]
	for l: Array in east:
		traffic.add_lane(0, 1, l[0], 0.0, LENGTH, [], l[1], 12, Vector2(0.0, 500.0))
	for l: Array in west:
		traffic.add_lane(0, -1, l[0], 0.0, LENGTH, [], l[1], 12)
