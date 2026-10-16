extends Node
## Headless: farm-road downhill slope, turbo, no damage on the farm road, Al-Kharrarah Park.

var fails := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("ok ", msg)
	else:
		printerr("FAIL: ", msg)
		fails += 1

func _scene(path: String) -> Node:
	var sc := (load(path) as PackedScene).instantiate()
	add_child(sc)
	for i in 3:
		await get_tree().physics_frame
	return sc

func _drive(car: Car, frames: int, turbo: bool) -> Dictionary:
	var top := 0.0
	var max_y := 0.0
	Input.action_press("accelerate")
	if turbo:
		Input.action_press("turbo")
	for i in frames:
		await get_tree().physics_frame
		top = maxf(top, car.forward_speed)
		max_y = maxf(max_y, car.position.y)
	Input.action_release("accelerate")
	Input.action_release("turbo")
	return {"top": top, "max_y": max_y}

func _ready() -> void:
	await get_tree().process_frame
	Game.new_game()
	Game.select_character("sarah")
	# --- the big slope exists and drives
	Game.spawn_id = "city_return"
	var hw: FarmHighwayScene = await _scene("res://scenes/farm_highway.tscn")
	_check(absf(hw.ground_height(FarmHighwayScene.SLOPE_CREST, 100.0) - FarmHighwayScene.SLOPE_H) < 0.5, "highway: the ridge is %.0f m high" % hw.ground_height(FarmHighwayScene.SLOPE_CREST, 100.0))
	_check(hw.ground_height(FarmHighwayScene.SLOPE_X1 + 5.0, 100.0) == 0.0, "highway: the slope ends flat before the Baqalah")
	var steepest := 0.0
	var x := FarmHighwayScene.SLOPE_X0
	while x < FarmHighwayScene.SLOPE_X1:
		steepest = maxf(steepest, absf(hw.ground_height(x + 1.0, 111.0) - hw.ground_height(x, 111.0)))
		x += 1.0
	_check(steepest > 0.12, "highway: the downhill is steep (%.0f%% grade)" % (steepest * 100.0))
	# drive up and over the ridge
	hw.car.position = Vector3(FarmHighwayScene.SLOPE_X0 - 150.0, 0.0, 111.2)
	hw.car.rotation.y = -PI / 2.0
	hw.car.velocity = Vector3(30.0, 0.0, 0.0)
	var r := await _drive(hw.car, 60 * 25, false)
	_check(float(r["max_y"]) > 30.0, "highway: the car climbs the ridge (max height %.1f m)" % float(r["max_y"]))
	_check(hw.car.position.x > FarmHighwayScene.SLOPE_X1, "highway: the car rolls down the other side (x %.0f)" % hw.car.position.x)
	# no damage on the farm road
	hw.car.position = Vector3(300.0, 0.0, 111.2)
	hw.car.rotation.y = -PI / 2.0
	hw.car.velocity = Vector3.ZERO
	hw.car.rotation.y = 0.0     # face the median barrier
	await _drive(hw.car, 200, false)
	_check(Game.car_damage == 0.0 and hw.car.damage.health() >= 99.9, "highway: crashing into a barrier causes no damage")
	hw.queue_free()
	await get_tree().process_frame
	# --- turbo
	Game.spawn_id = "home"
	var city: CityScene = await _scene("res://scenes/city.tscn")
	city.car.position = Vector3(100.0, 0.0, 330.0)
	var normal := await _drive(city.car, 60 * 9, false)
	city.car.position = Vector3(100.0, 0.0, 330.0)
	city.car.rotation.y = -PI / 2.0
	city.car.velocity = Vector3.ZERO
	city.car.forward_speed = 0.0
	var boosted := await _drive(city.car, 60 * 9, true)
	_check(float(boosted["top"]) > float(normal["top"]) + 4.0, "turbo: top speed %.0f m/s vs %.0f m/s without" % [float(boosted["top"]), float(normal["top"])])
	_check(city.car.turbo_charge < 0.8, "turbo: the charge drains (%.2f)" % city.car.turbo_charge)
	city.queue_free()
	await get_tree().process_frame
	# --- the park
	Game.spawn_id = "kharrarah"
	var park: KharrarahParkScene = await _scene("res://scenes/kharrarah_park.tscn")
	_check(park.zones.size() == 4, "park: the BBQ, kite, boat and exit circles exist")
	var peak := 0.0
	for xx in range(0, 520, 8):
		for zz in range(0, 420, 8):
			peak = maxf(peak, park.ground_height(float(xx), float(zz)))
	_check(peak > 3.0 and park.ground_height(260.0, 210.0) == 0.0, "park: dunes up to %.1f m around a flat plaza" % peak)
	var r2 := await _drive(park.car, 60 * 6, false)
	_check(park.car.position.distance_to(Vector3(260.0, 0.0, 362.0)) > 20.0, "park: the car drives on the sand")
	# every zone is reachable (car inside its circle)
	for z: Dictionary in park.zones:
		park.car.position = Vector3(z["pos"].x, 0.0, z["pos"].y)
		park.car.velocity = Vector3.ZERO
		for i in 6:
			await get_tree().physics_frame
		_check(park._active_zone != null and park._active_zone.location_id == z["id"], "park: zone '%s' can be entered" % z["id"])
	print("FAILURES: ", fails)
	get_tree().quit(fails)
