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
	print("FAILURES: ", failures)
	get_tree().quit(failures)


func _key(code: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = code as Key
	ev.pressed = true
	return ev
