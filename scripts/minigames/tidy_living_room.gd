extends MiniGameBase
## Living room: tidy up all 8 things. Press the number on each item or click it.
## Sarah's long reach makes the click targets bigger.

const GAME_TIME := 25.0
const KINDS := [
	{"name": "cushion", "color": "e07a5f"}, {"name": "toy car", "color": "3d85c6"},
	{"name": "book", "color": "81b29a"}, {"name": "ball", "color": "f2cc8f"},
	{"name": "teddy", "color": "a98467"}, {"name": "blocks", "color": "9d4edd"},
	{"name": "remote", "color": "495057"}, {"name": "slipper", "color": "ff6b6b"},
]

var _time_left: float = 0.0
var _items: Array = []   # {"pos": Vector2, "kind": Dictionary, "n": int, "gone": bool}
var _tidied: int = 0


func _ready() -> void:
	bg_color = Color.html("e9d8a6")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME + float(Game.mod("extra_time", 0.0))
	_tidied = 0
	_items.clear()
	for i in KINDS.size():
		var col := i % 4
		var row := i / 4
		_items.append({
			"pos": Vector2(size.x * (0.2 + 0.2 * col) + randf_range(-30, 30), 220.0 + row * 200.0 + randf_range(-30, 30)),
			"kind": KINDS[i], "n": i + 1, "gone": false})
	_items.shuffle()
	for i in _items.size():
		_items[i]["n"] = i + 1


func _tidy(i: int) -> void:
	if _items[i]["gone"]:
		return
	_items[i]["gone"] = true
	_tidied += 1
	if _tidied >= _items.size():
		complete(3 if _time_left > 8.0 else 2)


func _tick(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0 and running:
		complete(1)


func _on_input(event: InputEvent) -> void:
	var d := digit_of(event)
	if d >= 1 and d <= _items.size():
		_tidy(d - 1)
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var radius := 48.0 * float(Game.mod("reach", 1.0))
		for i in _items.size():
			if (_items[i]["pos"] as Vector2).distance_to(get_local_mouse_position()) <= radius:
				_tidy(i)


func _draw_game() -> void:
	if not running:
		return
	text(Vector2(24, 40), "Time %d    Tidied %d / %d" % [maxi(0, ceili(_time_left)), _tidied, _items.size()], 28, Color.html("3d405b"))
	draw_rect(Rect2(size.x * 0.5 - 140, size.y - 90, 280, 70), Color.html("8d6e63"))
	text_c(Vector2(size.x * 0.5, size.y - 45), "TOY BOX", 28, Color.WHITE)
	for it: Dictionary in _items:
		if it["gone"]:
			continue
		var pos: Vector2 = it["pos"]
		var kind: Dictionary = it["kind"]
		draw_circle(pos, 40.0, Color.html(kind["color"]))
		draw_arc(pos, 40.0, 0, TAU, 32, Color.html("3d405b"), 3.0)
		text_c(pos + Vector2(0, 8), str(it["n"]), 28, Color.WHITE)
		text_c(pos + Vector2(0, 66), kind["name"], 20, Color.html("3d405b"))
