extends Node
## Real renderer: godot --path . res://tests/touch_shots.tscn -- --touch <out_dir>
func _set_scene(path: String) -> void:
	var old := get_tree().current_scene
	var sc := (load(path) as PackedScene).instantiate()
	get_tree().root.add_child(sc)
	get_tree().current_scene = sc
	if old != null and old != self:
		old.queue_free()
	for i in 20:
		await get_tree().process_frame

func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])

func _ready() -> void:
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	var out := args[args.size() - 1]
	Game.new_game()
	Game.select_character("lamia")
	Game.spawn_id = "home"
	await _set_scene("res://scenes/city.tscn")
	await _shot(out, "t_drive")
	Game.spawn_id = "farm_gate"
	await _set_scene("res://scenes/farm_world.tscn")
	await _shot(out, "t_farm")
	Game.pending_minigame = "farm_archery"
	await _set_scene("res://scenes/minigame_host.tscn")
	await _shot(out, "t_archery")
	get_tree().quit()
