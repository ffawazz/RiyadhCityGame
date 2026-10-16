class_name KharrarahParkScene
extends DriveScene
## Al-Kharrarah Park: a desert family park with a flat plaza (camping + BBQ, kites, boats on the
## seasonal rain lake with its glowing water) ringed by big sand dunes to drive the 4x4 on.
## Sidr and acacia trees dot the sand. Loose sand = less grip. Drive into a circle and press E.

const PLAZA := Vector2(260.0, 210.0)
const LAKE := Vector2(375.0, 255.0)
const LAKE_R := Vector2(58.0, 42.0)

var _kites: Array = []
var _t: float = 0.0


func _configure() -> void:
	world_rect = Rect2(0, 0, 520, 420)
	fog_density = 0.0012
	fog_color = Color.html("f4dcb4")
	ground_color = Color.html("dcc08a")
	auto_markings = false
	palm_collisions = false
	damage_enabled = false
	traction = 0.82                     # loose sand
	add_zone("park_bbq", Vector2(165, 215), Vector2(0, 40))
	add_zone("park_kite", Vector2(325, 125), Vector2(0, 40))
	add_zone("park_boat", Vector2(360, 200), Vector2(0, -40))
	add_zone("kharrarah_exit", Vector2(260, 408), Vector2(0, -38))
	spawns["kharrarah"] = {"pos": Vector2(260, 362), "yaw": 0.0}
	default_spawn = spawns["kharrarah"]


## Flat plaza in the middle, big dunes all round it (for the 4x4).
func ground_height(x: float, z: float) -> float:
	var d := sqrt(pow((x - PLAZA.x) / 1.25, 2.0) + pow(z - PLAZA.y, 2.0))
	var blend := smoothstep(120.0, 175.0, d)
	if blend <= 0.0:
		return 0.0
	var h := 0.5 + 0.5 * sin(x * 0.045 + sin(z * 0.03) * 2.0) * cos(z * 0.05 + sin(x * 0.02) * 1.5)
	h += 0.35 * (0.5 + 0.5 * sin(x * 0.11 + z * 0.09))
	# keep the entrance road flat so the car can drive in
	var corridor := smoothstep(26.0, 64.0, absf(x - 260.0))     # a flat strip leads in from the gate
	return 5.0 * h * blend * corridor


func _extra_info() -> String:
	return "    Al-Kharrarah Park  -  drive the dunes!"


func _process(delta: float) -> void:
	super(delta)
	_t += delta
	for k: Dictionary in _kites:
		var n: Node3D = k["node"]
		var base: Vector3 = k["base"]
		n.position = base + Vector3(sin(_t * 0.8 + float(k["ph"])) * 6.0, sin(_t * 1.1 + float(k["ph"])) * 3.0, cos(_t * 0.6 + float(k["ph"])) * 5.0)
		n.rotation.z = sin(_t * 1.6 + float(k["ph"])) * 0.4


func _decorate() -> void:
	_build_dunes()
	_build_lake()
	_build_trees()
	_build_camp()
	_build_kites()
	_build_gate()
	_build_walkway()
	_build_crowd()


## The sand as one mesh (the flat ground plane sits below it).
func _build_dunes() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 4.0
	var x := 0.0
	while x < world_rect.size.x:
		var z := 0.0
		while z < world_rect.size.y:
			var corners := [Vector2(x, z), Vector2(x + step, z), Vector2(x + step, z + step), Vector2(x, z + step)]
			var pts: Array = []
			for c: Vector2 in corners:
				pts.append(Vector3(c.x, ground_height(c.x, c.y) - 0.02, c.y))
			for idx in [0, 1, 2, 0, 2, 3]:
				var p: Vector3 = pts[idx]
				var shade := clampf(p.y / 5.0, 0.0, 1.0)
				st.set_color(Color.html("a88a58").lerp(Color.html("c4a66f"), shade))
				st.add_vertex(p)
			z += step
		x += step
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	mi.material_override = mat
	add_child(mi)


## "Liquid light lake": the rain pool that glows turquoise under the sun.
func _build_lake() -> void:
	var water := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.1
	cm.radial_segments = 32
	water.mesh = cm
	water.scale = Vector3(LAKE_R.x, 1.0, LAKE_R.y)
	water.position = Vector3(LAKE.x, 0.06, LAKE.y)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.1, 0.8, 0.85, 0.8)
	m.emission_enabled = true
	m.emission = Color(0.1, 0.7, 0.9)
	m.emission_energy_multiplier = 0.35
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	water.material_override = m
	add_child(water)
	var rim := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 1.0
	rm.bottom_radius = 1.0
	rm.height = 0.05
	rm.radial_segments = 32
	rim.mesh = rm
	rim.scale = Vector3(LAKE_R.x + 3.0, 1.0, LAKE_R.y + 3.0)
	rim.position = Vector3(LAKE.x, 0.02, LAKE.y)
	rim.material_override = arch.flat(Color.html("b79b68"))
	add_child(rim)
	arch.label("بحيرة الخرارة", Vector3(LAKE.x, 7.0, LAKE.y - 20.0), 72, 0.06)


func _build_trees() -> void:
	var trunks: Array = []
	var crowns: Array = []
	var acacia_t: Array = []
	var acacia_c: Array = []
	for i in 70:
		var p := Vector2(_rng.randf_range(10.0, 510.0), _rng.randf_range(10.0, 400.0))
		if Vector2(p.x, p.y).distance_to(LAKE) < 70.0 or Vector2(p.x, p.y).distance_to(Vector2(165, 215)) < 40.0 \
				or Vector2(p.x, p.y).distance_to(Vector2(260, 395)) < 40.0:
			continue
		var gy := ground_height(p.x, p.y)
		if i % 2 == 0:      # sidr: round, bushy
			trunks.append(Transform3D(Basis.IDENTITY, Vector3(p.x, gy + 1.2, p.y)))
			crowns.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.8, 1.0) * _rng.randf_range(0.8, 1.3)), Vector3(p.x, gy + 3.4, p.y)))
		else:               # acacia: flat umbrella
			acacia_t.append(Transform3D(Basis.IDENTITY, Vector3(p.x, gy + 2.0, p.y)))
			acacia_c.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.4, 0.35, 1.4)), Vector3(p.x, gy + 4.4, p.y)))
	var tm := CylinderMesh.new()
	tm.top_radius = 0.2
	tm.bottom_radius = 0.34
	tm.height = 2.4
	tm.radial_segments = 6
	arch.multi(tm, arch.flat(Color.html("6b4f3a")), trunks)
	var cm := SphereMesh.new()
	cm.radius = 2.6
	cm.height = 5.0
	cm.radial_segments = 8
	cm.rings = 4
	arch.multi(cm, arch.flat(Color.html("5f7f3a")), crowns)
	var tm2 := CylinderMesh.new()
	tm2.top_radius = 0.18
	tm2.bottom_radius = 0.3
	tm2.height = 4.0
	tm2.radial_segments = 5
	arch.multi(tm2, arch.flat(Color.html("6b4f3a")), acacia_t)
	var cm2 := SphereMesh.new()
	cm2.radius = 3.4
	cm2.height = 6.8
	cm2.radial_segments = 8
	cm2.rings = 4
	arch.multi(cm2, arch.flat(Color.html("7a9140")), acacia_c)


func _build_camp() -> void:
	var c := Vector3(165.0, 0.0, 195.0)
	# tents (triangular prisms) in family colours
	var tent_cols := ["e63946", "2a9d8f", "f4a261", "6a4c93"]
	for i in 4:
		var tp := c + Vector3(-16.0 + i * 11.0, 0.0, -9.0 + (i % 2) * 5.0)
		var tent := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.0
		pm.bottom_radius = 3.2
		pm.height = 3.0
		pm.radial_segments = 4
		tent.mesh = pm
		tent.position = tp + Vector3(0, 1.5, 0)
		tent.rotation_degrees.y = 45.0
		tent.material_override = arch.flat(Color.html(tent_cols[i]))
		add_child(tent)
	# majlis carpet + cushions
	arch.deco(c + Vector3(0, 0.05, 14.0), Vector3(14.0, 0.1, 8.0), Color.html("9d0208"))
	arch.deco(c + Vector3(0, 0.07, 14.0), Vector3(12.0, 0.1, 6.0), Color.html("e85d04"))
	for i in 5:
		arch.deco(c + Vector3(-5.0 + i * 2.5, 0.5, 11.0), Vector3(1.6, 0.8, 0.8), Color.html("1d3557"))
	# BBQ grill and fire pit
	arch.deco(c + Vector3(10.0, 0.9, 20.0), Vector3(3.0, 0.2, 1.6), Color.html("343a40"))
	for sx: float in [-1.2, 1.2]:
		arch.deco(c + Vector3(10.0 + sx, 0.45, 20.0), Vector3(0.15, 0.9, 0.15), Color.html("343a40"))
	arch.deco(c + Vector3(10.0, 1.05, 20.0), Vector3(2.6, 0.1, 1.2), Color.html("ff7b00"))
	var fire := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.0
	fm.bottom_radius = 0.6
	fm.height = 1.4
	fire.mesh = fm
	fire.position = c + Vector3(-9.0, 0.8, 20.0)
	var flame := StandardMaterial3D.new()
	flame.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.albedo_color = Color(1.0, 0.5, 0.1)
	fire.material_override = flame
	add_child(fire)
	for i in 6:
		var a := float(i) / 6.0 * TAU
		arch.deco(c + Vector3(-9.0 + cos(a) * 1.1, 0.25, 20.0 + sin(a) * 1.1), Vector3(0.5, 0.5, 0.5), Color.html("6c757d"))
	arch.label("التخييم والشواء", Vector3(c.x, 6.0, c.z + 4.0), 64, 0.05)


func _build_kites() -> void:
	var cols := ["e63946", "ffd60a", "3a86ff", "06d6a0", "ff5d8f", "9b5de5"]
	for i in 6:
		var kite := Node3D.new()
		var body := MeshInstance3D.new()
		var qm := BoxMesh.new()
		qm.size = Vector3(2.2, 3.0, 0.08)
		body.mesh = qm
		body.rotation_degrees.z = 0.0
		body.material_override = arch.flat(Color.html(cols[i]))
		kite.add_child(body)
		for k in 3:
			var tail := MeshInstance3D.new()
			var tm := BoxMesh.new()
			tm.size = Vector3(0.3, 0.3, 0.05)
			tail.mesh = tm
			tail.position = Vector3(sin(float(k)) * 0.4, -2.2 - k * 0.7, 0)
			tail.material_override = arch.flat(Color.html(cols[(i + k + 1) % 6]))
			kite.add_child(tail)
		var base := Vector3(300.0 + i * 12.0, 24.0 + (i % 3) * 5.0, 105.0 + (i % 2) * 14.0)
		kite.position = base
		add_child(kite)
		_kites.append({"node": kite, "base": base, "ph": float(i) * 1.3})
		# the string down to the ground
		arch.deco(Vector3(base.x, base.y * 0.5, base.z), Vector3(0.04, base.y, 0.04), Color.html("f1faee"))
	arch.label("الطائرات الورقية", Vector3(325.0, 14.0, 118.0), 64, 0.05)


func _build_gate() -> void:
	var gate := Color.html("c9a66b")
	for side: float in [-1.0, 1.0]:
		arch.solid(Rect2(260.0 + side * 16.0 - 1.5, 402.0, 3.0, 3.0), 7.0, gate, 2)
	arch.deco(Vector3(260.0, 7.6, 403.5), Vector3(35.0, 1.6, 2.0), gate)
	var lbl := Label3D.new()
	lbl.text = "منتزه الخرارة\nAL-KHARRARAH PARK"
	lbl.font_size = 64
	lbl.pixel_size = 0.03
	lbl.outline_size = 12
	lbl.position = Vector3(260.0, 10.2, 402.5)
	lbl.rotation_degrees.y = 180.0
	add_child(lbl)


## A paved walking path round the plaza with benches (the "mamsha").
func _build_walkway() -> void:
	var path_col := Color.html("bfae8c")
	arch.deco(Vector3(260.0, 0.04, 330.0), Vector3(8.0, 0.08, 150.0), path_col)             # from the gate
	arch.deco(Vector3(260.0, 0.04, 270.0), Vector3(240.0, 0.08, 6.0), path_col)
	for i in 6:
		var bx := 90.0 + i * 70.0
		arch.deco(Vector3(bx, 0.5, 276.0), Vector3(2.4, 0.5, 0.7), Color.html("8b5e34"))


## It is always busy here: parked cars by the tents, the lake and the gate, a seated family
## round the camp fire, and cars cruising over the sand.
func _build_crowd() -> void:
	var cols := [Color.html("f1faee"), Color.html("2b2d42"), Color.html("8d99ae"), Color.html("e63946"), Color.html("457b9d"),
			Color.html("e9c46a"), Color.html("6a994e"), Color.html("adb5bd"), Color.html("1d3557")]
	var kinds := ["suv", "suv", "sedan", "pickup", "van", "sedan", "suv"]
	var parked_spots: Array[Vector3] = []     # x, z, yaw
	for i in 5:       # beside the tents
		parked_spots.append(Vector3(120.0 + i * 11.0, 178.0 - (i % 2) * 3.0, PI * 0.5 + 0.2 * float(i % 3)))
	for i in 4:       # by the lake shore
		parked_spots.append(Vector3(300.0 + i * 12.0, 300.0 + (i % 2) * 6.0, PI * 0.9 - 0.3 * float(i)))
	for i in 4:       # near the kite field
		parked_spots.append(Vector3(285.0 + i * 13.0, 120.0 + (i % 2) * 5.0, 0.4 * float(i)))
	for i in 5:       # lined up along the entrance
		parked_spots.append(Vector3(215.0 if i < 3 else 305.0, 330.0 + (i % 3) * 14.0, PI * 0.5 if i < 3 else -PI * 0.5))
	for i in parked_spots.size():
		var pc := ParkCar.new()
		var sp := parked_spots[i]
		pc.setup_park(self, kinds[i % kinds.size()], cols[(i * 4) % cols.size()], Vector2(sp.x, sp.y), sp.z, true)
		add_child(pc)
	var loops: Array = [
		[Vector2(120, 110), Vector2(320, 100), Vector2(440, 150), Vector2(450, 340), Vector2(300, 345), Vector2(110, 325)],
		[Vector2(200, 255), Vector2(255, 165), Vector2(310, 205), Vector2(255, 275)],
		[Vector2(60, 80), Vector2(460, 80), Vector2(485, 385), Vector2(60, 370)],
	]
	var counts := [3, 2, 3]
	var speeds := [7.0, 5.0, 9.0]
	var n := 0
	for li in loops.size():
		var wp: Array[Vector2] = []
		for v: Vector2 in loops[li]:
			wp.append(v)
		for k in counts[li]:
			var start: int = (k * wp.size()) / int(counts[li])
			var pc2 := ParkCar.new()
			var nxt := wp[(start + 1) % wp.size()]
			var yaw := atan2(-(nxt.x - wp[start].x), -(nxt.y - wp[start].y))
			pc2.setup_park(self, kinds[(n + 2) % kinds.size()], cols[(n * 2 + 1) % cols.size()], wp[start], yaw, false, wp, speeds[li], (start + 1) % wp.size())
			add_child(pc2)
			n += 1
	# a family warming up by the camp fire
	var fire := Campfire.new()
	fire.position = Vector3(156.0, 0.0, 215.0)
	add_child(fire)
	var fam := FarmFamily.new()
	add_child(fam)
	fam.setup_seated(fire.position, 2, 5, 0.3, 1.2, 3.0)
