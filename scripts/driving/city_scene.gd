class_name CityScene
extends DriveScene
## The Riyadh hub: a 3x3 street grid with towers, palms and four destinations.
## All numbers are metres. Roads run along x=100/450/800 and z=100/330/560.

const ROAD_HALF := 10.0


func _configure() -> void:
	world_rect = Rect2(0, 0, 900, 680)
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

	# landmarks next to each destination
	add_landmark(Rect2(118, 578, 64, 46), 7.0, Color.html("f4a261"), "HOME")
	add_landmark(Rect2(118, 118, 84, 52), 9.0, Color.html("e63946"), "TAMIMI SUPERMARKET")
	add_landmark(Rect2(698, 118, 84, 60), 14.0, Color.html("ffd166"), "SCHOOL")
	add_landmark(Rect2(698, 578, 84, 46), 6.0, Color.html("8ac926"), "FARM ROAD")
	reserved.append(Rect2(560, 415, 130, 60))  # Kingdom Centre footprint


func _decorate() -> void:
	# Kingdom Centre-style twin tower with the sky bridge
	_add_building(Rect2(570, 425, 28, 40), 120.0, Color.html("9fb7c9"), true)
	_add_building(Rect2(652, 425, 28, 40), 120.0, Color.html("9fb7c9"), true)
	_add_box_mesh(Vector3(625, 105, 445), Vector3(110, 16, 40), Color.html("9fb7c9"))
	var tag := Label3D.new()
	tag.text = "KINGDOM CENTRE"
	tag.font_size = 96
	tag.pixel_size = 0.07
	tag.outline_size = 24
	tag.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	tag.position = Vector3(625, 135, 445)
	add_child(tag)

	add_gantry(Vector2(740, 560), ROAD_HALF * 2.0, "AL-MUZAHIMIYAH  >>")

	for r: Rect2 in roads:
		var horizontal := r.size.x >= r.size.y
		for side: float in [-1.0, 1.0]:
			if horizontal:
				var zc := r.get_center().y + side * (ROAD_HALF + 3.0)
				add_palm_line(Vector2(15, zc), Vector2(world_rect.size.x - 15, zc), 45.0)
			else:
				var xc := r.get_center().x + side * (ROAD_HALF + 3.0)
				add_palm_line(Vector2(xc, 15), Vector2(xc, world_rect.size.y - 15), 45.0)
