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


