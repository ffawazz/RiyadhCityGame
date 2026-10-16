extends Node
## godot --headless res://tests/gamepad_test.tscn -- --touch
## Fake Xbox-controller input: the left stick and D-pad move in all four directions, LB swaps,
## and the touch buttons disappear while a pad is in use.

var fails := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("ok ", msg)
	else:
		printerr("FAIL: ", msg)
		fails += 1

func _axis(axis: int, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 3          # a TV often reports the pad as device 1-3, not 0
	e.axis = axis as JoyAxis
	e.axis_value = value
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().process_frame

func _button(btn: int, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.device = 3
	e.button_index = btn as JoyButton
	e.pressed = down
	Input.parse_input_event(e)
	await get_tree().process_frame
	await get_tree().process_frame

func _ready() -> void:
	await get_tree().process_frame
	await _axis(JOY_AXIS_LEFT_Y, -1.0)
	_check(Input.is_action_pressed("accelerate"), "left stick up = accelerate / walk up")
	await _axis(JOY_AXIS_LEFT_Y, 1.0)
	_check(Input.is_action_pressed("brake") and not Input.is_action_pressed("accelerate"), "left stick down = brake / walk down")
	await _axis(JOY_AXIS_LEFT_Y, 0.0)
	await _axis(JOY_AXIS_LEFT_X, 1.0)
	_check(Input.is_action_pressed("steer_right"), "left stick right = steer right")
	await _axis(JOY_AXIS_LEFT_X, 0.0)
	await _button(JOY_BUTTON_DPAD_LEFT, true)
	_check(Input.is_action_pressed("steer_left"), "D-pad left = steer left")
	await _button(JOY_BUTTON_DPAD_LEFT, false)
	await _button(JOY_BUTTON_A, true)
	_check(Input.is_action_pressed("handbrake") and Input.is_action_pressed("ui_accept"), "A = handbrake / jump / confirm")
	await _button(JOY_BUTTON_A, false)
	await _button(JOY_BUTTON_RIGHT_SHOULDER, true)
	_check(Input.is_action_pressed("turbo"), "RB = turbo")
	await _button(JOY_BUTTON_RIGHT_SHOULDER, false)
	await _button(JOY_BUTTON_LEFT_SHOULDER, true)
	_check(Input.is_action_pressed("swap_item"), "LB = swap weapon / food")
	await _button(JOY_BUTTON_LEFT_SHOULDER, false)
	await _button(JOY_BUTTON_B, true)
	_check(Input.is_action_pressed("ui_cancel"), "B = back")
	await _button(JOY_BUTTON_B, false)
	await _button(JOY_BUTTON_BACK, true)
	_check(Input.is_action_pressed("map"), "Back/View = map")
	await _button(JOY_BUTTON_BACK, false)
	_check(TouchPad.enabled and not TouchPad._view.visible, "touch buttons hide while a gamepad is used")
	# a TV remote (key presses) also hides the touch buttons; a real touch brings them back
	TouchPad._pad_mode = false
	var k := InputEventKey.new()
	k.keycode = KEY_ENTER
	k.pressed = true
	Input.parse_input_event(k)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not TouchPad._view.visible, "a TV remote / keyboard press hides the touch buttons")
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = Vector2(10, 10)
	t.pressed = true
	Input.parse_input_event(t)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(TouchPad._view.visible, "touching the screen shows the touch buttons again")
	# on-screen button names follow the device
	Game.input_mode = "pad"
	Game.pad_style_pref = "ps"
	_check(Hints.btn("confirm") == "Cross" and Hints.btn("interact") == "Square", "PlayStation names: Cross / Square")
	_check(Hints.adapt("Move the mouse (or WASD / drag your finger) and click, tap or press SPACE to pick.") == "Move with the left stick and press Cross to pick.", "instructions are rewritten for a PlayStation pad")
	Game.pad_style_pref = "xbox"
	_check(Hints.btn("confirm") == "A" and Hints.btn("turbo") == "RB", "Xbox names: A / RB")
	Game.input_mode = "kbd"
	_check(Hints.btn("confirm") == "Space" and Hints.adapt("press SPACE") == "press SPACE", "keyboard names unchanged")
	Game.pad_style_pref = "auto"
	# triggers can be switched off (the stick then drives)
	Game.triggers_pref = "off"
	Game.apply_trigger_setting()
	await _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_check(not Input.is_action_pressed("accelerate"), "triggers OFF: R2 no longer gives gas")
	await _axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await _axis(JOY_AXIS_LEFT_Y, -1.0)
	_check(Input.is_action_pressed("accelerate"), "triggers OFF: the left stick still gives gas")
	await _axis(JOY_AXIS_LEFT_Y, 0.0)
	Game.triggers_pref = "on"
	Game.apply_trigger_setting()
	await _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_check(Input.is_action_pressed("accelerate"), "triggers ON: R2 gives gas")
	await _axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	Game.triggers_pref = "auto"
	Game.apply_trigger_setting()
	print("FAILURES: ", fails)
	get_tree().quit(fails)
