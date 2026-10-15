class_name FarmHighwayScene
extends DriveScene
## The long road to Al-Muzahimiyah: a 6 km highway (about 2-3 minutes of driving)
## with a Baqalah pit stop halfway and the farm gate at the end.

const GATE_X := 6100.0
const ROAD_W := 16.0


func _configure() -> void:
	world_rect = Rect2(0, 0, 6200, 200)
	fog_density = 0.0016
	palm_collisions = true
	roads.append(Rect2(0, 100.0 - ROAD_W * 0.5, world_rect.size.x, ROAD_W))
	add_zone("city_return", Vector2(60, 100), Vector2(60, 0))
	add_zone("baqalah", Vector2(3100, 100), Vector2(50, 0))
	add_zone("farm_gate", Vector2(GATE_X, 100), Vector2(-50, 0))
	spawns["city_return"] = {"pos": Vector2(120, 100), "yaw": -PI / 2.0}
	spawns["farm_gate"] = {"pos": Vector2(GATE_X - 50.0, 100), "yaw": -PI / 2.0}
	default_spawn = {"pos": Vector2(140, 100), "yaw": -PI / 2.0}
	add_landmark(Rect2(3080, 124, 44, 26), 6.0, Color.html("e9c46a"), "BAQALAH")


func _extra_info() -> String:
	return "    To farm: %.1f km" % maxf(0.0, (GATE_X - car.position.x) / 1000.0)


func _decorate() -> void:
	# palms on both shoulders
	for side: float in [-1.0, 1.0]:
		var z := 100.0 + side * (ROAD_W * 0.5 + 6.0)
		add_palm_line(Vector2(30, z), Vector2(world_rect.size.x - 30, z), 70.0)
	# distance gantries every kilometre
	for km in range(1, 6):
		add_gantry(Vector2(km * 1000.0, 100), ROAD_W, "AL-MUZAHIMIYAH  %d KM" % (6 - km))
	# desert dunes beyond the walls
	for i in 40:
		var dune := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 10
		sphere.rings = 5
		dune.mesh = sphere
		var north := i % 2 == 0
		dune.position = Vector3(float(i) * 160.0, 0.0, -90.0 - randf() * 120.0 if north else 290.0 + randf() * 120.0)
		var s := 60.0 + randf() * 60.0
		dune.scale = Vector3(s * 1.6, s * 0.28, s)
		dune.material_override = _flat(Color.html("e2c88f"))
		add_child(dune)
	# farm gate arch
	var gate_mat := Color.html("6a994e")
	for side: float in [-1.0, 1.0]:
		_add_box_mesh(Vector3(GATE_X + 20.0, 4.5, 100.0 + side * 11.0), Vector3(2.0, 9.0, 2.0), gate_mat)
	_add_box_mesh(Vector3(GATE_X + 20.0, 9.5, 100.0), Vector3(2.0, 2.0, 26.0), gate_mat)
	var lbl := Label3D.new()
	lbl.text = "AL-MUZAHIMIYAH FARM"
	lbl.font_size = 96
	lbl.pixel_size = 0.05
	lbl.outline_size = 20
	lbl.rotation_degrees.y = -90.0
	lbl.position = Vector3(GATE_X + 18.8, 12.5, 100.0)
	add_child(lbl)
