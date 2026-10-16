extends Node
## Autoload "Game": all global, persistent state plus static game data.
## Scenes read from here; they never talk to each other directly.

signal character_changed(id: String)

## Shown in the main menu and the driving HUD so you can tell which version you are running.
const BUILD_ID := "b8 - turbo, big slope, Kharrarah park"

const SAVE_PATH := "user://riyadh_kids_save.cfg"

## The three playable sisters. "mods" are tiny gameplay perks that any
## mini-game can query with Game.mod("key", default).
const CHARACTERS := {
	"daniah": {
		"name": "Daniah", "name_ar": "دانية",
		"title": "The Clever One",
		"blurb": "Glasses on, brain on! Items fall a little slower and puzzles give an extra hint.",
		"color": "7b5cd6", "hair": "2e1f17",
		"mods": {"slow_fall": 0.85, "hints": 1},
	},
	"sarah": {
		"name": "Sarah", "name_ar": "سارة",
		"title": "The Bookworm",
		"blurb": "Tallest of the three! A longer reach means a wider basket and easier shelves.",
		"color": "2a9d8f", "hair": "5a3825",
		"mods": {"catch_width": 1.35, "reach": 1.3},
	},
	"lamia": {
		"name": "Lamia", "name_ar": "لمياء",
		"title": "The Animal Friend",
		"blurb": "Animals love her! Gets bonus helpers at the farm and extra time in animal games.",
		"color": "f4845f", "hair": "1f1a17",
		"mods": {"animal_bonus": 1.25, "extra_time": 5.0},
	},
}

## Farm avatars (chosen once we arrive at Al-Muzahimiyah).
const ANIMALS := {
	"duck": {
		"name": "Shatoor", "name_ar": "شاطور", "species": "Duck",
		"blurb": "Born to swim! Fastest in the pool.",
		"mods": {"swim_speed": 1.3},
	},
	"goat": {
		"name": "Hassan", "name_ar": "حسن", "species": "Goat",
		"blurb": "Strong legs! Best at Cornhole tosses and Basketball jumps.",
		"mods": {"jump": 1.3},
	},
	"chicken": {
		"name": "Chicken", "name_ar": "دجاجة", "species": "Chicken",
		"blurb": "Quick reflexes! Great at Ping Pong.",
		"mods": {"reflex": 1.3},
	},
	"cat": {
		"name": "Mishmish", "name_ar": "مشمش", "species": "Cat",
		"blurb": "Quick paws! Great at catching, jumping and the trampoline.",
		"mods": {"reflex": 1.2, "jump": 1.15, "grab": 1.15},
	},
	"hedgehog": {
		"name": "Qunfuz", "name_ar": "قنفذ", "species": "Hedgehog",
		"blurb": "Spiky and clever! Finds sand treasure and picks lemons for longer.",
		"mods": {"grab": 1.3, "dig": 1.3},
	},
}

## Every place the car can enter. "action": "scene" swaps scene,
## "minigame" launches a mini-game then returns to "return".
## "spawn" (optional) is the spawn id to use when the next scene loads.
const LOCATIONS := {
	"home": {
		"title": "Home", "title_ar": "البيت",
		"action": "scene", "target": "home_hub", "color": "ffd166",
	},
	"supermarket": {
		"title": "Tamimi Supermarket", "title_ar": "أسواق التميمي",
		"action": "minigame", "target": "supermarket_catch", "return": "city", "color": "ef476f",
	},
	"school": {
		"title": "School", "title_ar": "المدرسة",
		"action": "minigame", "target": "school_puzzle", "return": "city", "color": "06d6a0",
	},
	"farm": {
		"title": "Road Trip: Al-Muzahimiyah Farm", "title_ar": "مزرعة المزاحمية",
		"action": "scene", "target": "farm_highway", "color": "8ac926",
	},
	"city_return": {
		"title": "Back to Riyadh", "title_ar": "العودة للرياض",
		"action": "scene", "target": "city", "spawn": "farm", "color": "adb5bd",
	},
	"baqalah": {
		"title": "Baqalah Pit Stop", "title_ar": "بقالة",
		"action": "minigame", "target": "baqalah_snacks", "return": "farm_highway", "color": "ff9f1c",
	},
	"kharrarah": {
		"title": "Al-Kharrarah Park", "title_ar": "منتزه الخرارة",
		"action": "scene", "target": "kharrarah_park", "color": "52b788",
	},
	"kharrarah_exit": {
		"title": "Back to the road", "title_ar": "العودة للطريق",
		"action": "scene", "target": "farm_highway", "spawn": "kharrarah", "color": "adb5bd",
	},
	"park_bbq": {
		"title": "Camping & BBQ", "title_ar": "التخييم والشواء",
		"action": "minigame", "target": "park_bbq", "return": "kharrarah_park", "color": "ff7b00",
	},
	"park_kite": {
		"title": "Fly a Kite", "title_ar": "الطائرات الورقية",
		"action": "minigame", "target": "park_kite", "return": "kharrarah_park", "color": "9b5de5",
	},
	"park_boat": {
		"title": "Boat Ride on the Lake", "title_ar": "بحيرة الخرارة",
		"action": "minigame", "target": "park_boat", "return": "kharrarah_park", "color": "48cae4",
	},
	"farm_exit": {
		"title": "Drive Home", "title_ar": "العودة للبيت",
		"action": "scene", "target": "city", "spawn": "home", "color": "ffd166",
	},
	"farm_swim": {
		"title": "Swimming Pool", "title_ar": "المسبح",
		"action": "minigame", "target": "farm_swim", "return": "farm_world", "color": "48cae4",
	},
	"farm_pingpong": {
		"title": "Ping Pong", "title_ar": "تنس الطاولة",
		"action": "minigame", "target": "farm_pingpong", "return": "farm_world", "color": "ef476f",
	},
	"farm_cornhole": {
		"title": "Cornhole", "title_ar": "كورنهول",
		"action": "minigame", "target": "farm_cornhole", "return": "farm_world", "color": "f4a261",
	},
	"farm_basketball": {
		"title": "Basketball", "title_ar": "كرة السلة",
		"action": "minigame", "target": "farm_basketball", "return": "farm_world", "color": "fcbf49",
	},
	"farm_archery": {
		"title": "Bottle Archery", "title_ar": "رماية",
		"action": "minigame", "target": "farm_archery", "return": "farm_world", "color": "9b5de5",
	},
	"farm_swing": {
		"title": "Swing Set", "title_ar": "المرجيحة",
		"action": "minigame", "target": "farm_swing", "return": "farm_world", "color": "f15bb5",
	},
	"farm_moto": {
		"title": "Motorbike Track", "title_ar": "دباب",
		"action": "minigame", "target": "farm_moto", "return": "farm_world", "color": "fb5607",
	},
	"farm_lemons": {
		"title": "Lemon Picking", "title_ar": "قطف الليمون",
		"action": "minigame", "target": "farm_lemons", "return": "farm_world", "color": "ffe14d",
	},
	"farm_goatfeed": {
		"title": "Feed the Goats", "title_ar": "إطعام الماعز",
		"action": "minigame", "target": "farm_goatfeed", "return": "farm_world", "color": "c8b6ff",
	},
	"farm_eggs": {
		"title": "Collect Eggs", "title_ar": "جمع البيض",
		"action": "minigame", "target": "farm_eggs", "return": "farm_world", "color": "fff1c9",
	},
	"farm_sand": {
		"title": "Sand Digging", "title_ar": "اللعب بالرمل",
		"action": "minigame", "target": "farm_sand", "return": "farm_world", "color": "e9c46a",
	},
	"farm_trampoline": {
		"title": "Trampoline", "title_ar": "ترامبولين",
		"action": "minigame", "target": "farm_trampoline", "return": "farm_world", "color": "ff5d8f",
	},
	"farm_slide": {
		"title": "Slide", "title_ar": "زحليقة",
		"action": "minigame", "target": "farm_slide", "return": "farm_world", "color": "4cc9f0",
	},
	"barn": {
		"title": "Barn: Change Animal", "title_ar": "الحظيرة",
		"action": "scene", "target": "animal_select", "color": "a98467",
	},
	"garage": {
		"title": "Mazda Service: Repair", "title_ar": "ورشة مازدا",
		"action": "repair", "color": "4cc9f0",
	},
	"farm_gate": {
		"title": "Farm Gate", "title_ar": "بوابة المزرعة",
		"action": "scene", "target": "animal_select", "color": "8ac926",
	},
}

## Today's checklist shown in the driving HUD. A goal is done once "need"
## of its mini-games have at least one star.
const DAILY_GOALS := [
	{"label": "Tamimi Supermarket", "ids": ["supermarket_catch"], "need": 1},
	{"label": "School", "ids": ["school_puzzle"], "need": 1},
	{"label": "Living Room", "ids": ["living_room"], "need": 1},
	{"label": "Kitchen", "ids": ["kitchen"], "need": 1},
	{"label": "Backyard", "ids": ["backyard"], "need": 1},
	{"label": "Al-Kharrarah Park", "ids": ["park_bbq", "park_kite", "park_boat"], "need": 1},
	{"label": "Farm Fun", "ids": ["farm_swim", "farm_pingpong", "farm_cornhole", "farm_basketball", "farm_archery", "farm_swing", "farm_moto", "farm_lemons", "farm_goatfeed", "farm_eggs", "farm_sand", "farm_trampoline", "farm_slide"], "need": 1},
]

var character_id: String = "daniah"
var animal_id: String = "duck"
var completed: Dictionary = {}       # minigame_id -> best stars (0-3)
var drift_total: int = 0            # drift points banked this session
var car_damage: float = 0.0          # 0 = perfect, 100 = wrecked
var car_hits: Array = []             # recent crashes, replayed to rebuild the dents
var custom_music: Dictionary = {}    # character id -> path of the song file the player chose
var pending_minigame: String = ""    # set by Router before loading the host scene
var minigame_return: String = "city" # Router scene key to go back to
var spawn_id: String = "home"        # where the car appears when a driving scene loads


func _ready() -> void:
	_register_inputs()
	_install_arabic_font()
	load_settings()


# --- Characters ---------------------------------------------------------

func character() -> Dictionary:
	return CHARACTERS[character_id]


func animal() -> Dictionary:
	return ANIMALS[animal_id]


## Perk lookup across the chosen character and (at the farm) the chosen animal.
func mod(key: String, default: Variant = 1.0) -> Variant:
	var char_mods: Dictionary = character()["mods"]
	if char_mods.has(key):
		return char_mods[key]
	var animal_mods: Dictionary = animal()["mods"]
	return animal_mods.get(key, default)


func select_character(id: String) -> void:
	character_id = id
	character_changed.emit(id)


func select_animal(id: String) -> void:
	animal_id = id


# --- Progress -----------------------------------------------------------

func repair_car() -> void:
	car_damage = 0.0
	car_hits.clear()


func new_game() -> void:
	repair_car()
	completed.clear()
	animal_id = "duck"
	spawn_id = "home"


func record_result(minigame_id: String, stars: int) -> void:
	var best: int = completed.get(minigame_id, 0)
	completed[minigame_id] = maxi(best, clampi(stars, 0, 3))


func stars_for(minigame_id: String) -> int:
	return completed.get(minigame_id, 0)


func goal_done(goal: Dictionary) -> bool:
	var count := 0
	for id: String in goal["ids"]:
		if stars_for(id) > 0:
			count += 1
	return count >= int(goal["need"])


func daily_lines() -> Array[String]:
	var lines: Array[String] = []
	for goal: Dictionary in DAILY_GOALS:
		lines.append("%s %s" % ["[x]" if goal_done(goal) else "[ ]", goal["label"]])
	return lines


# --- Save / load --------------------------------------------------------

const SETTINGS_PATH := "user://riyadh_kids_settings.cfg"


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("music", "custom_music", custom_music)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		custom_music = cfg.get_value("music", "custom_music", {})


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "character", character_id)
	cfg.set_value("save", "animal", animal_id)
	cfg.set_value("save", "completed", completed)
	cfg.set_value("save", "car_damage", car_damage)
	cfg.save(SAVE_PATH)


func load_game() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	var saved_char: String = cfg.get_value("save", "character", "daniah")
	var saved_animal: String = cfg.get_value("save", "animal", "duck")
	character_id = saved_char if CHARACTERS.has(saved_char) else "daniah"
	animal_id = saved_animal if ANIMALS.has(saved_animal) else "duck"
	completed = cfg.get_value("save", "completed", {})
	car_damage = float(cfg.get_value("save", "car_damage", 0.0))
	car_hits.clear()
	spawn_id = "home"
	return true


# --- Input map (registered in code so the project file stays tiny) ------

func _register_inputs() -> void:
	# gamepad (Xbox / PlayStation / TV remote pads): triggers drive, the left stick and the D-pad
	# move in every direction (so walking and the mini-games work without a keyboard)
	_add_action("accelerate", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_TRIGGER_RIGHT, 1.0], [JOY_AXIS_LEFT_Y, -1.0]], 0.3)
	_add_action("brake", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_TRIGGER_LEFT, 1.0], [JOY_AXIS_LEFT_Y, 1.0]], 0.3)
	_add_action("steer_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]], 0.2)
	_add_action("steer_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]], 0.2)
	_add_action("swap_item", [KEY_TAB, KEY_Q], [JOY_BUTTON_LEFT_SHOULDER])
	_add_action("map", [KEY_M], [JOY_BUTTON_BACK])
	# menus: A = OK, B = back, D-pad / left stick move the focus (the built-in UI actions)
	_add_action("ui_accept", [], [JOY_BUTTON_A])
	_add_action("ui_cancel", [], [JOY_BUTTON_B])
	_add_action("ui_up", [], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add_action("ui_down", [], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add_action("ui_left", [], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_add_action("ui_right", [], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_add_action("handbrake", [KEY_SPACE], [JOY_BUTTON_A])
	_add_action("camera", [KEY_C], [JOY_BUTTON_Y])
	_add_action("turbo", [KEY_SHIFT], [JOY_BUTTON_RIGHT_SHOULDER])
	_add_action("interact", [KEY_E, KEY_ENTER, KEY_KP_ENTER], [JOY_BUTTON_X])


func _add_action(action: String, keys: Array, buttons: Array = [], axes: Array = [],
		deadzone: float = 0.5) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key as Key
		InputMap.action_add_event(action, ev)
	for button in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = button as JoyButton
		InputMap.action_add_event(action, jb)
	for axis in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axis[0] as JoyAxis
		jm.axis_value = axis[1]
		InputMap.action_add_event(action, jm)


## Bundled Noto Sans Arabic becomes a fallback of the default font, so Arabic
## text (menu title, number plate) renders the same on every PC.
func _install_arabic_font() -> void:
	var arabic := load("res://assets/fonts/NotoSansArabic.ttf") as Font
	if arabic != null:
		ThemeDB.fallback_font.fallbacks = [arabic]
