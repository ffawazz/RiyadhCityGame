extends Node
## godot --headless res://tests/touch_test.tscn -- --touch
## Feeds fake finger touches to the on-screen controls and checks the resulting input actions.

var fails := 0
var _clicked := false

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("ok ", msg)
	else:
		printerr("FAIL: ", msg)
		fails += 1

func _win(p: Vector2) -> Vector2:
	# the headless window is tiny; events are given in window pixels and scaled back to 1280x720
	var w := Vector2(get_window().size)
	var k := minf(w.x / 1280.0, w.y / 720.0)
	return p * k + (w - Vector2(1280.0, 720.0) * k) * 0.5

func _touch(idx: int, p: Vector2, down: bool) -> void:
	p = _win(p)
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = p
	e.pressed = down
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().process_frame

func _drag(idx: int, p: Vector2) -> void:
	p = _win(p)
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = p
	Input.parse_input_event(e)
	await get_tree().process_frame

func _set_scene(path: String) -> Node:
	var old := get_tree().current_scene
	var sc := (load(path) as PackedScene).instantiate()
	get_tree().root.add_child(sc)
	get_tree().current_scene = sc
	if old != null and old != self:
		old.queue_free()
	for i in 4:
		await get_tree().process_frame
	return sc

func _ready() -> void:
	await get_tree().process_frame
	if not TouchPad.enabled:
		printerr("run with:  -- --touch")
		get_tree().quit(1)
		return
	Game.new_game()
	Game.select_character("daniah")
	Game.spawn_id = "home"
	# driving
	var city := await _set_scene("res://scenes/city.tscn")
	_check(TouchPad.mode == "drive", "driving scene shows the driving controls (mode %s)" % TouchPad.mode)
	var car_start: Vector3 = city.car.global_position
	await _touch(1, Vector2(1150, 560), true)
	_check(Input.is_action_pressed("accelerate"), "GAS button presses accelerate")
	for i in 90:
		await get_tree().physics_frame
	_check(city.car.global_position.distance_to(car_start) > 1.0, "the car drives from touch input (%.1f m)" % city.car.global_position.distance_to(car_start))
	await _touch(2, Vector2(110, 610), true)
	_check(Input.is_action_pressed("steer_left"), "left arrow steers left (two fingers at once)")
	await _touch(1, Vector2(1150, 560), false)
	await _touch(2, Vector2(110, 610), false)
	for i in 12:
		await get_tree().process_frame
	_check(not Input.is_action_pressed("accelerate") and not Input.is_action_pressed("steer_left"), "buttons release")
	await _touch(3, Vector2(985, 470), true)
	_check(Input.is_action_pressed("handbrake"), "DRIFT button presses the handbrake")
	await _touch(3, Vector2(985, 470), false)
	# farm walking with the joystick
	Game.select_animal("goat")
	var farm := await _set_scene("res://scenes/farm_world.tscn")
	_check(TouchPad.mode == "walk", "farm shows the joystick controls")
	var start: Vector3 = farm.animal.position
	await _touch(4, TouchPad.STICK_BASE, true)
	await _drag(4, TouchPad.STICK_BASE + Vector2(0, 80))
	_check(Input.is_action_pressed("brake"), "joystick down = walk toward the camera")
	for i in 60:
		await get_tree().physics_frame
	_check(farm.animal.position.distance_to(start) > 2.0, "the animal walks with the joystick")
	await _touch(4, TouchPad.STICK_BASE, false)
	_check(not Input.is_action_pressed("brake"), "joystick released stops")
	# a tap on empty screen is a click for menus
	var menu := await _set_scene("res://scenes/main_menu.tscn")
	var btn := Button.new()
	btn.text = "test"
	btn.position = Vector2(300, 300)
	btn.size = Vector2(200, 80)
	btn.pressed.connect(func() -> void: _clicked = true)
	var layer := CanvasLayer.new()
	layer.layer = 50
	layer.add_child(btn)
	menu.add_child(layer)
	await get_tree().process_frame
	await _touch(5, Vector2(400, 340), true)
	await _touch(5, Vector2(400, 340), false)
	_check(_clicked, "a tap clicks a normal menu button")
	print("FAILURES: ", fails)
	get_tree().quit(fails)
