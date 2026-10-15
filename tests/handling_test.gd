extends Node
## Checks the car's handling numbers: handbrake turn, fast corner, power slide, wall crash.
## godot --headless res://tests/handling_test.tscn

var car: Car

func _ready() -> void:
	Game.new_game()
	var world := Node3D.new()
	add_child(world)
	var wall := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 6, 2)
	cs.shape = box
	wall.add_child(cs)
	wall.position = Vector3(0, 3, -400)
	world.add_child(wall)
	car = Car.new()
	world.add_child(car)
	var fails := 0

	# 1) accelerate to ~25 m/s on the straight
	await _drive(180, {"accelerate": true})
	await _drive(90, {"accelerate": true})
	print("1) cruising: %.1f m/s (%.0f km/h)" % [car.forward_speed, car.forward_speed * 3.6])

	# 2) handbrake turn: lift, steer right + handbrake 0.7 s, then release and let it recover
	var yaw0 := car.rotation.y
	var speed0 := car.forward_speed
	var max_slip := 0.0
	for i in 42:
		Input.action_press("steer_right")
		Input.action_press("handbrake")
		await get_tree().physics_frame
		max_slip = maxf(max_slip, absf(car.body_slip))
	Input.action_release("handbrake")
	Input.action_release("steer_right")
	for i in 120:
		await get_tree().physics_frame
		max_slip = maxf(max_slip, absf(car.body_slip))
	var turned := rad_to_deg(absf(wrapf(car.rotation.y - yaw0, -PI, PI)))
	print("2) handbrake turn: heading changed %.0f deg, speed %.1f -> %.1f m/s (still travelling at %.1f), max body slip %.0f deg, yaw rate now %.2f" % [turned, speed0, car.forward_speed, car.velocity.length(), rad_to_deg(max_slip), car.yaw_rate])
	if turned < 45.0:
		printerr("FAIL: handbrake turn barely turned the car")
		fails += 1
	if is_nan(car.rotation.y) or absf(car.yaw_rate) > 3.0:
		printerr("FAIL: car is spinning out of control after the handbrake turn")
		fails += 1

	# 2b) the realistic version: tap the handbrake, keep the power on, catch the slide
	car.rotation.y = 0.0
	car.velocity = Vector3(0, 0, -28)
	car.yaw_rate = 0.0
	await _drive(20, {"accelerate": true})
	var yawb := car.rotation.y
	for i in 28:
		Input.action_press("steer_right")
		Input.action_press("handbrake")
		Input.action_press("accelerate")
		await get_tree().physics_frame
	Input.action_release("handbrake")
	Input.action_release("steer_right")
	await _drive(90, {"accelerate": true})
	print("2b) handbrake tap with power on: heading changed %.0f deg, still travelling at %.1f m/s, slip now %.0f deg" % [rad_to_deg(absf(wrapf(car.rotation.y - yawb, -PI, PI))), car.velocity.length(), rad_to_deg(car.body_slip)])
	if car.velocity.length() < 8.0:
		printerr("FAIL: the car loses all its speed in a handbrake turn")
		fails += 1

	# 3) fast corner without handbrake must not spin the car
	car.rotation.y = 0.0
	car.velocity = Vector3(0, 0, -25)
	car.yaw_rate = 0.0
	await _drive(20, {"accelerate": true})
	var slip_max := 0.0
	var yaw1 := car.rotation.y
	for i in 90:
		Input.action_press("accelerate")
		Input.action_press("steer_right")
		await get_tree().physics_frame
		slip_max = maxf(slip_max, absf(car.body_slip))
	Input.action_release("steer_right")
	print("3) fast corner at ~%.0f m/s: turned %.0f deg in 1.5 s, max body slip %.0f deg" % [car.forward_speed, rad_to_deg(absf(car.rotation.y - yaw1)), rad_to_deg(slip_max)])
	if rad_to_deg(slip_max) > 70.0:
		printerr("FAIL: normal cornering spins the car")
		fails += 1

	# 4) crash into the wall at speed: damage must rise and the car be knocked back
	car.rotation.y = 0.0
	car.position = Vector3(0, 0, -360)
	car.velocity = Vector3(0, 0, -30)
	car.yaw_rate = 0.0
	var dmg0 := Game.car_damage
	await _drive(150, {"accelerate": true})
	print("4) wall crash at 108 km/h: damage %.0f -> %.0f%%, hits stored %d, speed now %.1f m/s" % [dmg0, Game.car_damage, Game.car_hits.size(), car.forward_speed])
	if Game.car_damage < 20.0:
		printerr("FAIL: a 108 km/h wall crash should do real damage")
		fails += 1

	# 5) repair
	car.repair()
	print("5) repaired: damage %.0f%%" % Game.car_damage)
	if Game.car_damage != 0.0:
		printerr("FAIL: repair did not reset the damage")
		fails += 1
	print("FAILURES: ", fails)
	get_tree().quit(fails)

func _drive(frames: int, actions: Dictionary) -> void:
	for a in actions:
		Input.action_press(a)
	for i in frames:
		await get_tree().physics_frame
	for a in actions:
		Input.action_release(a)
