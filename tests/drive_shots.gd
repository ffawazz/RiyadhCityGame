extends Node
## Visual check (needs a real renderer, e.g. xvfb): drives the car and saves screenshots.
## godot --path . res://tests/drive_shots.tscn -- /tmp/shots

var out_dir := "/tmp"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game()
	Game.select_character("daniah")
	var scene_path: String = "res://scenes/city.tscn"
	if args.size() > 1:
		scene_path = args[1]
	var inst := (load(scene_path) as PackedScene).instantiate()
	add_child(inst)
	var car: Car = inst.car
	await _frames(20)
	_shot("01_start")
	Input.action_press("accelerate")
	await _frames(150)
	_shot("02_driving")
	Input.action_press("steer_right")
	await _frames(40)
	Input.action_press("handbrake")
	await _frames(25)
	_shot("03_drift")
	print("drift lateral=", car.lateral_speed, " fwd=", car.forward_speed)
	Input.action_release("handbrake")
	Input.action_release("steer_right")
	await _frames(60)
	inst.chase_cam.cycle_mode()
	await _frames(10)
	_shot("04_far")
	inst.chase_cam.cycle_mode()
	await _frames(10)
	_shot("05_hood")
	inst.chase_cam.cycle_mode()
	car.position = Vector3(60, 0, 100)   # next to a destination zone (city) - harmless on the highway
	car.velocity = Vector3.ZERO
	car.rotation.y = -PI / 2.0
	Input.action_release("accelerate")
	await _frames(40)
	_shot("06_zone")
	Input.action_release("accelerate")
	print("pos=", car.position, " speed=", car.forward_speed)
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
