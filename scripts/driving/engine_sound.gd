class_name EngineSound
extends AudioStreamPlayer
## Real-time synthesised engine, tyre squeal and crash thump (no audio files needed).
## The Car drives `engine_hz`, `load`, `screech` and `thump`.

const RATE := 22050.0

var engine_hz: float = 40.0
var load: float = 0.0
var screech: float = 0.0
var thump: float = 0.0

var _phase: float = 0.0
var _thump_phase: float = 0.0
var _playback: AudioStreamGeneratorPlayback
var _last_noise: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.12
	stream = gen
	volume_db = -9.0
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var frames := mini(_playback.get_frames_available(), 2048)
	var inc := engine_hz / RATE
	for i in frames:
		_phase = fmod(_phase + inc, 1.0)
		var s := sin(TAU * _phase) * 0.55
		s += sin(TAU * _phase * 2.0) * (0.22 + 0.2 * load)
		s += sin(TAU * _phase * 3.0) * (0.12 + 0.15 * load)
		s += sin(TAU * _phase * 5.0) * 0.06 * load
		var n := _rng.randf() * 2.0 - 1.0
		s += n * (0.03 + 0.07 * load)
		if screech > 0.01:
			s += (n - _last_noise) * screech * 0.35   # high-passed noise = squeal
		_last_noise = n
		if thump > 0.001:
			_thump_phase = fmod(_thump_phase + 62.0 / RATE, 1.0)
			s += sin(TAU * _thump_phase) * thump * 1.2
			thump *= 0.9993
		_playback.push_frame(Vector2(s, s) * 0.5)
