extends Node
## A light, imperfect trigger pull must still reach full speed (some TVs report only part of the range).
func _ready() -> void:
	await get_tree().process_frame
	Game.new_game()
	Game.spawn_id = "home"
	var city := (load("res://scenes/city.tscn") as PackedScene).instantiate()
	add_child(city)
	for i in 3:
		await get_tree().physics_frame
	var fails := 0
	for case in [["full keyboard", 1.0, 0.0], ["light trigger 0.3", 0.3, 0.0], ["trigger 0.3 + brake rest 0.15", 0.3, 0.15]]:
		var car: Car = city.car
		car.position = Vector3(100.0, 0.0, 330.0)
		car.rotation.y = -PI / 2.0
		car.velocity = Vector3.ZERO
		car.forward_speed = 0.0
		Input.action_press("accelerate", float(case[1]))
		if float(case[2]) > 0.0:
			Input.action_press("brake", float(case[2]))
		var top := 0.0
		for i in 60 * 8:
			await get_tree().physics_frame
			top = maxf(top, car.forward_speed)
		Input.action_release("accelerate")
		Input.action_release("brake")
		var ok := top > 33.0
		print(("ok " if ok else "FAIL: "), case[0], ": top speed ", int(top * 3.6), " km/h")
		if not ok:
			fails += 1
	print("FAILURES: ", fails)
	get_tree().quit(fails)
