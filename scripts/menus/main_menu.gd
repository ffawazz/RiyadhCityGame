extends Control
## Title screen: Play / Continue / Quit over a simple Riyadh skyline.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := UIKit.centered_column(self)
	col.add_child(UIKit.label("Riyadh Kids Adventures", 60))
	col.add_child(UIKit.label("مغامرات أطفال الرياض", 36, Color.html("ffd479")))
	var gap := Control.new()
	gap.custom_minimum_size.y = 24
	col.add_child(gap)
	var play := UIKit.button("Play", _on_play)
	col.add_child(play)
	if Game.has_save():
		col.add_child(UIKit.button("Continue", _on_continue))
	col.add_child(UIKit.button("Quit", func() -> void: get_tree().quit()))
	play.grab_focus()
	var build := UIKit.label("Build %s" % Game.BUILD_ID, 16, Color(1, 1, 1, 0.7))
	build.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	build.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	build.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(build)
	# controller status (helps on Android TV, where the remote and a gamepad are different devices)
	_pad_label = UIKit.label("", 18, Color(1, 1, 1, 0.9))
	_pad_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	_pad_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_pad_label)
	_refresh_pad()
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(_refresh_pad)
	add_child(timer)


var _pad_label: Label
var _last_input: String = "-"
var _last_event: String = "-"


func _refresh_pad() -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		_pad_label.text = "Gamepad: NOT detected by the game   last input: %s   event: %s" % [_last_input, _last_event]
	else:
		_pad_label.text = "Gamepad: %s (%d)   last input: %s   event: %s" % [Input.get_joy_name(pads[0]), pads.size(), _last_input, _last_event]


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseMotion):
		_last_event = event.as_text().left(60)
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):
		_last_input = "gamepad"
	elif event is InputEventKey:
		_last_input = "remote / keyboard"
	elif event is InputEventScreenTouch:
		_last_input = "touch"


func _on_play() -> void:
	Game.new_game()
	Router.go("character_select")


func _on_continue() -> void:
	if Game.load_game():
		Music.play_for(Game.character_id)
		Router.go("city")


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color.html("f6b26b"))                 # desert-dusk sky
	draw_rect(Rect2(0, 0, w, h * 0.45), Color.html("1c3b5a"))
	draw_rect(Rect2(0, h * 0.45, w, h * 0.2), Color.html("e08e45"))
	var ground := h * 0.82
	draw_rect(Rect2(0, ground, w, h - ground), Color.html("d8c496"))
	var skyline := Color.html("2b2d42")
	# generic towers
	for i in 14:
		var tw := 50.0 + (i * 37 % 40)
		var th := 80.0 + (i * 53 % 150)
		draw_rect(Rect2(i * (w / 14.0) + 10.0, ground - th, tw, th), skyline)
	# Kingdom Centre-style tower with the iconic opening
	var kx := w * 0.72
	draw_rect(Rect2(kx - 40, ground - 330, 24, 330), skyline)
	draw_rect(Rect2(kx + 16, ground - 330, 24, 330), skyline)
	draw_rect(Rect2(kx - 40, ground - 330, 80, 40), skyline)
	# Faisaliyah-style globe tower
	var fx := w * 0.28
	draw_rect(Rect2(fx - 10, ground - 260, 20, 260), skyline)
	draw_circle(Vector2(fx, ground - 280), 26.0, skyline)
