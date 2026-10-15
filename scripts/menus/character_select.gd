extends Control
## Pick Daniah, Sarah or Lamia, then start the day in the city.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := UIKit.centered_column(self, Color.html("264653"))
	col.add_theme_constant_override("separation", 6)
	col.add_child(UIKit.label("Who's driving today?", 38))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	col.add_child(row)

	var first_button: Button = null
	for id: String in Game.CHARACTERS:
		var data: Dictionary = Game.CHARACTERS[id]
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 8)
		var portrait := Portrait.new()
		portrait.kind = id
		portrait.min_size = Vector2(150, 170)
		card.add_child(portrait)
		card.add_child(UIKit.label("%s  %s" % [data["name"], data["name_ar"]], 30))
		card.add_child(UIKit.label(data["title"], 20, Color.html("ffd479")))
		card.add_child(UIKit.label(data["blurb"], 15, Color.html("dddddd"), 270.0))
		var pick := UIKit.button("Choose %s" % data["name"], _on_pick.bind(id), Vector2(260, 46))
		card.add_child(pick)
		var song := UIKit.label("", 14, Color.html("b8e0d2"), 270.0)
		_song_labels[id] = song
		card.add_child(song)
		_refresh_song_label(id)
		card.add_child(UIKit.button("Choose song...", _pick_song.bind(id), Vector2(260, 32)))
		row.add_child(card)
		if first_button == null:
			first_button = pick

	var back := UIKit.button("Back", func() -> void: Router.go("main_menu"), Vector2(160, 36))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(back)
	first_button.grab_focus()


var _song_labels: Dictionary = {}


func _refresh_song_label(id: String) -> void:
	var path := Music.custom_path(id)
	(_song_labels[id] as Label).text = ("Song: %s" % path.get_file()) if path != "" else "Song: built-in track"


func _pick_song(id: String) -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		DisplayServer.file_dialog_show("Choose a song (mp3 or ogg)", OS.get_system_dir(OS.SYSTEM_DIR_MUSIC), "",
				false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.mp3, *.ogg ; Music"]),
				Callable(self, "_on_song_chosen").bind(id))
	else:
		(_song_labels[id] as Label).text = "Put %s.mp3 in the game's music folder" % id


func _on_song_chosen(ok: bool, paths: PackedStringArray, _filter: int, id: String) -> void:
	if ok and paths.size() > 0:
		if not Music.set_custom_song(id, paths[0]):
			(_song_labels[id] as Label).text = "Could not play that file (use mp3 or ogg)"
			return
	_refresh_song_label(id)


func _on_pick(id: String) -> void:
	Game.select_character(id)
	Music.play_for(id)
	Game.spawn_id = "home"
	Router.go("city")
