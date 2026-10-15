class_name CityScene
extends DriveScene
## The Riyadh hub: a 3x3 street grid with Home, Tamimi Supermarket, School
## and the exit onto the highway to the farm.


func _configure() -> void:
	world_rect = Rect2(0, 0, 2400, 1600)
	var xs: Array[float] = [300.0, 1200.0, 2100.0]
	var ys: Array[float] = [300.0, 800.0, 1300.0]
	var half := 100.0 # half road width

	for x in xs:
		roads.append(Rect2(x - half, 0.0, half * 2.0, world_rect.size.y))
	for y in ys:
		roads.append(Rect2(0.0, y - half, world_rect.size.x, half * 2.0))

	# a building fills every grid cell between four roads
	for i in xs.size() - 1:
		for j in ys.size() - 1:
			var x0 := xs[i] + half + 30.0
			var x1 := xs[i + 1] - half - 30.0
			var y0 := ys[j] + half + 30.0
			var y1 := ys[j + 1] - half - 30.0
			blocks.append(Rect2(x0, y0, x1 - x0, y1 - y0))

	add_zone("home", Vector2(300, 1300))
	add_zone("supermarket", Vector2(300, 300))
	add_zone("school", Vector2(2100, 300))
	add_zone("farm", Vector2(2100, 1300))
	default_spawn = spawns["home"]
