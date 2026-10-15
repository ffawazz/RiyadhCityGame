class_name Portrait
extends Control
## Placeholder vector art for the three sisters and the three farm animals.
## Swap for real sprites/TextureRects once art exists; callers only use `kind`.

@export var kind: String = "daniah"


func _ready() -> void:
	custom_minimum_size = Vector2(200, 260)


func _draw() -> void:
	var cx := size.x * 0.5
	var base_y := size.y - 10.0
	match kind:
		"daniah", "sarah", "lamia":
			var data: Dictionary = Game.CHARACTERS[kind]
			var height_scale := {"daniah": 0.8, "sarah": 1.0, "lamia": 0.62}[kind] as float
			_draw_girl(cx, base_y, height_scale, Color.html(data["color"]),
					Color.html(data["hair"]), kind)
		"duck":
			_draw_duck(cx, base_y)
		"goat":
			_draw_goat(cx, base_y)
		"chicken":
			_draw_chicken(cx, base_y)


func _draw_girl(cx: float, base_y: float, h: float, dress: Color, hair: Color, who: String) -> void:
	var skin := Color.html("e8b98a")
	var legs_h := 40.0 * h
	var body_h := 150.0 * h
	var body_top := base_y - legs_h - body_h
	var head_r := 28.0
	var head_c := Vector2(cx, body_top - head_r + 4.0)
	# legs + shoes
	draw_rect(Rect2(cx - 20, base_y - legs_h, 14, legs_h), skin)
	draw_rect(Rect2(cx + 6, base_y - legs_h, 14, legs_h), skin)
	draw_rect(Rect2(cx - 24, base_y - 8, 22, 8), Color.html("333333"))
	draw_rect(Rect2(cx + 2, base_y - 8, 22, 8), Color.html("333333"))
	# hair behind head, then dress, then head
	draw_rect(Rect2(cx - 31, head_c.y, 62, 70 * h), hair)
	draw_circle(head_c, head_r + 3.0, hair)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 24, body_top), Vector2(cx + 24, body_top),
		Vector2(cx + 38, base_y - legs_h), Vector2(cx - 38, base_y - legs_h)]), dress)
	draw_circle(head_c, head_r, skin)
	# fringe, eyes, smile
	draw_arc(head_c, head_r + 1.0, PI * 1.05, PI * 1.95, 20, hair, 8.0)
	draw_circle(head_c + Vector2(-10, 2), 3.0, Color.BLACK)
	draw_circle(head_c + Vector2(10, 2), 3.0, Color.BLACK)
	draw_arc(head_c + Vector2(0, 8), 9.0, 0.2, PI - 0.2, 12, Color.html("a23b3b"), 2.5)
	match who:
		"daniah": # round glasses
			draw_arc(head_c + Vector2(-10, 2), 10.0, 0, TAU, 24, Color.BLACK, 2.5)
			draw_arc(head_c + Vector2(10, 2), 10.0, 0, TAU, 24, Color.BLACK, 2.5)
			draw_line(head_c + Vector2(-1, 1), head_c + Vector2(1, 1), Color.BLACK, 2.5)
		"sarah": # a book held at her side
			var book := Rect2(cx + 22, body_top + 55 * h, 34, 44)
			draw_rect(book, Color.html("c1121f"))
			draw_rect(Rect2(book.position.x + 4, book.position.y + 4, 26, 36), Color.html("fdf0d5"))
		"lamia": # plush bunny friend
			var pet := Vector2(cx + 50, base_y - 24)
			draw_circle(pet, 18.0, Color.html("f1f1f1"))
			draw_circle(pet + Vector2(0, -22), 12.0, Color.html("f1f1f1"))
			draw_rect(Rect2(pet.x - 9, pet.y - 52, 6, 22), Color.html("f1f1f1"))
			draw_rect(Rect2(pet.x + 3, pet.y - 52, 6, 22), Color.html("f1f1f1"))


func _draw_duck(cx: float, base_y: float) -> void:
	draw_rect(Rect2(cx - 20, base_y - 8, 14, 8), Color.html("ff9f1c"))
	draw_rect(Rect2(cx + 6, base_y - 8, 14, 8), Color.html("ff9f1c"))
	draw_circle(Vector2(cx, base_y - 55), 48.0, Color.html("ffd60a"))
	draw_circle(Vector2(cx - 12, base_y - 55), 24.0, Color.html("f4b400"))   # wing
	draw_circle(Vector2(cx + 22, base_y - 118), 30.0, Color.html("ffd60a"))  # head
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 46, base_y - 120), Vector2(cx + 76, base_y - 112), Vector2(cx + 46, base_y - 104)]),
		Color.html("ff7b00"))
	draw_circle(Vector2(cx + 28, base_y - 126), 4.0, Color.BLACK)


func _draw_goat(cx: float, base_y: float) -> void:
	var fur := Color.html("e9e4d8")
	for lx in [-44.0, -20.0, 14.0, 38.0]:
		draw_rect(Rect2(cx + lx, base_y - 50, 10, 50), Color.html("8d8574"))
	draw_rect(Rect2(cx - 55, base_y - 105, 110, 60), fur)
	draw_circle(Vector2(cx + 58, base_y - 118), 26.0, fur)                  # head
	draw_line(Vector2(cx + 50, base_y - 140), Vector2(cx + 40, base_y - 165), Color.html("6b5d45"), 6.0)
	draw_line(Vector2(cx + 66, base_y - 140), Vector2(cx + 76, base_y - 165), Color.html("6b5d45"), 6.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 62, base_y - 100), Vector2(cx + 74, base_y - 100), Vector2(cx + 68, base_y - 80)]),
		Color.html("8d8574"))                                               # beard
	draw_circle(Vector2(cx + 66, base_y - 124), 4.0, Color.BLACK)


func _draw_chicken(cx: float, base_y: float) -> void:
	draw_rect(Rect2(cx - 14, base_y - 30, 5, 30), Color.html("ff9f1c"))
	draw_rect(Rect2(cx + 9, base_y - 30, 5, 30), Color.html("ff9f1c"))
	draw_circle(Vector2(cx, base_y - 70), 44.0, Color.html("fdfdfd"))
	draw_circle(Vector2(cx - 14, base_y - 66), 22.0, Color.html("e0e0e0"))  # wing
	draw_circle(Vector2(cx + 30, base_y - 120), 22.0, Color.html("fdfdfd")) # head
	for i in 3:
		draw_circle(Vector2(cx + 20 + i * 10, base_y - 142 + (i % 2) * 4), 7.0, Color.html("e63946"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 50, base_y - 122), Vector2(cx + 68, base_y - 116), Vector2(cx + 50, base_y - 110)]),
		Color.html("ff9f1c"))
	draw_circle(Vector2(cx + 38, base_y - 126), 3.5, Color.BLACK)
	draw_circle(Vector2(cx + 42, base_y - 104), 6.0, Color.html("e63946")) # wattle
