class_name Minimap
extends Control
## North-up map of the roads, location zones and the car.

var scene: DriveScene


func _init(drive_scene: DriveScene) -> void:
	scene = drive_scene
	size = Vector2(240, 170)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))
	var wr := scene.world_rect
	var k := minf((size.x - 12.0) / wr.size.x, (size.y - 12.0) / wr.size.y)
	var off := (size - wr.size * k) * 0.5
	for r: Rect2 in scene.roads:
		var rr := Rect2(off + (r.position - wr.position) * k, r.size * k)
		if rr.size.x < 3.0:
			rr.size.x = 3.0
		if rr.size.y < 3.0:
			rr.size.y = 3.0
		draw_rect(rr, Color(0.7, 0.7, 0.75, 0.9))
	for z: Dictionary in scene.zones:
		var data: Dictionary = Game.LOCATIONS[z["id"]]
		draw_circle(off + ((z["pos"] as Vector2) - wr.position) * k, 5.0, Color.html(data["color"]))
	if scene.car != null:
		var p := off + (Vector2(scene.car.position.x, scene.car.position.z) - wr.position) * k
		var yaw := scene.car.rotation.y
		var dir := Vector2(-sin(yaw), -cos(yaw))
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([p + dir * 8.0, p - dir * 5.0 + side * 5.0, p - dir * 5.0 - side * 5.0]),
				Color.html("4cc9f0"))
