extends Node
## Autoload "Music": plays the soundtrack of the sister you picked.
##   Daniah -> American rock,  Sarah -> Korean pop,  Lamia -> Arabic (maqam Hijaz)
## Tracks are synthesised on the main thread, one bar per slice, starting a moment after
## launch (title screen is idle), then cached. The chosen style is rendered first.

const STYLES := {"daniah": "american", "sarah": "korean", "lamia": "arabic"}
const MUSIC_DIRS := ["res://music", "user://music"]   # plus a "music" folder next to the game .exe
const MUSIC_EXTS := ["mp3", "ogg"]
const START_DELAY := 0.8      # let the first scene finish loading before the heavy work
const SLICE_PAUSE := 0.08     # breathing room between bars while nobody is waiting

var current_style: String = ""

var _player: AudioStreamPlayer
var _cache: Dictionary = {}       # style -> AudioStreamWAV
var _jobs: Dictionary = {}        # style -> MusicSynth (partially rendered)
var _custom: Dictionary = {}       # character id -> user-supplied AudioStream
var _wanted: String = ""
var _pause: float = START_DELAY


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -9.0
	add_child(_player)


## Your own song: drop <name>.mp3 or .ogg (daniah / sarah / lamia) into the game's `music`
## folder and that sister plays it instead of the built-in track.
func custom_stream(character_id: String) -> AudioStream:
	if _custom.has(character_id):
		return _custom[character_id]
	var dirs: Array = MUSIC_DIRS.duplicate()
	dirs.append(OS.get_executable_path().get_base_dir().path_join("music"))
	for dir: String in dirs:
		for ext: String in MUSIC_EXTS:
			var path := "%s/%s.%s" % [dir, character_id, ext]
			if not FileAccess.file_exists(path):
				continue
			var bytes := FileAccess.get_file_as_bytes(path)
			var stream: AudioStream = null
			if ext == "mp3":
				var mp3 := AudioStreamMP3.new()
				mp3.data = bytes
				mp3.loop = true
				stream = mp3
			else:
				var ogg := AudioStreamOggVorbis.load_from_buffer(bytes)
				if ogg != null:
					ogg.loop = true
				stream = ogg
			if stream != null:
				_custom[character_id] = stream
				return stream
	return null


func play_for(character_id: String) -> void:
	var own := custom_stream(character_id)
	if own != null:
		_wanted = ""
		current_style = "custom:" + character_id
		_player.stream = own
		_player.play()
		return
	_wanted = STYLES.get(character_id, "american")
	if _cache.has(_wanted):
		_start(_wanted)


func stop() -> void:
	_wanted = ""
	current_style = ""
	_player.stop()


func _process(delta: float) -> void:
	var waiting := _wanted != "" and not _cache.has(_wanted)
	_pause -= delta
	if _pause > 0.0 and not waiting:
		return
	var style := _next_style()
	if style == "":
		return
	if not _jobs.has(style):
		_jobs[style] = MusicSynth.new(style)
	var job: MusicSynth = _jobs[style]
	var done := job.render_next_bar()
	_pause = 0.0 if waiting else SLICE_PAUSE
	if done:
		_cache[style] = MusicSynth.make_stream(job.result())
		_jobs.erase(style)
		if _wanted == style:
			_start(style)


## The wanted style first, then any style still missing.
func _next_style() -> String:
	if _wanted != "" and not _cache.has(_wanted):
		return _wanted
	for style: String in STYLES.values():
		if not _cache.has(style):
			return style
	return ""


func _start(style: String) -> void:
	if current_style == style and _player.playing:
		return
	current_style = style
	_player.stream = _cache[style]
	_player.play()
