class_name FarmHighwayScene
extends DriveScene
## The long road to Al-Muzahimiyah: one straight 8 km-feeling highway with a
## Baqalah pit stop halfway and the farm gate at the end.

const GATE_X := 7700.0


func _configure() -> void:
	world_rect = Rect2(0, 0, 8000, 600)
	ground_color = Color.html("e3cf9f")
	roads.append(Rect2(0, 150, 8000, 300))
	add_zone("city_return", Vector2(200, 300))
	add_zone("baqalah", Vector2(4000, 300), Vector2(320, 0))
	add_zone("farm_gate", Vector2(GATE_X, 300))
	default_spawn = Vector2(450, 300)


func _extra_info() -> String:
	return "   |   To farm: %.1f km" % maxf(0.0, (GATE_X - car.position.x) / 100.0)


func _draw_extra() -> void:
	# roadside palms along both shoulders
	var trunk := Color.html("7f5539")
	var leaf := Color.html("2d6a4f")
	for x in range(150, int(world_rect.size.x), 320):
		for y in [90.0, 520.0]:
			draw_line(Vector2(x, y + 20.0), Vector2(x, y - 20.0), trunk, 6.0)
			draw_circle(Vector2(x, y - 26.0), 20.0, leaf)
