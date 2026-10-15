extends Node
## Visual check (needs a real renderer): plays mini-games with scripted input, screenshots them.
## godot --path . res://tests/game_shots.tscn -- <out_dir> id1,id2,...

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp"
	var ids: PackedStringArray = (args[1] if args.size() > 1 else "living_room,kitchen,school_puzzle,baqalah_snacks").split(",")
	Game.new_game()
	Game.select_character("sarah")
	for id in ids:
		var host := Control.new()
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(host)
		var mg := MiniGameRegistry.create(id)
		host.add_child(mg)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_intro.png" % [out, id])
		mg._begin()
		for i in 150:
			_drive_inputs(i)
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_play.png" % [out, id])
		for a in ["steer_left", "steer_right", "accelerate", "brake", "handbrake"]:
			Input.action_release(a)
		host.queue_free()
		await get_tree().process_frame
	get_tree().quit()

func _drive_inputs(i: int) -> void:
	for a in ["steer_left", "steer_right", "accelerate", "brake"]:
		Input.action_release(a)
	match (i / 25) % 4:
		0: Input.action_press("steer_right")
		1: Input.action_press("accelerate")
		2: Input.action_press("steer_left")
		3: Input.action_press("brake")
	if i % 30 == 0:
		Input.action_press("handbrake")
	elif i % 30 == 3:
		Input.action_release("handbrake")
