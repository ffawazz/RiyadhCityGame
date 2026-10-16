extends CanvasLayer
## Autoload "Router": the only place that changes scenes.
## Adds a fade transition and the driving <-> mini-game round trip.
##
## Flow:  driving scene --enter_location()--> mini-game host --finish_minigame()--> back

const SCENES := {
	"main_menu": "res://scenes/main_menu.tscn",
	"character_select": "res://scenes/character_select.tscn",
	"city": "res://scenes/city.tscn",
	"farm_highway": "res://scenes/farm_highway.tscn",
	"home_hub": "res://scenes/home_hub.tscn",
	"animal_select": "res://scenes/animal_select.tscn",
	"farm_world": "res://scenes/farm_world.tscn",
	"kharrarah_park": "res://scenes/kharrarah_park.tscn",
	"minigame": "res://scenes/minigame_host.tscn",
}

const FADE_TIME := 0.25

var _fade: ColorRect
var _busy := false
var _toast_label: Label
var _toast_id: int = 0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color(0.05, 0.07, 0.12)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	# a small notice when a controller connects or drops (TV pads go to sleep and reconnect)
	_toast_label = Label.new()
	_toast_label.add_theme_font_size_override("font_size", 26)
	_toast_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast_label.add_theme_constant_override("outline_size", 8)
	_toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 60)
	_toast_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_label.visible = false
	_toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_label)
	Input.joy_connection_changed.connect(_on_joy_changed)


## Fade out, swap to a registered scene, fade in.
func go(scene_key: String) -> void:
	if _busy:
		return
	if not SCENES.has(scene_key):
		push_error("Router: unknown scene key '%s'" % scene_key)
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP # block clicks mid-transition
	var out := create_tween()
	out.tween_property(_fade, "modulate:a", 1.0, FADE_TIME)
	await out.finished
	get_tree().change_scene_to_file(SCENES[scene_key])
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
	await back.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## Called by driving scenes when the player presses E inside a location zone.
func enter_location(location_id: String) -> void:
	var loc: Dictionary = Game.LOCATIONS[location_id]
	Game.spawn_id = loc.get("spawn", location_id)
	if location_id == "home":
		Game.repair_car()      # Dad fixes the car at home
	match loc["action"]:
		"minigame":
			start_minigame(loc["target"], loc["return"])
		"scene":
			go(loc["target"])


func start_minigame(minigame_id: String, return_to: String) -> void:
	Game.pending_minigame = minigame_id
	Game.minigame_return = return_to
	go("minigame")


func finish_minigame(stars: int) -> void:
	Game.record_result(Game.pending_minigame, stars)
	Game.save_game()
	go(Game.minigame_return)


func _on_joy_changed(device: int, connected: bool) -> void:
	if connected:
		toast("Controller connected: %s" % Input.get_joy_name(device))
	else:
		toast("Controller disconnected - press its PS / Xbox button to reconnect")


func toast(text: String, seconds: float = 3.5) -> void:
	_toast_id += 1
	var mine := _toast_id
	_toast_label.text = text
	_toast_label.visible = true
	await get_tree().create_timer(seconds).timeout
	if mine == _toast_id:
		_toast_label.visible = false
