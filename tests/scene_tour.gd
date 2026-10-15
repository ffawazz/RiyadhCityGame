extends Node
## Visual check (needs a real renderer): flies a free camera around a driving scene.
## godot --path . res://tests/scene_tour.tscn -- <out_dir> city|highway

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp"
	var which := args[1] if args.size() > 1 else "city"
	Game.new_game()
	Game.select_character("daniah")
	var path := "res://scenes/city.tscn"
	if which == "highway":
		path = "res://scenes/farm_highway.tscn"
	elif which == "farm":
		path = "res://scenes/farm_world.tscn"
	var scene := (load(path) as PackedScene).instantiate()
	add_child(scene)
	await get_tree().process_frame
	var cam := Camera3D.new()
	cam.far = 3000.0
	cam.fov = 70
	add_child(cam)
	cam.make_current()
	var views: Array
	if which == "farm":
		views = [
			["gameplay", null, null],
			["overview", Vector3(90, 70, 190), Vector3(90, 0, 70)],
			["pool", Vector3(35, 14, 100), Vector3(35, 1, 62)],
			["pingpong_hoop", Vector3(90, 12, 70), Vector3(90, 2, 85)],
			["barn", Vector3(120, 12, 60), Vector3(145, 3, 25)],
			["cornhole", Vector3(146, 9, 88), Vector3(146, 1, 62)],
		]
	elif which == "city":
		views = [
			["kc_front", Vector3(625, 60, 676), Vector3(625, 170, 445)],
			["kc_side", Vector3(740, 90, 445), Vector3(625, 200, 445)],
			["fais_front", Vector3(290, 50, 676), Vector3(290, 140, 445)],
			["fais_top", Vector3(200, 190, 560), Vector3(290, 215, 445)],
			["traffic_street", Vector3(450, 9, 250), Vector3(450, 2, 340)],
			["traffic_wide", Vector3(380, 14, 330), Vector3(520, 3, 330)],
		]
	else:
		views = [
			["traffic", Vector3(400, 6, 112), Vector3(700, 3, 108)],
			["bump_warning", Vector3(4700, 7, 111), Vector3(4950, 5, 106)],
			["bump_side", Vector3(5300, 14, 40), Vector3(5300, 2, 111)],
			["bump_start", Vector3(4990, 5, 112), Vector3(5200, 2, 111)],
		]
	for v: Array in views:
		if v[1] == null:
			scene.cam.make_current()
		else:
			cam.make_current()
			cam.position = v[1]
			cam.look_at(v[2])
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, which, v[0]])
	get_tree().quit()
