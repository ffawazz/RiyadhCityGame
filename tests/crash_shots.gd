extends Node
## Visual check (needs a real renderer): a handbrake drift, then a crash, then close-ups of the damage.
## godot --path . res://tests/crash_shots.tscn -- <out_dir>

var out := "/tmp"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	Game.new_game()
	Game.select_character("daniah")
	Game.spawn_id = "home"
	var city := (load("res://scenes/city.tscn") as PackedScene).instantiate()
	add_child(city)
	var car: Car = city.car
	await _frames(10)
	Input.action_press("accelerate")
	await _frames(100)
	# drift: steer + handbrake
	for i in 38:
		Input.action_press("steer_left")
		Input.action_press("handbrake")
		await get_tree().physics_frame
		if i == 26:
			await _shot("01_drift")
	Input.action_release("handbrake")
	Input.action_release("steer_left")
	await _frames(25)
	await _shot("02_after_drift")
	# crash: aim at a building
	Input.action_release("accelerate")
	car.position = Vector3(215.0, 0.0, 556.0)
	car.rotation.y = 0.0
	car.velocity = Vector3(0, 0, -30)
	car.yaw_rate = 0.0
	Input.action_press("accelerate")
	await _frames(70)
	Input.action_release("accelerate")
	print("damage after crash: ", Game.car_damage, " hits ", Game.car_hits.size())
	await _shot("03_crash_chase")
	# close-ups with a free camera
	var cam := Camera3D.new()
	cam.fov = 50
	city.add_child(cam)
	cam.make_current()
	var views := {
		"04_front_damage": Vector3(-3.5, 2.2, -7.5),
		"05_side_damage": Vector3(-7.0, 2.0, 0.5),
		"06_rear": Vector3(3.5, 2.6, 7.0),
	}
	for name: String in views:
		cam.global_position = car.global_position + car.global_transform.basis * views[name]
		cam.look_at(car.global_position + Vector3(0, 1.0, 0))
		await _shot(name)
	# orbit views with the real chase camera
	city.chase_cam.make_current()
	city.chase_cam.locked = true
	for v in [["07_orbit_side", PI * 0.5, 0.2, 1.0], ["08_orbit_front_high", PI * 0.85, 0.7, 1.4], ["09_orbit_back_close", 0.0, 0.1, 0.55]]:
		city.chase_cam.orbit_yaw = v[1]
		city.chase_cam.orbit_pitch = v[2]
		city.chase_cam.orbit_zoom = v[3]
		await _frames(20)
		await _shot(v[0])
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _shot(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
