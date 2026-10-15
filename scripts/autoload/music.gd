extends Node
## Autoload "Music": plays the soundtrack of the sister you picked.
##   Daniah -> American rock,  Sarah -> Korean pop,  Lamia -> Arabic (maqam Hijaz)
## Tracks are synthesised on a worker thread the first time they're needed, then cached.

const STYLES := {"daniah": "american", "sarah": "korean", "lamia": "arabic"}

var current_style: String = ""

var _player: AudioStreamPlayer
var _cache: Dictionary = {}       # style -> AudioStreamWAV
var _task_id: int = -1
var _task_style: String = ""
var _task_result: PackedByteArray
var _wanted: String = ""


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -9.0
	add_child(_player)
	_next_job() # warm all three tracks in the background so music starts instantly


func play_for(character_id: String) -> void:
	_wanted = STYLES.get(character_id, "american")
	if _cache.has(_wanted):
		_start(_wanted)
	elif _task_id == -1:
		_next_job()


func stop() -> void:
	_wanted = ""
	current_style = ""
	_player.stop()


func _begin_render(style: String) -> void:
	_task_style = style
	_task_id = WorkerThreadPool.add_task(_render_job.bind(style))


func _render_job(style: String) -> void:
	_task_result = MusicSynth.render_bytes(style)


func _process(_delta: float) -> void:
	if _task_id == -1 or not WorkerThreadPool.is_task_completed(_task_id):
		return
	WorkerThreadPool.wait_for_task_completion(_task_id)
	_task_id = -1
	_cache[_task_style] = MusicSynth.make_stream(_task_result)
	if _wanted == _task_style:
		_start(_task_style)
	_next_job()


## Render the wanted style first, then any style that is still missing.
func _next_job() -> void:
	if _task_id != -1:
		return
	if _wanted != "" and not _cache.has(_wanted):
		_begin_render(_wanted)
		return
	for style: String in STYLES.values():
		if not _cache.has(style):
			_begin_render(style)
			return


func _start(style: String) -> void:
	if current_style == style and _player.playing:
		return
	current_style = style
	_player.stream = _cache[style]
	_player.play()
