extends MiniGameBase
## Baqalah pit stop: grab the snack on the list. Keys 1-6 or click a shelf slot.

const GAME_TIME := 20.0
const SNACKS := [
	{"name": "Dates", "color": "6f4518"}, {"name": "Juice", "color": "f77f00"},
	{"name": "Chips", "color": "fcbf49"}, {"name": "Biscuits", "color": "d4a373"},
	{"name": "Water", "color": "90e0ef"}, {"name": "Laban", "color": "f8f9fa"},
	{"name": "Chocolate", "color": "7f4f24"}, {"name": "Fruit", "color": "e63946"},
	{"name": "Popcorn", "color": "ffe66d"}, {"name": "Cheese", "color": "ffd166"},
]

var _time_left: float = 0.0
var _score: int = 0
var _slots: Array[int] = []   # indices into SNACKS
var _target: int = 0          # index into SNACKS
var _wrong_flash: float = 0.0


func _ready() -> void:
	bg_color = Color.html("ffe8d6")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME + float(Game.mod("extra_time", 0.0))
	_score = 0
	_new_round()


func _new_round() -> void:
	var pool: Array[int] = []
	for i in SNACKS.size():
		pool.append(i)
	pool.shuffle()
	_slots = pool.slice(0, 6)
	_target = _slots[randi() % 6]


func _slot_rect(i: int) -> Rect2:
	var col := i % 3
	var row := i / 3
	return Rect2(size.x * 0.5 - 330.0 + col * 230.0, 200.0 + row * 170.0, 200.0, 140.0)


func _grab(slot: int) -> void:
	if _slots[slot] == _target:
		_score += 1
		_new_round()
	else:
		_wrong_flash = 0.3


func _tick(delta: float) -> void:
	_time_left -= delta
	_wrong_flash = maxf(0.0, _wrong_flash - delta)
	if _time_left <= 0.0:
		complete(maxi(1, stars_from(_score, 5, 8, 11)))


func _on_input(event: InputEvent) -> void:
	var d := digit_of(event)
	if d >= 1 and d <= 6:
		_grab(d - 1)
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		for i in 6:
			if _slot_rect(i).has_point(get_local_mouse_position()):
				_grab(i)


func _draw_game() -> void:
	if not running:
		return
	text(Vector2(24, 40), "Time %d    Packed %d" % [maxi(0, ceili(_time_left)), _score], 28, Color.html("3d405b"))
	text_c(Vector2(size.x * 0.5, 120), "Grab: %s!" % SNACKS[_target]["name"], 48, Color.html("bc4749"))
	for i in 6:
		var r := _slot_rect(i)
		var s: Dictionary = SNACKS[_slots[i]]
		draw_rect(r, Color.html("e5e5e5"))
		draw_rect(r.grow(-30.0), Color.html(s["color"]))
		draw_rect(r, Color.html("bc4749") if _wrong_flash > 0.0 else Color.html("6c584c"), false, 4.0)
		text_c(Vector2(r.get_center().x, r.end.y - 8), "%d  %s" % [i + 1, s["name"]], 22, Color.html("1d1d1d"))
