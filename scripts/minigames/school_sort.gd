extends MiniGameBase
## School: sort supplies into the right bag. Keys 1/2/3 or click a bag.
## Daniah's perk: after 2 s of hesitation the right bag lights up.

const GAME_TIME := 30.0
const BAGS := ["Pencil Case", "Book Bag", "Notebook Folder"]
const ITEMS := [
	{"name": "Pencil", "bag": 0, "color": "f4d35e"}, {"name": "Pen", "bag": 0, "color": "3a86ff"},
	{"name": "Crayon", "bag": 0, "color": "ef476f"}, {"name": "Eraser", "bag": 0, "color": "ffafcc"},
	{"name": "Science Book", "bag": 1, "color": "2a9d8f"}, {"name": "Story Book", "bag": 1, "color": "e76f51"},
	{"name": "Atlas", "bag": 1, "color": "457b9d"}, {"name": "Quran Book", "bag": 1, "color": "588157"},
	{"name": "Math Notebook", "bag": 2, "color": "8338ec"}, {"name": "Diary", "bag": 2, "color": "fb5607"},
	{"name": "Sketchbook", "bag": 2, "color": "06d6a0"}, {"name": "Homework Pad", "bag": 2, "color": "ffbe0b"},
]

var _time_left: float = 0.0
var _score: int = 0
var _current: Dictionary = {}
var _idle: float = 0.0
var _flash: float = 0.0
var _flash_ok: bool = true


func _ready() -> void:
	bg_color = Color.html("fdf0d5")
	super()


func _on_start() -> void:
	_time_left = GAME_TIME + float(Game.mod("extra_time", 0.0))
	_score = 0
	_next_item()


func _next_item() -> void:
	_current = ITEMS[randi() % ITEMS.size()]
	_idle = 0.0


func _tick(delta: float) -> void:
	_time_left -= delta
	_idle += delta
	_flash = maxf(0.0, _flash - delta)
	if _time_left <= 0.0:
		complete(maxi(1, stars_from(_score, 5, 9, 14)))


func _bag_rect(i: int) -> Rect2:
	var w := 260.0
	var gap := (size.x - w * 3.0) / 4.0
	return Rect2(gap + i * (w + gap), size.y - 230.0, w, 170.0)


func _choose(bag: int) -> void:
	if bag == int(_current["bag"]):
		_score += 1
		_flash_ok = true
		_next_item()
	else:
		_flash_ok = false
		_idle = 0.0
	_flash = 0.25


func _on_input(event: InputEvent) -> void:
	var d := digit_of(event)
	if d >= 1 and d <= 3:
		_choose(d - 1)
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		for i in 3:
			if _bag_rect(i).has_point(get_local_mouse_position()):
				_choose(i)


func _draw_game() -> void:
	if not running:
		return
	text(Vector2(24, 40), "Time %d    Sorted %d" % [maxi(0, ceili(_time_left)), _score], 28, Color.html("264653"))
	var item_rect := Rect2(size.x * 0.5 - 150.0, 90.0, 300.0, 130.0)
	draw_rect(item_rect, Color.html(_current["color"]))
	draw_rect(item_rect, Color.html("264653"), false, 5.0)
	text_c(item_rect.get_center() + Vector2(0, 12), _current["name"], 34, Color.html("1d1d1d"))
	var hint_on := float(Game.mod("hints", 0)) > 0.0 and _idle > 2.0
	for i in 3:
		var r := _bag_rect(i)
		var col := Color.html("a98467")
		if _flash > 0.0:
			col = Color.html("80b918") if (_flash_ok and i == int(_current["bag"])) else col
		draw_rect(r, col)
		var lit := hint_on and i == int(_current["bag"])
		draw_rect(r, Color.html("ffd166") if lit else Color.html("6c584c"), false, 8.0 if lit else 4.0)
		text_c(r.get_center() + Vector2(0, -6), BAGS[i], 26, Color.WHITE)
		text_c(r.get_center() + Vector2(0, 38), "[%d]" % (i + 1), 30, Color.html("ffe8d6"))
	if _flash > 0.0 and not _flash_ok:
		text_c(Vector2(size.x * 0.5, 290), "Try another bag!", 30, Color.html("d62828"))
