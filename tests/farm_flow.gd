extends Node
## Real farm flow: walk into each activity circle, press E, play the mini-game, come back.
## godot --headless res://tests/farm_flow.tscn

func _ready() -> void:
	get_tree().current_scene = null     # keep this runner alive across scene changes
	Game.new_game()
	Game.select_character("sarah")
	Game.select_animal("duck")
	Game.spawn_id = "farm_gate"
	Router.go("farm_world")
	await get_tree().create_timer(1.2).timeout
	for station in ["farm_swim", "farm_pingpong", "farm_cornhole", "farm_basketball"]:
		var farm := get_tree().current_scene
		printerr("scene: ", farm.name if farm else "none")
		var pos: Vector2 = FarmWorld.STATIONS[station]
		farm.animal.position = Vector3(pos.x, 0.3, pos.y)
		for i in 8:
			await get_tree().physics_frame
		printerr(station, ": active zone = ", farm._active_zone.location_id if farm._active_zone else "NONE")
		var k := InputEventKey.new()
		k.physical_keycode = KEY_E
		k.keycode = KEY_E
		k.pressed = true
		Input.parse_input_event(k)
		await get_tree().process_frame
		var k2 := InputEventKey.new()
		k2.physical_keycode = KEY_E
		k2.keycode = KEY_E
		k2.pressed = false
		Input.parse_input_event(k2)
		await get_tree().create_timer(1.3).timeout
		var host := get_tree().current_scene
		printerr("after E: scene = ", host.name if host else "none")
		var mg: MiniGameBase = null
		if host:
			for c in host.get_children():
				if c is MiniGameBase:
					mg = c
		if mg == null:
			printerr("FAIL: ", station, " did not open a mini-game")
			continue
		# E / Space must start the game from the intro panel (this was the "can't play" trap)
		var ek := InputEventKey.new()
		ek.physical_keycode = KEY_E
		ek.keycode = KEY_E
		ek.pressed = true
		Input.parse_input_event(ek)
		await get_tree().process_frame
		await get_tree().process_frame
		var ek2 := InputEventKey.new()
		ek2.physical_keycode = KEY_E
		ek2.keycode = KEY_E
		ek2.pressed = false
		Input.parse_input_event(ek2)
		printerr(station, ": after pressing E on the intro panel, running = ", mg.running)
		if not mg.running:
			printerr("FAIL: E did not start ", station)
			mg._begin()
		for i in 600:
			if i % 12 == 0:
				for a in ["steer_left", "steer_right", "accelerate", "brake"]:
					Input.action_release(a)
				Input.action_press(["steer_left", "steer_right", "accelerate", "brake"][randi() % 4])
			if i % 15 == 0:
				var ev := InputEventAction.new()
				ev.action = "ui_accept"
				ev.pressed = true
				Input.parse_input_event(ev)
			await get_tree().process_frame
			if not mg.running:
				break
		for a in ["steer_left", "steer_right", "accelerate", "brake"]:
			Input.action_release(a)
		printerr(station, ": mini-game ", "ended itself" if not mg.running else "still running after 600 frames")
		mg._finish(2)
		await get_tree().create_timer(1.3).timeout
		printerr("back to: ", get_tree().current_scene.name)
	printerr("FARM FLOW DONE")
	get_tree().quit()
