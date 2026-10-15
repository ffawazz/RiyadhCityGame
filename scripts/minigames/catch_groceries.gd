extends MiniGameBase
## Tamimi Supermarket mini-game: catch falling groceries in a basket.
## Perks: Sarah = wider basket, Daniah = slower fall, Lamia = extra time.

const GAME_TIME := 30.0
const BASKET_SPEED := 650.0
const BASKET_W := 120.0
const ITEM_RADIUS := 18.0
const ITEMS := [
	{"letter": "D", "color": "8a4b2a", "good": true},   # dates
	{"letter": "M", "color": "f1faee", "good": true},   # milk
	{"letter": "B", "color": "e9a23b", "good": true},   # bread
	{"letter": "A", "color": "d62828", "good": true},   # apple
	{"letter": "S", "color": "8d99ae", "good": false},  # soap - dodge it
]

var _time_left: float = 0.0
var _score: int = 0
var _basket_x: float = 0.0
var _basket_w: float = BASKET_W
var _spawn_timer: float = 0.0
var _items: Array = []  # {"pos": Vector2, "speed": float, "data": Dictionary}


func _ready() -> void:
	bg_color = Color.html("f1e3c2")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME + float(Game.mod("extra_time", 0.0))
	_score = 0
	_basket_w = BASKET_W * float(Game.mod("catch_width", 1.0))
	_basket_x = size.x * 0.5
	_items.clear()
	_spawn_timer = 0.0


func _tick(delta: float) -> void:
	_time_left -= delta
	var dir := Input.get_axis("steer_left", "steer_right")
	_basket_x = clampf(_basket_x + dir * BASKET_SPEED * delta, _basket_w * 0.5, size.x - _basket_w * 0.5)

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = randf_range(0.5, 0.9)
		var item_data: Dictionary = ITEMS[randi() % ITEMS.size()]
		if not item_data["good"] and randf() < 0.4:
			item_data = ITEMS[0] # keep soap rarer
		_items.append({
			"pos": Vector2(randf_range(40.0, size.x - 40.0), -20.0),
			"speed": randf_range(170.0, 260.0),
			"data": item_data,
		})

	var fall_mult := float(Game.mod("slow_fall", 1.0))
	var catch_rect := Rect2(_basket_x - _basket_w * 0.5, size.y - 80.0, _basket_w, 50.0).grow(ITEM_RADIUS)
	for i in range(_items.size() - 1, -1, -1):
		var it: Dictionary = _items[i]
		var pos: Vector2 = it["pos"]
		pos.y += float(it["speed"]) * fall_mult * delta
		it["pos"] = pos
		if catch_rect.has_point(pos):
			var data: Dictionary = it["data"]
			_score = (_score + 1) if data["good"] else maxi(0, _score - 1)
			_items.remove_at(i)
		elif pos.y > size.y + ITEM_RADIUS:
			_items.remove_at(i)

	if _time_left <= 0.0:
		complete(3 if _score >= 12 else (2 if _score >= 7 else (1 if _score >= 3 else 0)))


func _draw_game() -> void:
	if not running:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, size.y - 30.0, size.x, 30.0), Color.html("c8b27a")) # shop floor
	var basket := Rect2(_basket_x - _basket_w * 0.5, size.y - 80.0, _basket_w, 50.0)
	draw_rect(basket, Color.html("b5651d"))
	draw_rect(basket, Color.html("6f3b0f"), false, 4.0)
	for it: Dictionary in _items:
		var data: Dictionary = it["data"]
		var pos: Vector2 = it["pos"]
		draw_circle(pos, ITEM_RADIUS, Color.html(data["color"]))
		draw_string(font, pos + Vector2(-7, 7), data["letter"], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.BLACK)
	draw_string(font, Vector2(24, 40), "Time %d    Groceries %d    (don't catch S = soap)" % [
			maxi(0, ceili(_time_left)), _score], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.html("264653"))
