extends Node
## godot --headless res://tests/music_test.tscn -- /tmp/out   (renders each style to a WAV)

func _ready() -> void:
	var out := "/tmp"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var failures := 0
	for style in ["american", "korean", "arabic"]:
		var t0 := Time.get_ticks_msec()
		var bytes := MusicSynth.render_bytes(style)
		var ms := Time.get_ticks_msec() - t0
		var stream := MusicSynth.make_stream(bytes)
		stream.save_to_wav("%s/%s.wav" % [out, style])
		var n := bytes.size() / 2
		var peak := 0
		var sumsq := 0.0
		for i in n:
			var v := bytes.decode_s16(i * 2)
			peak = maxi(peak, absi(v))
			sumsq += float(v) * float(v)
		var rms := sqrt(sumsq / n) / 32767.0
		print("%s: %.1f s of audio, rendered in %d ms, peak=%d rms=%.3f" % [style, float(n) / MusicSynth.RATE, ms, peak, rms])
		if peak < 5000 or peak >= 32767 or rms < 0.03:
			printerr("FAIL levels ", style)
			failures += 1
	print("FAILURES: ", failures)
	get_tree().quit(failures)
