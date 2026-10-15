extends Node
## Visual check (needs a real renderer): flies a free camera around a driving scene.
## godot --path . res://tests/scene_tour.tscn -- <out_dir> city|highway

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp"
	var which := args[1] if args.size() > 1 else "city"
	Game.new_game()
	Game.select_character("daniah")
	var path := "res://scenes/city.tscn" if which == "city" else "res://scenes/farm_highway.tscn"
	var scene := (load(path) as PackedScene).instantiate()
	add_child(scene)
	await get_tree().process_frame
	var cam := Camera3D.new()
	cam.far = 3000.0
	cam.fov = 70
	add_child(cam)
	cam.make_current()
	var views: Array
	if which == "city":
		views = [
			["aerial", Vector3(450, 330, 780), Vector3(450, 0, 300)],
			["kingdom", Vector3(625, 14, 590), Vector3(625, 60, 445)],
			["fort_mosque", Vector3(430, 20, 330), Vector3(520, 12, 190)],
			["villas", Vector3(60, 25, 380), Vector3(220, 6, 480)],
			["towers_street", Vector3(300, 6, 335), Vector3(450, 40, 345)],
		]
	else:
		views = [
			["road_start", Vector3(60, 7, 111), Vector3(500, 4, 106)],
			["gantry", Vector3(120, 5, 111), Vector3(220, 7, 100)],
			["cliffs", Vector3(1500, 12, 100), Vector3(1700, 40, -250)],
			["baqalah", Vector3(3000, 10, 128), Vector3(3105, 4, 160)],
			["farm_gate", Vector3(6030, 9, 125), Vector3(6160, 6, 140)],
		]
	for v: Array in views:
		cam.position = v[1]
		cam.look_at(v[2])
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, which, v[0]])
	get_tree().quit()
