extends CanvasLayer
## Autoload "TouchPad": on-screen controls for phones and tablets (Android / iOS), also enabled on a
## desktop with the `--touch` argument for testing. It turns touches into the same input actions the
## keyboard uses, so no game script needs to know about touch:
##   * driving: steer left / right buttons, GAS, BRAKE, DRIFT (handbrake), E, camera
##   * farm walking and mini-games: a virtual joystick (= WASD) plus action buttons
##   * every other touch is passed on as a normal left mouse click / drag (menus, archery aiming)
## Godot's own touch->mouse emulation is switched off so pressing a button never also clicks the game.

const MIN_HOLD := 0.12          # seconds an action stays down so is_action_just_pressed() sees a tap
const STICK_BASE := Vector2(165.0, 545.0)
const STICK_R := 95.0

var enabled: bool = false
var mode: String = "menu"        # menu | drive | walk | mini

var _view: Control
var _buttons: Array[Dictionary] = []
var _owners: Dictionary = {}     # touch index -> button dict | "stick" | "mouse"
var _stick_vec := Vector2.ZERO
var _stick_strength := {"steer_left": 0.0, "steer_right": 0.0, "accelerate": 0.0, "brake": 0.0}
var _mouse_pos := Vector2.ZERO
var _release_at: Dictionary = {}  # button id -> time to release
var _clock: float = 0.0
var _last_scene_key: String = ""
var _pad_mode: bool = false       # a gamepad is being used: hide the touch buttons (Android TV)


static func wanted() -> bool:
	return OS.has_feature("android") or OS.has_feature("ios") or OS.get_cmdline_user_args().has("--touch")


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = wanted()
	if not enabled:
		set_process(false)
		set_process_input(false)
		return
	Input.emulate_mouse_from_touch = false
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		Input.emulate_touch_from_mouse = true      # desktop test: mouse acts as one finger
	_view = Control.new()
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_pad)
	add_child(_view)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and enabled:
		_tap_action("ui_cancel")


# ---- layout -----------------------------------------------------------------

func _detect_mode() -> String:
	var sc := get_tree().current_scene
	if sc == null:
		return "menu"
	if sc is DriveScene:
		return "drive"
	if sc is FarmWorld:
		return "walk"
	if sc.scene_file_path.ends_with("minigame_host.tscn"):
		return "mini"
	return "menu"


func _btn(id: String, label: String, c: Vector2, r: float, actions: Array, key: int = 0) -> void:
	_buttons.append({"id": id, "label": label, "c": c, "r": r, "actions": actions, "key": key, "down": false})


func _layout() -> void:
	_release_all()
	_buttons.clear()
	match mode:
		"drive":
			_btn("left", "<", Vector2(110, 610), 64, ["steer_left"])
			_btn("right", ">", Vector2(262, 610), 64, ["steer_right"])
			_btn("gas", "GAS", Vector2(1150, 560), 78, ["accelerate"])
			_btn("brake", "BRAKE", Vector2(985, 625), 56, ["brake"])
			_btn("drift", "DRIFT", Vector2(985, 470), 56, ["handbrake"])
			_btn("turbo", "TURBO", Vector2(830, 610), 52, ["turbo"])
			_btn("e", "E", Vector2(1150, 395), 46, ["interact"])
			_btn("cam", "CAM", Vector2(1015, 350), 40, ["camera"])
		"walk":
			_btn("jump", "JUMP", Vector2(1160, 590), 70, ["handbrake"])
			_btn("e", "E", Vector2(1010, 640), 52, ["interact"])
			_btn("map", "MAP", Vector2(1160, 450), 42, [], KEY_M)
		"mini":
			_btn("a", "OK", Vector2(1160, 590), 70, ["ui_accept"])
			_btn("e", "E", Vector2(1010, 640), 46, ["interact"])
			if Game.pending_minigame == "farm_archery":
				_btn("swap", "SWAP", Vector2(1160, 440), 46, [], KEY_TAB)
	if mode != "menu":
		_btn("back", "ESC", Vector2(940, 50), 30, ["ui_cancel"])


func _uses_stick() -> bool:
	return mode == "walk" or mode == "mini"


# ---- frame loop -------------------------------------------------------------

func _process(delta: float) -> void:
	_clock += delta
	var sc := get_tree().current_scene
	var key := "%s|%s" % [sc.get_instance_id() if sc else 0, Game.pending_minigame]
	if key != _last_scene_key:
		_last_scene_key = key
		_owners.clear()
		mode = _detect_mode()
		_layout()
	for id: String in _release_at.keys():
		if _clock >= float(_release_at[id]):
			_release_at.erase(id)
			for b: Dictionary in _buttons:
				if b["id"] == id and not b["down"]:
					_send_button(b, false)
	_view.visible = not _pad_mode
	_view.queue_redraw()


# ---- input ------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):
		if not _pad_mode:
			_pad_mode = true
			_release_all()
		return
	var st := event as InputEventScreenTouch
	if st != null:
		_pad_mode = false
		if st.pressed:
			_touch_down(st.index, st.position)
		else:
			_touch_up(st.index, st.position)
		return
	var sd := event as InputEventScreenDrag
	if sd != null:
		_touch_move(sd.index, sd.position)


func _hit_button(p: Vector2) -> Dictionary:
	for b: Dictionary in _buttons:
		if p.distance_to(b["c"]) <= float(b["r"]) * 1.2:
			return b
	return {}


func _touch_down(idx: int, p: Vector2) -> void:
	var b := _hit_button(p)
	if not b.is_empty():
		_owners[idx] = b
		b["down"] = true
		_release_at.erase(b["id"])
		_send_button(b, true)
		return
	if _uses_stick() and p.distance_to(STICK_BASE) <= STICK_R * 1.7:
		_owners[idx] = "stick"
		_move_stick(p)
		return
	if not _owners.values().has("mouse"):
		_owners[idx] = "mouse"
		_mouse_pos = p
		_send_mouse(p, true, false)


func _touch_move(idx: int, p: Vector2) -> void:
	var o: Variant = _owners.get(idx)
	if o is String:
		if o == "stick":
			_move_stick(p)
		elif o == "mouse":
			var rel := p - _mouse_pos
			_mouse_pos = p
			_send_mouse(p, true, true, rel)


func _touch_up(idx: int, p: Vector2) -> void:
	var o: Variant = _owners.get(idx)
	_owners.erase(idx)
	if o is Dictionary:
		var b: Dictionary = o
		b["down"] = false
		_release_at[b["id"]] = _clock + MIN_HOLD
	elif o is String:
		if o == "stick":
			_move_stick(STICK_BASE)
		elif o == "mouse":
			_send_mouse(p, false, false)


func _move_stick(p: Vector2) -> void:
	var v := (p - STICK_BASE) / STICK_R
	if v.length() > 1.0:
		v = v.normalized()
	if v.length() < 0.2:
		v = Vector2.ZERO
	_stick_vec = v
	_set_strength("steer_left", maxf(0.0, -v.x))
	_set_strength("steer_right", maxf(0.0, v.x))
	_set_strength("accelerate", maxf(0.0, -v.y))
	_set_strength("brake", maxf(0.0, v.y))


func _set_strength(action: String, s: float) -> void:
	s = snappedf(s, 0.05)
	if is_equal_approx(float(_stick_strength[action]), s):
		return
	_stick_strength[action] = s
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = s > 0.3 or (s > 0.0 and Input.is_action_pressed(action))
	ev.strength = s if ev.pressed else 0.0
	Input.parse_input_event(ev)


func _send_button(b: Dictionary, down: bool) -> void:
	for a: String in b["actions"]:
		var ev := InputEventAction.new()
		ev.action = a
		ev.pressed = down
		ev.strength = 1.0 if down else 0.0
		Input.parse_input_event(ev)
	if int(b["key"]) != 0:
		var k := InputEventKey.new()
		k.keycode = int(b["key"]) as Key
		k.physical_keycode = int(b["key"]) as Key
		k.pressed = down
		Input.parse_input_event(k)


func _tap_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)
	get_tree().create_timer(MIN_HOLD).timeout.connect(func() -> void:
		var up := InputEventAction.new()
		up.action = action
		up.pressed = false
		Input.parse_input_event(up))


func _send_mouse(p: Vector2, pressed: bool, motion: bool, rel: Vector2 = Vector2.ZERO) -> void:
	var ev: InputEvent
	if motion:
		var m := InputEventMouseMotion.new()
		m.position = p
		m.global_position = p
		m.relative = rel
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		ev = m
	else:
		# a motion first so the GUI knows where the "mouse" is, then the click
		var mv := InputEventMouseMotion.new()
		mv.position = p
		mv.global_position = p
		get_viewport().push_input(mv, true)
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = pressed
		b.position = p
		b.global_position = p
		b.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		ev = b
	get_viewport().push_input(ev, true)


func _release_all() -> void:
	for b: Dictionary in _buttons:
		if b["down"]:
			b["down"] = false
			_send_button(b, false)
	_move_stick(STICK_BASE)
	_owners.clear()
	_release_at.clear()


# ---- drawing ----------------------------------------------------------------

func _draw_pad() -> void:
	var font := ThemeDB.fallback_font
	for b: Dictionary in _buttons:
		var c: Vector2 = b["c"]
		var r: float = b["r"]
		var down: bool = b["down"]
		_view.draw_circle(c, r, Color(0, 0, 0, 0.5 if down else 0.28))
		_view.draw_arc(c, r, 0, TAU, 32, Color(1, 1, 1, 0.9 if down else 0.55), 4.0)
		var fs := int(r * 0.55) if String(b["label"]).length() <= 2 else int(r * 0.4)
		var w := font.get_string_size(b["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_view.draw_string(font, c + Vector2(-w * 0.5, fs * 0.35), b["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95))
	if _uses_stick():
		_view.draw_circle(STICK_BASE, STICK_R, Color(0, 0, 0, 0.25))
		_view.draw_arc(STICK_BASE, STICK_R, 0, TAU, 40, Color(1, 1, 1, 0.5), 4.0)
		_view.draw_circle(STICK_BASE + _stick_vec * STICK_R * 0.8, 38.0, Color(1, 1, 1, 0.55))
