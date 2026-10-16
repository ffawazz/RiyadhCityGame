extends Node
## Real renderer: godot --path . res://tests/road_shots.tscn -- <out_dir>
func _set_scene(path: String) -> Node:
	var old := get_tree().current_scene
	var sc := (load(path) as PackedScene).instantiate()
	get_tree().root.add_child(sc)
	get_tree().current_scene = sc
	if old != null and old != self:
		old.queue_free()
	for i in 10:
		await get_tree().process_frame
	return sc

func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])

func _place(sc: DriveScene, x: float, z: float, yaw: float, speed: float) -> void:
	sc.car.position = Vector3(x, sc.ground_height(x, z), z)
	sc.car.rotation.y = yaw
	sc.car.velocity = Vector3(sin(-yaw) * -speed, 0, 0)
	sc.chase_cam.snap_to_target()

func _ready() -> void:
	await get_tree().process_frame
	var out: String = OS.get_cmdline_user_args()[-1]
	Game.new_game()
	Game.select_character("daniah")
	Game.spawn_id = "city_return"
	var hw: FarmHighwayScene = await _set_scene("res://scenes/farm_highway.tscn")
	_place(hw, 1900.0, 111.2, -PI / 2.0, 0.0)
	for i in 30:
		await get_tree().process_frame
	await _shot(out, "r_approach")
	_place(hw, 2540.0, 111.2, -PI / 2.0, 0.0)
	for i in 10:
		await get_tree().process_frame
	await _shot(out, "r_crest")
	_place(hw, 2700.0, 111.2, -PI / 2.0, 0.0)
	Input.action_press("accelerate")
	Input.action_press("turbo")
	for i in 60:
		await get_tree().process_frame
	await _shot(out, "r_downhill_turbo")
	Input.action_release("accelerate")
	Input.action_release("turbo")
	_place(hw, 4000.0, 111.2, -PI / 2.0, 0.0)
	for i in 20:
		await get_tree().process_frame
	await _shot(out, "r_park_exit")
	Game.spawn_id = "kharrarah"
	var park: KharrarahParkScene = await _set_scene("res://scenes/kharrarah_park.tscn")
	for i in 20:
		await get_tree().process_frame
	await _shot(out, "p_gate")
	_place(park, 260.0, 230.0, 0.0, 0.0)
	for i in 10:
		await get_tree().process_frame
	await _shot(out, "p_plaza")
	_place(park, 330.0, 190.0, PI, 0.0)
	for i in 10:
		await get_tree().process_frame
	await _shot(out, "p_lake")
	_place(park, 120.0, 330.0, PI / 2.0, 0.0)
	for i in 10:
		await get_tree().process_frame
	await _shot(out, "p_dunes")
	get_tree().quit()
