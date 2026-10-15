extends Node
## Real-flow soak test (needs a real renderer): plays mini-games through the Router exactly
## like the game does (hub -> intro panel -> play with random input -> results -> back to hub).
## godot --path . res://tests/flow_soak.tscn -- home_hub living_room,kitchen,backyard

func _ready() -> void:
	# keep this runner alive across scene changes
	var root := get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	get_tree().current_scene = null
	printerr('soak: start')
	var args := OS.get_cmdline_user_args()
	var hub := args[0] if args.size() > 0 else "home_hub"
	var ids: PackedStringArray = (args[1] if args.size() > 1 else "living_room,kitchen,backyard").split(",")
	Game.new_game()
	Game.select_character(args[2] if args.size() > 2 else "lamia")
	printerr('soak: going to hub')
	Router.go(hub)
	await get_tree().create_timer(1.0).timeout
	printerr('soak: in ', get_tree().current_scene.name)
	for id in ids:
		Router.start_minigame(id, hub)
		await get_tree().create_timer(1.2).timeout
		var host := get_tree().current_scene
		printerr("playing ", id, " scene=", host.name)
		var mg: MiniGameBase = null
		for c in host.get_children():
			if c is MiniGameBase:
				mg = c
		if mg == null:
			printerr("FAIL: no mini-game in ", host.name)
			continue
		Engine.time_scale = 6.0
		mg._begin()
		var frames := 0
		while is_instance_valid(mg) and not mg._done and frames < 12000 and not (frames > 200 and not mg.running):
			frames += 1
			if frames % 10 == 0:
				for a in ["steer_left", "steer_right", "accelerate", "brake"]:
					Input.action_release(a)
				Input.action_press(["steer_left", "steer_right", "accelerate", "brake"][randi() % 4])
			if frames % 17 == 0:
				var ev := InputEventAction.new()
				ev.action = "interact"
				ev.pressed = true
				Input.parse_input_event(ev)
				var ev2 := InputEventAction.new()
				ev2.action = "ui_accept"
				ev2.pressed = true
				Input.parse_input_event(ev2)
			if frames % 23 == 0:
				var k := InputEventKey.new()
				k.keycode = (KEY_1 + randi() % 6) as Key
				k.pressed = true
				Input.parse_input_event(k)
			await get_tree().process_frame
		Engine.time_scale = 1.0
		for a in ["steer_left", "steer_right", "accelerate", "brake"]:
			Input.action_release(a)
		printerr("finished ", id, " after ", frames, " frames; results panel shown=", mg.running == false)
		# press Continue on the results panel
		await get_tree().create_timer(0.3).timeout
		mg._finish(1)
		await get_tree().create_timer(1.2).timeout
		printerr("back in scene: ", get_tree().current_scene.name)
	printerr("SOAK DONE")
	get_tree().quit()
