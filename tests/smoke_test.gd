extends Node
## Headless smoke test:  godot --headless res://tests/smoke_test.tscn
## Loads every scene, then runs every mini-game for a few simulated seconds.

func _ready() -> void:
	var failures := 0
	Game.new_game()
	for key: String in Router.SCENES:
		var packed := load(Router.SCENES[key]) as PackedScene
		if packed == null:
			printerr("FAIL load ", key)
			failures += 1
			continue
		var inst := packed.instantiate()
		add_child(inst)
		await get_tree().process_frame
		inst.queue_free()
		print("ok scene ", key)
	for id: String in MiniGameRegistry.ENTRIES:
		var mg := MiniGameRegistry.create(id)
		add_child(mg)
		await get_tree().process_frame
		mg._begin()
		for i in 1800: # 30 simulated seconds, with button mashing
			if i % 7 == 0:
				mg._on_input(_key(KEY_1 + randi() % 6))
			if i % 11 == 0:
				var accept := InputEventAction.new()
				accept.action = "ui_accept"
				accept.pressed = true
				mg._on_input(accept)
			if not mg.running:
				break
			mg._tick(1.0 / 60.0)
		mg.queue_free()
		print("ok minigame ", id)
	failures += await _driving_test()
	print("FAILURES: ", failures)
	get_tree().quit(failures)


func _key(code: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = code as Key
	ev.pressed = true
	return ev


## Drives the car in the city: accelerates, drifts with the handbrake, then rams a wall.
func _driving_test() -> int:
	var fails := 0
	Game.new_game()
	Game.spawn_id = "home"
	var city := (load("res://scenes/city.tscn") as PackedScene).instantiate()
	add_child(city)
	var car: Car = city.car
	var start := car.position
	Input.action_press("accelerate")
	for i in 240:
		await get_tree().physics_frame
	if car.forward_speed < 15.0 or car.position.distance_to(start) < 20.0:
		printerr("FAIL: car did not accelerate/move (speed ", car.forward_speed, ")")
		fails += 1
	else:
		print("ok driving: reached ", int(car.forward_speed * 3.6), " km/h")
	Input.action_press("steer_left")
	Input.action_press("handbrake")
	var max_slide := 0.0
	for i in 40:
		await get_tree().physics_frame
		max_slide = maxf(max_slide, absf(car.lateral_speed))
	Input.action_release("steer_left")
	Input.action_release("handbrake")
	if max_slide < 2.0:
		printerr("FAIL: handbrake did not slide the car (max lateral ", max_slide, ")")
		fails += 1
	else:
		print("ok drift: max sideways slip ", snappedf(max_slide, 0.1), " m/s")
	for i in 900: # hold the throttle: the car must stay inside the world and never go NaN
		await get_tree().physics_frame
	var p := car.position
	if is_nan(p.x) or not city.world_rect.grow(2.0).has_point(Vector2(p.x, p.z)):
		printerr("FAIL: car left the world or is NaN: ", p)
		fails += 1
	else:
		print("ok collisions: car stayed in the world at ", p)
	Input.action_release("accelerate")
	city.queue_free()
	await get_tree().process_frame
	return fails
