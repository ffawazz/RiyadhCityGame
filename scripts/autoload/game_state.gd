extends Node
## Autoload "Game": all global, persistent state plus static game data.
## Scenes read from here; they never talk to each other directly.

signal character_changed(id: String)

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
		"name": "Duck", "name_ar": "بطة",
		"blurb": "Born to swim! Fastest in the pool.",
		"mods": {"swim_speed": 1.3},
	},
	"goat": {
		"name": "Goat", "name_ar": "ماعز",
		"blurb": "Strong legs! Best at Cornhole tosses and Basketball jumps.",
		"mods": {"jump": 1.3},
	},
	"chicken": {
		"name": "Chicken", "name_ar": "دجاجة",
		"blurb": "Quick reflexes! Great at Ping Pong.",
		"mods": {"reflex": 1.3},
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
	{"label": "Farm Fun", "ids": ["farm_swim", "farm_pingpong", "farm_cornhole", "farm_basketball"], "need": 1},
]

var character_id: String = "daniah"
var animal_id: String = "duck"
var completed: Dictionary = {}       # minigame_id -> best stars (0-3)
var pending_minigame: String = ""    # set by Router before loading the host scene
var minigame_return: String = "city" # Router scene key to go back to
var spawn_id: String = "home"        # where the car appears when a driving scene loads


func _ready() -> void:
	_register_inputs()


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

func new_game() -> void:
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

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "character", character_id)
	cfg.set_value("save", "animal", animal_id)
	cfg.set_value("save", "completed", completed)
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
	spawn_id = "home"
	return true


# --- Input map (registered in code so the project file stays tiny) ------

func _register_inputs() -> void:
	_add_action("accelerate", [KEY_W, KEY_UP])
	_add_action("brake", [KEY_S, KEY_DOWN])
	_add_action("steer_left", [KEY_A, KEY_LEFT])
	_add_action("steer_right", [KEY_D, KEY_RIGHT])
	_add_action("interact", [KEY_E, KEY_ENTER, KEY_KP_ENTER])


func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key as Key
		InputMap.action_add_event(action, ev)
