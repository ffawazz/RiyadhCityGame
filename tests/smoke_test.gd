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
		for i in 1800: # 30 simulated seconds, with button mashing and movement
			if i % 20 == 0:
				for a in ["steer_left", "steer_right", "accelerate", "brake", "handbrake"]:
					Input.action_release(a)
				Input.action_press(["steer_left", "steer_right", "accelerate", "brake"][randi() % 4])
				if randi() % 3 == 0:
					Input.action_press("handbrake")
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
		for a in ["steer_left", "steer_right", "accelerate", "brake", "handbrake"]:
			Input.action_release(a)
		mg.queue_free()
		print("ok minigame ", id)
	failures += await _driving_test()
	failures += await _traffic_and_bumps_test()
	failures += await _farm_test()
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


## City traffic exists and moves; on the roller-coaster road a fast car gets airborne.
func _traffic_and_bumps_test() -> int:
	var fails := 0
	Game.new_game()
	var city := (load("res://scenes/city.tscn") as PackedScene).instantiate()
	add_child(city)
	await get_tree().physics_frame
	var cars: Array = city.get_children().filter(func(c: Node) -> bool: return c is TrafficCar)
	if cars.size() < 50:
		printerr("FAIL: expected city traffic, found ", cars.size())
		fails += 1
	var before := (cars[0] as TrafficCar).s
	for i in 120:
		await get_tree().physics_frame
	if absf((cars[0] as TrafficCar).s - before) < 1.0:
		printerr("FAIL: traffic car is not moving")
		fails += 1
	else:
		print("ok traffic: ", cars.size(), " cars driving in the city")
	city.queue_free()
	await get_tree().process_frame

	Game.spawn_id = "city_return"
	var road := (load("res://scenes/farm_highway.tscn") as PackedScene).instantiate()
	add_child(road)
	await get_tree().physics_frame
	var car: Car = road.car
	car.position = Vector3(5030.0, road.ground_height(5030.0, 111.2), 111.2)
	car.velocity = Vector3(34.0, 0.0, 0.0)
	car.rotation.y = -PI / 2.0
	Input.action_press("accelerate")
	var max_y := 0.0
	var was_airborne := false
	for i in 150:
		await get_tree().physics_frame
		max_y = maxf(max_y, car.position.y)
		was_airborne = was_airborne or car.airborne
	Input.action_release("accelerate")
	if max_y < 0.8 or max_y > 6.0 or is_nan(car.position.y):
		printerr("FAIL: the roller-coaster road did not lift the car (max height ", max_y, ")")
		fails += 1
	else:
		print("ok roller coaster: car climbed to ", snappedf(max_y, 0.1), " m, airborne=", was_airborne)
	road.queue_free()
	await get_tree().process_frame
	return fails


## The farm: the animal walks when WASD is pressed.
func _farm_test() -> int:
	var fails := 0
	for animal in ["duck", "goat", "chicken"]:
		Game.select_animal(animal)
		Game.spawn_id = "farm_gate"
		var farm := (load("res://scenes/farm_world.tscn") as PackedScene).instantiate()
		add_child(farm)
		await get_tree().physics_frame
		var start: Vector3 = farm.animal.position
		Input.action_press("accelerate")
		for i in 90:
			await get_tree().physics_frame
		Input.action_release("accelerate")
		if farm.animal.position.distance_to(start) < 3.0:
			printerr("FAIL: ", animal, " did not walk")
			fails += 1
		else:
			print("ok farm: the ", animal, " walked ", snappedf(farm.animal.position.distance_to(start), 0.1), " m")
		# walking into a glowing circle must offer the game (this was broken: zones only saw cars)
		for station in FarmWorld.STATIONS:
			var pos: Vector2 = FarmWorld.STATIONS[station]
			farm.animal.position = Vector3(pos.x, 0.3, pos.y)
			farm.animal.velocity = Vector3.ZERO
			for i in 6:
				await get_tree().physics_frame
			var zone: LocationZone = farm._active_zone
			if zone == null or zone.location_id != station:
				printerr("FAIL: standing at '", station, "' the animal did not enter its zone (active: ", zone.location_id if zone else "none", ")")
				fails += 1
		if fails == 0:
			print("ok farm zones: the ", animal, " can enter all ", FarmWorld.STATIONS.size(), " activity circles")
		farm.queue_free()
		await get_tree().process_frame
	return fails
