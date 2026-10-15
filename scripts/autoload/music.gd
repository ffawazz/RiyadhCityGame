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
var _custom_path: Dictionary = {}  # character id -> the file it came from
var _wanted: String = ""
var _pause: float = START_DELAY


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = -9.0
	add_child(_player)


## Your own song for a sister. Looked up in this order:
##   1. the file she was given with "Choose song..." on the character screen
##   2. music/<name>.mp3|ogg next to the game (or user://music), also any file in that folder
##      whose name contains her name (lamia, sarah, daniah) - or "mukassarat" / "مكسرات" for Lamia
func custom_stream(character_id: String) -> AudioStream:
	if _custom.has(character_id):
		return _custom[character_id]
	var candidates: Array = []
	var chosen: String = Game.custom_music.get(character_id, "")
	if chosen != "" and FileAccess.file_exists(chosen):
		candidates.append(chosen)
	var dirs: Array = MUSIC_DIRS.duplicate()
	dirs.append(OS.get_executable_path().get_base_dir().path_join("music"))
	for dir: String in dirs:
		for ext: String in MUSIC_EXTS:
			candidates.append("%s/%s.%s" % [dir, character_id, ext])
		var da := DirAccess.open(dir)
		if da != null:
			for f in da.get_files():
				var low := f.to_lower()
				var ext2 := low.get_extension()
				if not MUSIC_EXTS.has(ext2):
					continue
				if low.contains(character_id) or (character_id == "lamia" and (low.contains("mukassarat") or low.contains("mkassarat") or f.contains("مكسرات"))):
					candidates.append("%s/%s" % [dir, f])
	for path: String in candidates:
		var stream := _load_audio(path)
		if stream != null:
			_custom[character_id] = stream
			_custom_path[character_id] = path
			return stream
	return null


func custom_path(character_id: String) -> String:
	custom_stream(character_id)
	return _custom_path.get(character_id, "")


## Called after the player picks a file.
func set_custom_song(character_id: String, path: String) -> bool:
	_custom.erase(character_id)
	_custom_path.erase(character_id)
	Game.custom_music[character_id] = path
	Game.save_settings()
	return custom_stream(character_id) != null


func _load_audio(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	match path.get_extension().to_lower():
		"mp3":
			var mp3 := AudioStreamMP3.new()
			mp3.data = bytes
			mp3.loop = true
			return mp3
		"ogg":
			var ogg := AudioStreamOggVorbis.load_from_buffer(bytes)
			if ogg != null:
				ogg.loop = true
			return ogg
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
