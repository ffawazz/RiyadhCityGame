class_name AvatarArt
extends RefCounted
## Little vector figures of the three sisters, drawn onto any CanvasItem (used by the
## mini-games and by Portrait). Call from inside a _draw() / _draw_game().


## `feet` = where the figure stands, `scale` = size (1.0 is the character-select size).
static func draw_sister(ci: CanvasItem, who: String, feet: Vector2, scale: float,
		facing: float = 1.0, lift: float = 0.0, tilt: float = 0.0) -> void:
	var data: Dictionary = Game.CHARACTERS[who]
	var heights := {"daniah": 0.8, "sarah": 1.0, "lamia": 0.62}
	ci.draw_set_transform(feet + Vector2(0.0, -lift), tilt, Vector2(scale * facing, scale))
	girl(ci, 0.0, 0.0, float(heights[who]), Color.html(data["color"]), Color.html(data["hair"]), who)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func girl(ci: CanvasItem, cx: float, base_y: float, h: float, dress: Color, hair: Color, who: String) -> void:
	var skin := Color.html("e8b98a")
	var legs_h := 40.0 * h
	var body_h := 150.0 * h
	var body_top := base_y - legs_h - body_h
	var head_r := 28.0
	var head_c := Vector2(cx, body_top - head_r + 4.0)
	# legs + shoes
	ci.draw_rect(Rect2(cx - 20, base_y - legs_h, 14, legs_h), skin)
	ci.draw_rect(Rect2(cx + 6, base_y - legs_h, 14, legs_h), skin)
	ci.draw_rect(Rect2(cx - 24, base_y - 8, 22, 8), Color.html("333333"))
	ci.draw_rect(Rect2(cx + 2, base_y - 8, 22, 8), Color.html("333333"))
	# hair behind head, then dress, then head
	ci.draw_rect(Rect2(cx - 31, head_c.y, 62, 70 * h), hair)
	ci.draw_circle(head_c, head_r + 3.0, hair)
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(cx - 24, body_top), Vector2(cx + 24, body_top),
		Vector2(cx + 38, base_y - legs_h), Vector2(cx - 38, base_y - legs_h)]), dress)
	ci.draw_circle(head_c, head_r, skin)
	# fringe, eyes, smile
	ci.draw_arc(head_c, head_r + 1.0, PI * 1.05, PI * 1.95, 20, hair, 8.0)
	ci.draw_circle(head_c + Vector2(-10, 2), 3.0, Color.BLACK)
	ci.draw_circle(head_c + Vector2(10, 2), 3.0, Color.BLACK)
	ci.draw_arc(head_c + Vector2(0, 8), 9.0, 0.2, PI - 0.2, 12, Color.html("a23b3b"), 2.5)
	match who:
		"daniah": # round glasses
			ci.draw_arc(head_c + Vector2(-10, 2), 10.0, 0, TAU, 24, Color.BLACK, 2.5)
			ci.draw_arc(head_c + Vector2(10, 2), 10.0, 0, TAU, 24, Color.BLACK, 2.5)
			ci.draw_line(head_c + Vector2(-1, 1), head_c + Vector2(1, 1), Color.BLACK, 2.5)
		"sarah": # a book held at her side
			var book := Rect2(cx + 22, body_top + 55 * h, 34, 44)
			ci.draw_rect(book, Color.html("c1121f"))
			ci.draw_rect(Rect2(book.position.x + 4, book.position.y + 4, 26, 36), Color.html("fdf0d5"))
		"lamia": # plush bunny friend
			var pet := Vector2(cx + 50, base_y - 24)
			ci.draw_circle(pet, 18.0, Color.html("f1f1f1"))
			ci.draw_circle(pet + Vector2(0, -22), 12.0, Color.html("f1f1f1"))
			ci.draw_rect(Rect2(pet.x - 9, pet.y - 52, 6, 22), Color.html("f1f1f1"))
			ci.draw_rect(Rect2(pet.x + 3, pet.y - 52, 6, 22), Color.html("f1f1f1"))




## The farm animal avatars (Shatoor the duck, Hassan the goat, the chicken).
static func draw_animal(ci: CanvasItem, kind: String, feet: Vector2, scale: float, facing: float = 1.0, lift: float = 0.0, tilt: float = 0.0) -> void:
	ci.draw_set_transform(feet + Vector2(0.0, -lift), tilt, Vector2(scale * facing, scale))
	match kind:
		"goat":
			goat(ci, 0.0, 0.0)
		"chicken":
			chicken(ci, 0.0, 0.0)
		_:
			duck(ci, 0.0, 0.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func duck(ci: CanvasItem, cx: float, base_y: float) -> void:
	ci.draw_rect(Rect2(cx - 20, base_y - 8, 14, 8), Color.html("ff9f1c"))
	ci.draw_rect(Rect2(cx + 6, base_y - 8, 14, 8), Color.html("ff9f1c"))
	ci.draw_circle(Vector2(cx, base_y - 55), 48.0, Color.html("ffd60a"))
	ci.draw_circle(Vector2(cx - 12, base_y - 55), 24.0, Color.html("f4b400"))   # wing
	ci.draw_circle(Vector2(cx + 22, base_y - 118), 30.0, Color.html("ffd60a"))  # head
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 46, base_y - 120), Vector2(cx + 76, base_y - 112), Vector2(cx + 46, base_y - 104)]),
		Color.html("ff7b00"))
	ci.draw_circle(Vector2(cx + 28, base_y - 126), 4.0, Color.BLACK)


static func goat(ci: CanvasItem, cx: float, base_y: float) -> void:
	var fur := Color.html("e9e4d8")
	for lx in [-44.0, -20.0, 14.0, 38.0]:
		ci.draw_rect(Rect2(cx + lx, base_y - 50, 10, 50), Color.html("8d8574"))
	ci.draw_rect(Rect2(cx - 55, base_y - 105, 110, 60), fur)
	ci.draw_circle(Vector2(cx + 58, base_y - 118), 26.0, fur)                  # head
	ci.draw_line(Vector2(cx + 50, base_y - 140), Vector2(cx + 40, base_y - 165), Color.html("6b5d45"), 6.0)
	ci.draw_line(Vector2(cx + 66, base_y - 140), Vector2(cx + 76, base_y - 165), Color.html("6b5d45"), 6.0)
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 62, base_y - 100), Vector2(cx + 74, base_y - 100), Vector2(cx + 68, base_y - 80)]),
		Color.html("8d8574"))                                               # beard
	ci.draw_circle(Vector2(cx + 66, base_y - 124), 4.0, Color.BLACK)


static func chicken(ci: CanvasItem, cx: float, base_y: float) -> void:
	ci.draw_rect(Rect2(cx - 14, base_y - 30, 5, 30), Color.html("ff9f1c"))
	ci.draw_rect(Rect2(cx + 9, base_y - 30, 5, 30), Color.html("ff9f1c"))
	ci.draw_circle(Vector2(cx, base_y - 70), 44.0, Color.html("fdfdfd"))
	ci.draw_circle(Vector2(cx - 14, base_y - 66), 22.0, Color.html("e0e0e0"))  # wing
	ci.draw_circle(Vector2(cx + 30, base_y - 120), 22.0, Color.html("fdfdfd")) # head
	for i in 3:
		ci.draw_circle(Vector2(cx + 20 + i * 10, base_y - 142 + (i % 2) * 4), 7.0, Color.html("e63946"))
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(cx + 50, base_y - 122), Vector2(cx + 68, base_y - 116), Vector2(cx + 50, base_y - 110)]),
		Color.html("ff9f1c"))
	ci.draw_circle(Vector2(cx + 38, base_y - 126), 3.5, Color.BLACK)
	ci.draw_circle(Vector2(cx + 42, base_y - 104), 6.0, Color.html("e63946")) # wattle
