class_name Car
extends CharacterBody2D
## The family's blue 2019 Mazda CX-9, top-down. Faces +X at rotation 0.
## Arcade handling: W/S throttle + brake/reverse, A/D steer (only while moving).

const MAX_SPEED := 520.0
const ACCEL := 360.0
const BRAKE := 700.0
const COAST := 200.0
const STEER_RATE := 2.4
const SIZE := Vector2(88, 44)

var speed: float = 0.0


func _init() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)


func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("brake", "accelerate")
	if throttle > 0.0:
		speed = move_toward(speed, MAX_SPEED, ACCEL * delta)
	elif throttle < 0.0:
		var rate := BRAKE if speed > 0.0 else ACCEL
		speed = move_toward(speed, -MAX_SPEED * 0.35, rate * delta)
	else:
		speed = move_toward(speed, 0.0, COAST * delta)

	var steer := Input.get_axis("steer_left", "steer_right")
	rotation += steer * STEER_RATE * clampf(speed / MAX_SPEED, -1.0, 1.0) * delta

	var forward := Vector2.RIGHT.rotated(rotation)
	velocity = forward * speed
	move_and_slide()
	speed = velocity.dot(forward) # bumping a wall bleeds speed automatically


func _draw() -> void:
	var half := SIZE * 0.5
	draw_rect(Rect2(-half, SIZE), Color.html("1b4fa0"))                              # body
	draw_rect(Rect2(-half.x + 6, -half.y + 4, SIZE.x - 12, SIZE.y - 8), Color.html("2463c4"))
	draw_rect(Rect2(-22, -half.y + 5, 34, SIZE.y - 10), Color.html("163d7a"))        # roof
	draw_rect(Rect2(14, -half.y + 6, 12, SIZE.y - 12), Color.html("a8dadc"))         # windshield
	draw_rect(Rect2(-34, -half.y + 6, 8, SIZE.y - 12), Color.html("8fc1c4"))         # rear glass
	draw_rect(Rect2(half.x - 5, -half.y + 4, 5, 9), Color.html("fff3b0"))            # headlights
	draw_rect(Rect2(half.x - 5, half.y - 13, 5, 9), Color.html("fff3b0"))
	draw_rect(Rect2(-half.x, -half.y + 4, 4, 9), Color.html("d62828"))               # tail lights
	draw_rect(Rect2(-half.x, half.y - 13, 4, 9), Color.html("d62828"))
