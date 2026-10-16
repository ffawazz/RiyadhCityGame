class_name Hints
extends RefCounted
## What to call the buttons on screen: keyboard keys on a PC, PlayStation or Xbox names when a
## gamepad is being used, the on-screen button names on a phone. Game.input_mode / Game.pad_style
## say which one is current; adapt() rewrites keyboard instructions ("press SPACE") for it.

const NAMES := {
	"kbd": {"confirm": "Space", "back": "Esc", "interact": "E", "camera": "C", "turbo": "Shift", "swap": "Tab", "map": "M",
			"gas": "W", "brake": "S", "handbrake": "Space", "stick": "WASD"},
	"touch": {"confirm": "OK", "back": "ESC", "interact": "E", "camera": "CAM", "turbo": "TURBO", "swap": "SWAP", "map": "MAP",
			"gas": "GAS", "brake": "BRAKE", "handbrake": "DRIFT", "stick": "the joystick"},
	"xbox": {"confirm": "A", "back": "B", "interact": "X", "camera": "Y", "turbo": "RB", "swap": "LB", "map": "View",
			"gas": "RT", "brake": "LT", "handbrake": "A", "stick": "the left stick"},
	"ps": {"confirm": "Cross", "back": "Circle", "interact": "Square", "camera": "Triangle", "turbo": "R1", "swap": "L1", "map": "Share",
			"gas": "R2", "brake": "L2", "handbrake": "Cross", "stick": "the left stick"},
}


## "kbd", "touch", "ps" or "xbox" - the naming set to show right now.
static func style() -> String:
	if Game.input_mode == "pad":
		return pad_style()
	return Game.input_mode


## PlayStation or Xbox, from the pad's name (or the player's choice in the Controller test screen).
static func pad_style() -> String:
	if Game.pad_style_pref == "ps" or Game.pad_style_pref == "xbox":
		return Game.pad_style_pref
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return "xbox"
	var n := Input.get_joy_name(pads[0]).to_lower()
	for word in ["ps3", "ps4", "ps5", "dualshock", "dualsense", "sony", "playstation", "wireless controller"]:
		if n.contains(word):
			return "ps"
	return "xbox"


static func btn(kind: String) -> String:
	return (NAMES[style()] as Dictionary).get(kind, kind)


static func is_pad() -> bool:
	return Game.input_mode == "pad"


## The "press this" line shown over the driving / farm HUD.
static func drive_help() -> String:
	if is_pad():
		return "%s gas  %s brake  left stick steer  %s handbrake = drift!  %s TURBO  %s enter a place  %s camera  %s menu\nRight stick = look around the car" % [
				btn("gas"), btn("brake"), btn("handbrake"), btn("turbo"), btn("interact"), btn("camera"), btn("back")]
	if Game.input_mode == "touch":
		return "Touch: < > steer   GAS / BRAKE   TURBO   DRIFT = handbrake   E = enter a place   CAM = change view   ESC = menu"
	return "W/S gas & brake  A/D steer  SPACE handbrake = drift!  SHIFT = TURBO  E enter  Esc menu\nCamera: C view  |  hold right mouse + drag, or J L I K  = orbit  |  wheel or U O = zoom  |  hold B = look back  |  V = lock view"


static func farm_help() -> String:
	if is_pad():
		return "%s walk   %s jump   %s play   %s big map   Walk into a glowing circle to play a game!   %s menu" % [
				btn("stick"), btn("confirm"), btn("interact"), btn("map"), btn("back")]
	if Game.input_mode == "touch":
		return "Joystick walk   JUMP   E play   MAP big map   Walk into a glowing circle to play a game!"
	return "WASD walk   SPACE jump   E play   M big map   Walk into a glowing circle to play a game!   Esc menu"


## Rewrites keyboard / mouse instructions for a gamepad or phone. Keyboard: unchanged.
static func adapt(s: String) -> String:
	var st := style()
	if st == "kbd":
		return s
	var n: Dictionary = NAMES[st]
	var conf: String = n["confirm"]
	var stick: String = n["stick"]
	var swap: String = n["swap"]
	var pairs := [
		["Move the mouse (or WASD / drag your finger) and click, tap or press SPACE", "Move with %s and press %s" % [stick, conf]],
		["Aim with the mouse (or drag your finger), click / tap or press SPACE to shoot, TAB (SWAP button) switches", "Aim with %s, press %s to shoot, %s switches" % [stick, conf, swap]],
		["Move the mouse (or WASD / drag your finger) to steer the kite.", "Steer the kite with %s." % stick],
		["Move with A / D or the arrow keys.", "Move with %s." % stick],
		["W / Up / Space to jump", "%s to jump" % conf],
		["WASD walk, E / Space to use.", "%s to walk, %s to use." % [stick, conf]],
		["WASD to run.", "%s to run." % stick],
		["WASD to move.", "%s to move." % stick],
		["Pick a food with 1 / 2 / 3 (or the arrow keys), aim with the mouse and click or tap a goat", "Pick a food with %s, aim with %s and press %s on a goat" % [swap, stick, conf]],
		["Click or tap the eggs", "Press %s on the eggs" % conf],
		["Click each kebab", "Press %s on each kebab" % conf],
		["Hold D / Right for gas, A / Left to brake", "Push %s right for gas, left to brake" % stick],
		["tilt with W / S", "tilt with %s up / down" % stick],
		["press UP / W at the top", "push %s up at the top" % stick],
		["W / Up = motor, S / Down = slow down, A / D steer", "%s up = motor, down = slow down, left / right steer" % stick],
		["A / D change lane, SPACE jumps", "%s left / right changes lane, %s jumps" % [stick, conf]],
		["hold A or D to do a flip", "hold %s left or right to do a flip" % stick],
		["W tucks in", "up on %s tucks in" % stick],
		["TAB / LB / 1 / 2 switch weapon", "%s switches weapon" % swap],
		["1 2 3 / LB = pick food  -  click or press A on a goat to feed it", "%s = pick food  -  press %s on a goat to feed it" % [swap, conf]],
		["SPACE = pump when it swings forward   UP / W = jump off at the top", "%s = pump when it swings forward   %s up = jump off at the top" % [conf, stick]],
		["D / Right = gas    A / Left = brake    W / S = tilt in the air", "%s right = gas   left = brake   up / down = tilt in the air" % stick],
		["W motor   S slow   A / D steer", "%s up = motor   down = slow   left / right = steer" % stick],
		["SPACE just before landing = higher bounce    A / D = flip    W = tuck", "%s just before landing = higher bounce    %s left / right = flip    up = tuck" % [conf, stick]],
		["click a kebab when", "press %s on a kebab when" % conf],
		["click a goat", "press %s on a goat" % conf],
		["click or press", "press"],
		["Click or tap", "Press %s" % conf],
		["click, tap or press SPACE", "press %s" % conf],
		["click or tap", "press %s" % conf],
		["pressing SPACE", "pressing %s" % conf],
		["Press SPACE", "Press %s" % conf],
		["press SPACE", "press %s" % conf],
		["SPACE", conf],
		["TAB", swap],
		["WASD", stick],
		["(E / Space)", "(%s)" % conf],
		["(Esc to skip)", "(%s to skip)" % n["back"]],
	]
	var out := s
	for p: Array in pairs:
		out = out.replace(p[0], p[1])
	return out
