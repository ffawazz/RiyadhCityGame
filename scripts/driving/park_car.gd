class_name ParkCar
extends TrafficCar
## Other families' cars in Al-Kharrarah Park: some are parked up near the tents and the lake,
## others cruise slowly over the sand along a loop of waypoints (and wait if you are in front).

var scene: DriveScene
var route: Array[Vector2] = []
var parked: bool = false
var _wp: int = 0
var _yaw: float = 0.0
var _speed_now: float = 0.0


func setup_park(sc: DriveScene, kind: String, color: Color, pos: Vector2, yaw: float, is_parked: bool,
		waypoints: Array[Vector2] = [], cruise_speed: float = 7.0, start_wp: int = 0) -> void:
	scene = sc
	parked = is_parked
	route = waypoints
	cruise = cruise_speed
	_yaw = yaw
	_wp = start_wp
	sync_to_physics = false
	_build(kind, color)
	_put(pos.x, pos.y, yaw)


func _physics_process(delta: float) -> void:
	if parked or route.size() < 2 or scene == null:
		return
	var here := Vector2(position.x, position.z)
	var target := route[_wp]
	var to := target - here
	if to.length() < 6.0:
		_wp = (_wp + 1) % route.size()
		return
	var want := atan2(-to.x, -to.y)          # the car faces -Z
	_yaw = lerp_angle(_yaw, want, 1.0 - exp(-1.6 * delta))
	var go := cruise
	var pl := scene.car
	if pl != null:
		var rel := Vector2(pl.position.x - position.x, pl.position.z - position.z)
		var fwd := Vector2(-sin(_yaw), -cos(_yaw))
		if rel.dot(fwd) > 0.0 and rel.length() < 14.0 and absf(rel.dot(Vector2(-fwd.y, fwd.x))) < 4.0:
			go = 0.0                          # wait for the player's 4x4 to pass
	_speed_now = move_toward(_speed_now, go, 4.0 * delta)
	var fwd2 := Vector2(-sin(_yaw), -cos(_yaw))
	var np := here + fwd2 * _speed_now * delta
	_put(np.x, np.y, _yaw)


func _put(x: float, z: float, yaw: float) -> void:
	var gy := scene.ground_height(x, z)
	var f := Vector2(-sin(yaw), -cos(yaw))
	var front := scene.ground_height(x + f.x * 1.8, z + f.y * 1.8)
	var rear := scene.ground_height(x - f.x * 1.8, z - f.y * 1.8)
	position = Vector3(x, gy, z)
	rotation = Vector3(atan2(front - rear, 3.6), yaw, 0.0)
