class_name CityScene
extends DriveScene
## Riyadh: a 3x3 avenue grid. The centre is a glass-tower business district (with Kingdom
## Centre and Al Faisaliyah); the outer districts are Najdi-style walled villas; mid-rise
## shops fill the ring between. Masmak-style fort and a mosque with minarets add old Riyadh.
## All numbers are metres. Avenues run along x = 100/450/800 and z = 100/330/560.

const ROAD_HALF := 10.0
const KINGDOM_CENTRE := Vector2(625, 445)
const FAISALIYAH := Vector2(290, 445)


func _configure() -> void:
	world_rect = Rect2(0, 0, 900, 680)
	fog_density = 0.0022
	ground_color = Color.html("b89f72")
	var xs: Array[float] = [100.0, 450.0, 800.0]
	var zs: Array[float] = [100.0, 330.0, 560.0]
	for x in xs:
		roads.append(Rect2(x - ROAD_HALF, 0.0, ROAD_HALF * 2.0, world_rect.size.y))
	for z in zs:
		roads.append(Rect2(0.0, z - ROAD_HALF, world_rect.size.x, ROAD_HALF * 2.0))

	# city cells = the gaps between roads (including the outer ring)
	var x_edges: Array[float] = [12.0]
	for x in xs:
		x_edges.append(x - ROAD_HALF - 6.0)
		x_edges.append(x + ROAD_HALF + 6.0)
	x_edges.append(world_rect.size.x - 12.0)
	var z_edges: Array[float] = [12.0]
	for z in zs:
		z_edges.append(z - ROAD_HALF - 6.0)
		z_edges.append(z + ROAD_HALF + 6.0)
	z_edges.append(world_rect.size.y - 12.0)
	for i in range(0, x_edges.size(), 2):
		for j in range(0, z_edges.size(), 2):
			blocks.append(Rect2(x_edges[i], z_edges[j], x_edges[i + 1] - x_edges[i], z_edges[j + 1] - z_edges[j]))

	add_zone("home", Vector2(100, 560))
	add_zone("supermarket", Vector2(100, 100))
	add_zone("school", Vector2(800, 100))
	add_zone("farm", Vector2(800, 560))
	default_spawn = spawns["home"]

	# destination landmarks (Najdi-style boxes with signs)
	add_landmark(Rect2(118, 578, 64, 46), 7.0, Color.html("e9b873"), "HOME")
	add_landmark(Rect2(118, 118, 84, 52), 9.0, Color.html("d9c7a0"), "TAMIMI SUPERMARKET")
	add_landmark(Rect2(698, 118, 84, 60), 14.0, Color.html("e8cf8c"), "SCHOOL")
	add_landmark(Rect2(698, 578, 84, 46), 6.0, Color.html("cdd8a6"), "FARM ROAD")
	# famous Riyadh sights keep their footprint free
	reserved.append(Rect2(KINGDOM_CENTRE.x - 64, KINGDOM_CENTRE.y - 33, 128, 66))
	reserved.append(Rect2(FAISALIYAH.x - 28, FAISALIYAH.y - 28, 56, 56))
	reserved.append(Rect2(498, 148, 74, 60))     # Masmak-style fort
	reserved.append(Rect2(293, 193, 74, 54))     # mosque
	reserved.append(Rect2(488, 584, 76, 44))     # KAFD-style angular towers


func _build_lot(lot: Rect2) -> void:
	var centre_dist := lot.get_center().distance_to(world_rect.get_center())
	var core := clampf(1.0 - centre_dist / 450.0, 0.0, 1.0)
	var roll := _rng.randf()
	if roll < 0.5 * core:
		arch.tower(lot, 55.0 + 85.0 * core * _rng.randf(), _rng.randf() < 0.3)
	elif roll < 0.5 * core + 0.15 + 0.45 * core:
		arch.midrise(lot, _rng.randf_range(14.0, 30.0), arch.sand_color())
	else:
		arch.villa(lot, _rng.randf_range(7.0, 10.0), arch.sand_color())


func _decorate() -> void:
	arch.kingdom_centre(KINGDOM_CENTRE)
	arch.faisaliyah(FAISALIYAH)
	arch.fort(Rect2(500, 150, 70, 56), "MASMAK FORT")
	arch.mosque(Rect2(295, 195, 70, 50))
	arch.tower(Rect2(484, 590, 52, 52), 110.0, true)
	arch.tower(Rect2(528, 596, 44, 44), 90.0, true)

	add_gantry(Vector2(740, 560), ROAD_HALF * 2.0, "المزاحمية\nAL-MUZAHIMIYAH  >>")

	for r: Rect2 in roads:
		var horizontal := r.size.x >= r.size.y
		for side: float in [-1.0, 1.0]:
			if horizontal:
				var zc := r.get_center().y + side * (ROAD_HALF + 3.0)
				add_palm_line(Vector2(15, zc), Vector2(world_rect.size.x - 15, zc), 45.0)
				var zl := r.get_center().y + side * (ROAD_HALF + 1.4)
				add_lamp_line(Vector2(37, zl), Vector2(world_rect.size.x - 15, zl), 45.0)
			else:
				var xc := r.get_center().x + side * (ROAD_HALF + 3.0)
				add_palm_line(Vector2(xc, 15), Vector2(xc, world_rect.size.y - 15), 45.0)
				var xl := r.get_center().x + side * (ROAD_HALF + 1.4)
				add_lamp_line(Vector2(xl, 37), Vector2(xl, world_rect.size.y - 15), 45.0)
