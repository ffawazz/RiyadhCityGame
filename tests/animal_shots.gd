extends Node
## godot --path . res://tests/animal_shots.tscn -- <out_dir>
func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	var out := args[args.size() - 1]
	Game.new_game()
	var sc := (load("res://scenes/animal_select.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(sc)
	get_tree().current_scene = sc
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/animal_select.png" % out)
	get_tree().quit()
