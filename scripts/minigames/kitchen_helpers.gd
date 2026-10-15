extends MiniGameBase
## Kitchen: cook two recipes by adding ingredients in order. Press 1/2/3 or click.
## Daniah's hint dims one wrong ingredient each step.

const RECIPES := [
	{"name": "Karak Chai", "steps": ["Water", "Tea", "Cardamom", "Milk"]},
	{"name": "Pancakes", "steps": ["Flour", "Eggs", "Milk", "Butter"]},
	{"name": "Fruit Salad", "steps": ["Apple", "Banana", "Orange", "Honey"]},
	{"name": "Sandwich", "steps": ["Bread", "Cheese", "Tomato", "Cucumber"]},
]
const POOL := ["Salt", "Sand", "Soap", "Rice", "Pepper", "Ketchup", "Ice", "Beans", "Juice", "Lemon"]

var _order: Array = []
var _recipe: int = 0   # position in _order
var _step: int = 0
var _options: Array[String] = []
var _mistakes: int = 0
var _flash: float = 0.0
var _dim: int = -1


func _ready() -> void:
	bg_color = Color.html("f4f1de")
	super()


func _on_start() -> void:
	_order = [0, 1, 2, 3]
	_order.shuffle()
	_order = _order.slice(0, 2)
	_recipe = 0
	_step = 0
	_mistakes = 0
	_make_options()


func _current() -> Dictionary:
	return RECIPES[_order[_recipe]]


func _make_options() -> void:
	var correct: String = _current()["steps"][_step]
	var wrong: Array = POOL.duplicate()
	wrong.shuffle()
	_options = [correct, wrong[0], wrong[1]]
	_options.shuffle()
	_dim = -1
	if float(Game.mod("hints", 0)) > 0.0:
		for i in 3:
			if _options[i] != correct:
				_dim = i
				break


func _choose(i: int) -> void:
	if _options[i] == _current()["steps"][_step]:
		_step += 1
		if _step >= 4:
			_step = 0
			_recipe += 1
			if _recipe >= _order.size():
				complete(3 if _mistakes <= 1 else (2 if _mistakes <= 3 else 1))
				return
		_make_options()
	else:
		_mistakes += 1
		_flash = 0.35


func _opt_rect(i: int) -> Rect2:
	return Rect2(size.x * 0.5 - 420.0 + i * 290.0, size.y - 220.0, 260.0, 120.0)


func _tick(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)


func _on_input(event: InputEvent) -> void:
	var d := digit_of(event)
	if d >= 1 and d <= 3:
		_choose(d - 1)
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		for i in 3:
			if _opt_rect(i).has_point(get_local_mouse_position()):
				_choose(i)


func _draw_game() -> void:
	if not running:
		return
	var r := _current()
	text_c(Vector2(size.x * 0.5, 70), "Cooking: %s" % r["name"], 44, Color.html("bc4749"))
	for i in 4:
		var done := i < _step
		var now := i == _step
		var box := Rect2(size.x * 0.5 - 380.0 + i * 195.0, 120.0, 175.0, 80.0)
		draw_rect(box, Color.html("80b918") if done else (Color.html("ffd166") if now else Color.html("dee2e6")))
		draw_rect(box, Color.html("6c584c"), false, 3.0)
		text_c(box.get_center() + Vector2(0, 8), "%d. %s" % [i + 1, r["steps"][i]], 22, Color.html("1d1d1d"))
	text_c(Vector2(size.x * 0.5, 300), "Next ingredient?", 36, Color.html("3d405b"))
	for i in 3:
		var box := _opt_rect(i)
		var dimmed := i == _dim
		draw_rect(box, Color.html("ced4da") if dimmed else Color.html("a8dadc"))
		draw_rect(box, Color.html("d62828") if _flash > 0.0 else Color.html("457b9d"), false, 5.0)
		text_c(box.get_center() + Vector2(0, 10), "%d  %s" % [i + 1, _options[i]], 30,
				Color.html("868e96") if dimmed else Color.html("1d1d1d"))
