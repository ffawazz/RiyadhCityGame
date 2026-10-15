extends Node3D
## Visual check (needs a real renderer): photographs the car from several angles.
## godot --path . res://tests/car_closeup.tscn -- /tmp/shots

func _ready() -> void:
	var out := "/tmp"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	Game.select_character("daniah")
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.html("9ec8e8")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.76, 0.66)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 0.9
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color.html("5a5d63")
	ground.material_override = gm
	add_child(ground)
	var car := Car.new()
	add_child(car)
	car.set_physics_process(false)
	var cam := Camera3D.new()
	cam.fov = 45
	add_child(cam)
	var views := {
		"car_side": [Vector3(-7.5, 1.9, 0.0), Vector3(0, 1.0, 0)],
		"car_front34": [Vector3(-4.5, 2.2, -6.0), Vector3(0, 0.9, 0)],
		"car_rear34": [Vector3(4.2, 2.6, 6.4), Vector3(0, 1.0, 0)],
		"car_plate": [Vector3(0.0, 1.4, 4.0), Vector3(0, 0.8, 2.5)],
		"car_top": [Vector3(0.01, 7.5, 0.4), Vector3(0, 1.0, 0.3)],
	}
	for name: String in views:
		cam.position = views[name][0]
		cam.look_at(views[name][1])
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	get_tree().quit()
