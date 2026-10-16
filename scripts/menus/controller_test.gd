extends ColorRect
## Controller test screen (main menu > "Controller test"): lists the gamepads the game can see and
## shows every raw input event as it arrives, so we can tell how a TV passes a controller on.

var _list: Label
var _log: Label
var _lines: Array[String] = []
var _counts := {"key": 0, "pad button": 0, "pad axis": 0, "touch": 0, "other": 0}


func _ready() -> void:
	color = Color(0.05, 0.07, 0.12, 0.96)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	add_child(box)
	box.add_child(UIKit.label("Controller test  -  press buttons and move sticks", 30))
	_list = UIKit.label("", 20, Color.html("ffd479"))
	box.add_child(_list)
	_log = UIKit.label("", 20, Color.WHITE)
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_log)
	var close := UIKit.button("Close (or press Esc)", queue_free, Vector2(320, 56))
	box.add_child(close)
	close.grab_focus()


func _process(_d: float) -> void:
	var pads := Input.get_connected_joypads()
	var t := "Gamepads seen by the game: %d" % pads.size()
	for id in pads:
		t += "\n   #%d  %s" % [id, Input.get_joy_name(id)]
	t += "\nEvent counts:  keys %d   pad buttons %d   pad axes %d   touch %d   other %d" % [
			_counts["key"], _counts["pad button"], _counts["pad axis"], _counts["touch"], _counts["other"]]
	_list.text = t
	_log.text = "\n".join(_lines)


func _input(event: InputEvent) -> void:
	var s := ""
	var key := event as InputEventKey
	var pb := event as InputEventJoypadButton
	var pm := event as InputEventJoypadMotion
	if key != null:
		if not key.pressed:
			return
		_counts["key"] += 1
		s = "KEY  keycode=%d  physical=%d  (%s)  device=%d" % [key.keycode, key.physical_keycode, key.as_text_keycode(), key.device]
		if key.keycode == KEY_ESCAPE:
			queue_free()
			return
	elif pb != null:
		_counts["pad button"] += 1
		s = "PAD BUTTON %d  %s  device=%d" % [pb.button_index, "down" if pb.pressed else "up", pb.device]
	elif pm != null:
		if absf(pm.axis_value) < 0.4:
			return
		_counts["pad axis"] += 1
		s = "PAD AXIS %d  value=%.2f  device=%d" % [pm.axis, pm.axis_value, pm.device]
	elif event is InputEventScreenTouch:
		_counts["touch"] += 1
		s = "TOUCH"
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		return
	else:
		_counts["other"] += 1
		s = event.as_text().left(70)
	_lines.append(s)
	while _lines.size() > 14:
		_lines.pop_front()
