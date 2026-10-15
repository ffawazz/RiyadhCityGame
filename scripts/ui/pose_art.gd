class_name PoseArt
extends RefCounted
## Action poses of the chosen sister (swimming, shooting, swinging, riding) drawn with simple
## shapes, in her own dress / hair colours. Facing right; `pos` is the body centre / feet.

const SKIN := Color("e8b98a")


static func _cols(who: String) -> Array:
	var d: Dictionary = Game.CHARACTERS[who]
	return [Color.html(d["color"]), Color.html(d["hair"])]


static func _limb(ci: CanvasItem, a: Vector2, b: Vector2, w: float, c: Color) -> void:
	ci.draw_line(a, b, c, w)
	ci.draw_circle(b, w * 0.5, c)


## Front-crawl swimmer: head, cap, alternating arms, kicking legs, splashes.
static func swimmer(ci: CanvasItem, who: String, pos: Vector2, t: float, s: float = 1.0) -> void:
	var c := _cols(who)
	var dress: Color = c[0]
	var hair: Color = c[1]
	var water := pos.y + 6.0 * s
	# body in the water
	ci.draw_rect(Rect2(pos.x - 46 * s, pos.y - 4 * s, 70 * s, 20 * s), dress.darkened(0.1))
	ci.draw_circle(pos + Vector2(-46 * s, 6 * s), 10 * s, dress.darkened(0.1))
	# kicking legs
	for i in 2:
		var k := sin(t * 14.0 + i * PI) * 6.0 * s
		_limb(ci, pos + Vector2(-50 * s, 6 * s), pos + Vector2(-76 * s, 6 * s + k), 8 * s, SKIN)
		ci.draw_circle(pos + Vector2(-82 * s, 6 * s + k * 1.4), 5 * s, Color(1, 1, 1, 0.7))
	# head + cap + goggles
	var hc := pos + Vector2(36 * s, -2 * s)
	ci.draw_circle(hc, 17 * s, SKIN)
	ci.draw_arc(hc, 18 * s, PI * 0.95, PI * 2.05, 14, hair, 9 * s)
	ci.draw_rect(Rect2(hc + Vector2(2 * s, -6 * s), Vector2(14 * s, 7 * s)), Color(0.1, 0.1, 0.1, 0.8))
	ci.draw_circle(hc + Vector2(9 * s, 10 * s), 2.5 * s, Color("a23b3b"))
	# arms: one reaches forward while the other pulls back
	for i in 2:
		var a := t * 7.0 + i * PI
		var shoulder := pos + Vector2(18 * s, -2 * s)
		var reach := Vector2(cos(a), sin(a)) * 30.0 * s
		var hand := shoulder + Vector2(reach.x, -absf(reach.y) * 0.9 - 6 * s) if sin(a) > 0.0 else shoulder + Vector2(-reach.x * 0.5 + 8 * s, 10 * s)
		_limb(ci, shoulder, hand, 8 * s, SKIN)
	# water line + splash
	for k in 4:
		var wx := pos.x - 70.0 * s + k * 50.0 * s
		ci.draw_arc(Vector2(wx, water + 4.0 * s), 18.0 * s, 0.2, PI - 0.2, 10, Color(1, 1, 1, 0.55), 3.0)
	for i in 5:
		var sx := pos.x + 50 * s + i * 7.0 * s
		ci.draw_circle(Vector2(sx, water - absf(sin(t * 9.0 + i)) * 8.0 * s), 2.5 * s, Color(1, 1, 1, 0.8))


## Basketball shooter. phase: 0 = ball low (aiming), 1 = arms fully up (release). feet = ground point.
static func shooter(ci: CanvasItem, who: String, feet: Vector2, phase: float, s: float = 1.0, with_ball: bool = true) -> Vector2:
	var c := _cols(who)
	var dress: Color = c[0]
	var hair: Color = c[1]
	var h := {"daniah": 0.85, "sarah": 1.0, "lamia": 0.68}[who] as float
	var crouch := (1.0 - phase) * 14.0 * s
	var hip := feet + Vector2(0, -52 * s * h + crouch)
	var neck := hip + Vector2(0, -62 * s * h)
	var head := neck + Vector2(2 * s, -22 * s)
	# legs
	_limb(ci, hip + Vector2(-8 * s, 0), feet + Vector2(-12 * s, 0), 11 * s, SKIN)
	_limb(ci, hip + Vector2(8 * s, 0), feet + Vector2(14 * s, 0), 11 * s, SKIN)
	ci.draw_rect(Rect2(feet + Vector2(-22 * s, -6 * s), Vector2(20 * s, 7 * s)), Color("f1faee"))
	ci.draw_rect(Rect2(feet + Vector2(4 * s, -6 * s), Vector2(22 * s, 7 * s)), Color("f1faee"))
	# jersey
	ci.draw_colored_polygon(PackedVector2Array([neck + Vector2(-17 * s, 0), neck + Vector2(17 * s, 0),
			hip + Vector2(22 * s, 8 * s), hip + Vector2(-22 * s, 8 * s)]), dress)
	# hair behind, head, fringe
	ci.draw_circle(head + Vector2(-5 * s, 6 * s), 22 * s, hair)
	ci.draw_circle(head, 18 * s, SKIN)
	ci.draw_arc(head, 19 * s, PI * 1.0, PI * 1.9, 16, hair, 7 * s)
	ci.draw_circle(head + Vector2(8 * s, -1 * s), 2.5 * s, Color.BLACK)
	ci.draw_arc(head + Vector2(7 * s, 7 * s), 5 * s, 0.2, PI - 0.2, 8, Color("a23b3b"), 2.0)
	# arms: from low in front of the chest, up and over the head
	var shoulder := neck + Vector2(4 * s, 6 * s)
	var hand_low := shoulder + Vector2(26 * s, 22 * s)
	var hand_up := shoulder + Vector2(18 * s, -62 * s * h - 6 * s)
	var hand := hand_low.lerp(hand_up, phase)
	var elbow := shoulder.lerp(hand, 0.5) + Vector2(2 * s, 14 * s * (1.0 - phase))
	_limb(ci, shoulder, elbow, 9 * s, SKIN)
	_limb(ci, elbow, hand, 9 * s, SKIN)
	var ball := hand + Vector2(2 * s, -14 * s)
	if with_ball:
		ci.draw_circle(ball, 15 * s, Color("e76f51"))
		ci.draw_arc(ball, 15 * s, 0, TAU, 16, Color("7f2a14"), 2.0)
		ci.draw_line(ball + Vector2(-15 * s, 0), ball + Vector2(15 * s, 0), Color("7f2a14"), 2.0)
	return ball


## Girl sitting on a swing seat seen from the side. `lean` -1..1 swings the legs (back = -1).
static func swinger(ci: CanvasItem, who: String, seat: Vector2, lean: float, s: float = 1.0) -> void:
	var c := _cols(who)
	var dress: Color = c[0]
	var hair: Color = c[1]
	var hip := seat + Vector2(0, -6 * s)
	var neck := hip + Vector2(-lean * 6 * s, -54 * s)
	var head := neck + Vector2(-lean * 4 * s, -20 * s)
	# legs tuck back and stretch forward with the swing
	var knee := hip + Vector2(26 * s, 4 * s)
	var foot := knee + Vector2((10 + lean * 22) * s, 28 * s - lean * 14 * s)
	_limb(ci, hip, knee, 11 * s, SKIN)
	_limb(ci, knee, foot, 10 * s, SKIN)
	ci.draw_rect(Rect2(foot + Vector2(-4 * s, -3 * s), Vector2(18 * s, 7 * s)), Color("f1faee"))
	ci.draw_colored_polygon(PackedVector2Array([neck + Vector2(-14 * s, 0), neck + Vector2(14 * s, 0),
			hip + Vector2(26 * s, 4 * s), hip + Vector2(-16 * s, 4 * s)]), dress)
	ci.draw_circle(head + Vector2(-6 * s, 8 * s), 20 * s, hair)
	ci.draw_circle(head, 17 * s, SKIN)
	ci.draw_arc(head, 18 * s, PI, PI * 1.9, 14, hair, 7 * s)
	ci.draw_circle(head + Vector2(7 * s, -1 * s), 2.5 * s, Color.BLACK)
	ci.draw_arc(head + Vector2(6 * s, 6 * s), 5 * s, 0.2, PI - 0.2, 8, Color("a23b3b"), 2.0)
	# arms up to the ropes
	_limb(ci, neck + Vector2(0, 6 * s), neck + Vector2(14 * s, -34 * s), 8 * s, SKIN)
