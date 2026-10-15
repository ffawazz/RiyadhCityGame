extends Node
## Headless logic check of the new farm games: archery hits, swing jump distance, cornhole match, moto ramp jump.

var fails := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("ok ", msg)
	else:
		printerr("FAIL: ", msg)
		fails += 1

func _mk(id: String) -> MiniGameBase:
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var mg := MiniGameRegistry.create(id)
	host.add_child(mg)
	await get_tree().process_frame
	mg._begin()
	return mg

func _ready() -> void:
	Game.new_game()
	Game.select_character("lamia")
	# archery: wind 0, rifle, aim at a water bottle
	var a: MiniGameBase = await _mk("farm_archery")
	a._use_bow = false
	a._wind = 0.0
	a._wind_target = 0.0
	a._wind_timer = 99.0
	var target: Dictionary = a._bottles[1]
	a._aim = (target["pos"] as Vector2) + Vector2(0, -34)
	a._sway_t = 0.0
	a._fire()
	for i in 40:
		a._tick(0.02)
	_check(a._score > 0 or a._hits > 0, "archery: a shot at a bottle hits it (score %d)" % a._score)
	# wind pushes the shot sideways
	a._wind = 1.0
	a._wind_target = 1.0
	a._cooldown = 0.0
	a._arrows.clear()
	a._fire()
	var landed_x: float = (a._arrows[0]["to"] as Vector2).x
	_check(landed_x > a._crosshair().x + 15.0, "archery: wind drifts the shot (%.0f px)" % (landed_x - a._crosshair().x))
	# swing: pump, then jump
	var s: MiniGameBase = await _mk("farm_swing")
	for i in 600:
		s._tick(1.0 / 60.0)
		if s._vel > 0.05 and i % 40 == 0:
			var ev := InputEventKey.new()
			ev.keycode = KEY_SPACE
			ev.pressed = true
			s._pumped = false
			s._vel += 0.0
			s._on_input(_accept())
	_check(absf(s._angle) > 0.3 or s._vel != 0.0, "swing: pumping builds height (angle %.2f)" % s._angle)
	var tries := 0
	while s._phase == "swing" and tries < 600:
		tries += 1
		s._tick(1.0 / 60.0)
		if s._angle > 0.45 and s._vel > 0.0:
			s._jump(true)
	for i in 300:
		s._tick(1.0 / 60.0)
	_check(s._best > 1.0, "swing: jump flies %.1f m" % s._best)
	# cornhole: full match
	var c: MiniGameBase = await _mk("farm_cornhole")
	var guard := 0
	while c.running and guard < 6000:
		guard += 1
		c._tick(1.0 / 60.0)
		if c._turn == "me" and c._phase == "aim":
			c._on_input(_accept())
		elif c._turn == "me" and c._phase == "power":
			c._on_input(_accept())
	_check(not c.running, "cornhole: the match ends (me %d, dad %d)" % [c._my_pts, c._dad_pts])
	# motorbike: gas along the track
	var m: MiniGameBase = await _mk("farm_moto")
	Input.action_press("steer_right")
	for i in 600:
		m._tick(1.0 / 60.0)
	Input.action_release("steer_right")
	_check(m._x > 1500.0, "moto: the bike drives (%.0f px, %d stars)" % [m._x, m._stars])
	print("FAILURES: ", fails)
	get_tree().quit(fails)

func _accept() -> InputEvent:
	var e := InputEventAction.new()
	e.action = "ui_accept"
	e.pressed = true
	return e
