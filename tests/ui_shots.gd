extends Node
## Visual check: screenshots of the menu screens.  godot --path . res://tests/ui_shots.tscn -- <out>
func _ready() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	Game.new_game()
	Game.select_character("lamia")
	for key in ["character_select", "animal_select"]:
		var scene := (load(Router.SCENES[key]) as PackedScene).instantiate()
		add_child(scene)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/ui_%s.png" % [out, key])
		scene.queue_free()
		await get_tree().process_frame
	get_tree().quit()
