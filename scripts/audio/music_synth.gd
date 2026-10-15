class_name MusicSynth
extends RefCounted
## Procedural music: each sister's soundtrack is composed in code and rendered to a
## looping 16-bit mono WAV (no audio assets needed). Safe to run on a worker thread.
##
##  american  - Daniah: driving classic-rock (E-A-B-A, power-chord guitar, backbeat)
##  korean    - Sarah : bright K-pop (royal-road IV-V-iii-vi, four-on-the-floor, synth arps)
##  arabic    - Lamia : maqam Hijaz on D, oud + nay, darbuka playing the maqsum rhythm

const RATE := 22050

const W_SINE := 0
const W_SAW := 1
const W_SQUARE := 2
const W_TRI := 3


static func render_bytes(style: String) -> PackedByteArray:
	var buf: PackedFloat32Array
	match style:
		"korean":
			buf = _korean()
		"arabic":
			buf = _arabic()
		_:
			buf = _american()
	return _to_pcm16(buf)


static func make_stream(bytes: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = bytes.size() / 2
	return wav


# ---------------------------------------------------------------- AMERICAN ------

static func _american() -> PackedFloat32Array:
	var bpm := 126.0
	var step := 60.0 / bpm / 4.0          # one 16th note
	var bars := 8
	var buf := _new_buffer(bars * 16, step)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# I - IV - V - IV in E : root notes (bass octave) per bar
	var roots := [40, 45, 47, 45, 40, 45, 47, 45]
	for bar in bars:
		var t0 := bar * 16 * step
		var root: int = roots[bar]
		# drums: backbeat, 8th hats, kick on 1 + 3 (+ the "and" of 3)
		for s in [0, 8, 10]:
			_kick(buf, t0 + s * step, 0.8)
		for s in [4, 12]:
			_snare(buf, t0 + s * step, 0.7, rng)
		for s in range(0, 16, 2):
			_hat(buf, t0 + s * step, 0.22 if s % 4 == 0 else 0.15, rng, 0.05)
		if bar == 7:  # fill
			for s in [12, 13, 14, 15]:
				_snare(buf, t0 + s * step, 0.5, rng)
		# bass guitar: driving 8ths with octave jumps
		var bass_pattern := [0, 0, 12, 0, 0, 7, 12, 5]
		for i in 8:
			var m: int = root + int(bass_pattern[i])
			_osc(buf, t0 + i * 2 * step, step * 1.9, _hz(m), 0.30, W_SAW, 0.004, 5.0, 0.0, 0.0, 1.6)
		# rhythm guitar: palm-muted power chords (root + fifth + octave), open on 1 and 3
		for i in 8:
			var open := i == 0 or i == 4
			var d := step * (3.5 if open else 1.2)
			for iv in [0, 7, 12]:
				_osc(buf, t0 + i * 2 * step, d, _hz(root + 12 + iv), 0.10, W_SAW, 0.003, 3.0 if open else 14.0, 0.0, 0.0, 4.0)
	# lead: E minor pentatonic riff, 2 bars repeated, octave up second time round
	var riff_a := [[0, 71, 2], [3, 74, 1], [4, 76, 3], [8, 74, 2], [10, 71, 2], [12, 69, 2], [14, 71, 2],
			[16, 67, 3], [20, 69, 1], [21, 71, 3], [24, 74, 2], [26, 71, 2], [28, 69, 4]]
	var riff_b := [[0, 76, 2], [2, 74, 2], [4, 71, 4], [8, 69, 2], [10, 71, 2], [12, 74, 4],
			[16, 76, 3], [19, 79, 1], [20, 76, 2], [22, 74, 2], [24, 71, 4], [28, 67, 4]]
	for round in 2:
		var lift := 12 * round
		for pair in 2:
			var riff: Array = riff_a if pair == 0 else riff_b
			var base := (round * 4 + pair * 2) * 16
			for n in riff:
				var note: Array = n
				_osc(buf, (base + int(note[0])) * step, step * float(note[2]) * 0.95, _hz(int(note[1]) + lift - 12),
						0.15, W_SAW, 0.01, 1.6, 5.5, 0.006, 2.5)
	return _finish(buf)


# ----------------------------------------------------------------- KOREAN -------

static func _korean() -> PackedFloat32Array:
	var bpm := 120.0
	var step := 60.0 / bpm / 4.0
	var bars := 8
	var buf := _new_buffer(bars * 16, step)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	# IV - V - iii - vi in C ("royal road"): Fmaj7, G, Em7, Am
	var chords := [
		[53, 57, 60, 64], [55, 59, 62, 67], [52, 55, 59, 62], [57, 60, 64, 69]]
	var hooks := [
		[[0, 76, 2], [2, 77, 2], [4, 81, 4], [8, 79, 2], [10, 77, 2], [12, 76, 4]],
		[[0, 74, 2], [2, 76, 2], [4, 79, 4], [8, 77, 2], [10, 76, 2], [12, 74, 4]],
		[[0, 71, 2], [2, 74, 2], [4, 76, 4], [8, 79, 2], [10, 76, 2], [12, 74, 2], [14, 71, 2]],
		[[0, 69, 2], [2, 72, 2], [4, 76, 4], [8, 72, 2], [10, 69, 2], [12, 72, 4]]]
	for bar in bars:
		var t0 := bar * 16 * step
		var chord: Array = chords[bar % 4]
		var root: int = int(chord[0]) - 12
		# drums: four-on-the-floor, claps on 2 + 4, 16th hats, open hats on the off-beats
		for s in [0, 4, 8, 12]:
			_kick(buf, t0 + s * step, 0.85)
		for s in [4, 12]:
			_clap(buf, t0 + s * step, 0.45, rng)
		for s in 16:
			_hat(buf, t0 + s * step, 0.10 if s % 2 else 0.14, rng, 0.03)
		for s in [2, 6, 10, 14]:
			_hat(buf, t0 + s * step, 0.17, rng, 0.11)
		# pumping off-beat bass
		for s in [2, 6, 10, 14]:
			_osc(buf, t0 + s * step, step * 1.8, _hz(root), 0.26, W_SAW, 0.004, 4.0, 0.0, 0.0, 1.2)
		_osc(buf, t0, step * 1.5, _hz(root), 0.22, W_SINE, 0.003, 6.0)
		# warm pad
		for note in chord:
			for det in [-0.004, 0.004]:
				_osc(buf, t0, step * 16.0, _hz(int(note)) * (1.0 + det), 0.035, W_SAW, 0.25, 0.25)
		# sparkly 16th arpeggio
		var arp := [0, 1, 2, 3, 2, 1, 2, 3, 0, 1, 2, 3, 2, 1, 2, 3]
		for s in 16:
			var m: int = int(chord[int(arp[s]) % 4]) + 12
			_osc(buf, t0 + s * step, step * 0.9, _hz(m), 0.075, W_SQUARE, 0.002, 18.0)
		# the hook (second 4 bars sparkle an octave higher with a bell layer)
		for n in hooks[bar % 4]:
			var note: Array = n
			var midi := int(note[1])
			_osc(buf, t0 + int(note[0]) * step, step * float(note[2]) * 0.95, _hz(midi), 0.16, W_TRI, 0.01, 2.2, 5.0, 0.004)
			_osc(buf, t0 + int(note[0]) * step, step * float(note[2]) * 0.95, _hz(midi), 0.05, W_SQUARE, 0.01, 3.0)
			if bar >= 4:
				_osc(buf, t0 + int(note[0]) * step, step * 2.0, _hz(midi + 12), 0.07, W_SINE, 0.002, 7.0)
	return _finish(buf)


# ------------------------------------------------------------------ ARABIC ------

static func _arabic() -> PackedFloat32Array:
	var bpm := 96.0
	var step := 60.0 / bpm / 4.0
	var bars := 8
	var buf := _new_buffer(bars * 16, step)
	var rng := RandomNumberGenerator.new()
	rng.seed = 37
	# Maqam Hijaz on D: D Eb F# G A Bb C D  (the augmented second Eb->F# is the signature sound)
	var oud_phrases := [
		[[0, 62, 2], [2, 63, 2], [4, 66, 4], [8, 67, 2], [10, 69, 2], [12, 67, 2], [14, 66, 2]],
		[[0, 69, 3], [3, 70, 1], [4, 69, 2], [6, 67, 2], [8, 66, 2], [10, 63, 2], [12, 62, 4]],
		[[0, 74, 3], [3, 75, 1], [4, 74, 2], [6, 72, 2], [8, 70, 2], [10, 69, 2], [12, 67, 2], [14, 66, 2]],
		[[0, 67, 2], [2, 66, 2], [4, 63, 2], [6, 62, 2], [8, 62, 8]]]
	var bass_roots := [38, 38, 39, 38]
	for bar in bars:
		var t0 := bar * 16 * step
		# darbuka: maqsum = Dum Tek _ Tek Dum _ Tek _
		for s in [0, 8]:
			_dum(buf, t0 + s * step, 0.9)
		for s in [2, 6, 12]:
			_tek(buf, t0 + s * step, 0.55, rng)
		for s in [4, 14]:
			_tek(buf, t0 + s * step, 0.2, rng)   # soft ghost taks
		# riq (frame-drum jingles) on the 8ths
		for s in range(0, 16, 2):
			_hat(buf, t0 + s * step, 0.07, rng, 0.06)
		# drone + bass
		var root: int = bass_roots[bar % 4]
		_osc(buf, t0, step * 16.0, _hz(root + 12), 0.075, W_TRI, 0.3, 0.05, 0.4, 0.004)
		_osc(buf, t0, step * 16.0, _hz(root + 19), 0.03, W_SINE, 0.3, 0.05)
		for s in [0, 8]:
			_osc(buf, t0 + s * step, step * 3.0, _hz(root), 0.28, W_SINE, 0.004, 3.0)
		# oud melody (first half) - long notes get tremolo-picked, like a real oud
		var phrase: Array = oud_phrases[bar % 4]
		for n in phrase:
			var note: Array = n
			var len_steps := int(note[2])
			var start := int(note[0])
			if bar < 4:
				_pluck(buf, t0 + start * step, step * float(len_steps), _hz(int(note[1])), 0.34, rng)
				if len_steps >= 4:
					for k in range(1, len_steps):
						_pluck(buf, t0 + (start + k) * step, step * 1.2, _hz(int(note[1])), 0.14, rng)
			else:
				# second half: nay (reed flute) takes the tune an octave up, oud answers underneath
				_nay(buf, t0 + start * step, step * float(len_steps) * 0.98, _hz(int(note[1]) + 12), 0.15, rng)
				_pluck(buf, t0 + start * step, step * float(len_steps), _hz(int(note[1]) - 12), 0.2, rng)
		# qanun-style plucked arpeggio on the offbeats under the nay
		if bar >= 4:
			var scale := [62, 63, 66, 67, 69, 70, 72, 74]
			for s in [1, 5, 9, 13]:
				_pluck(buf, t0 + s * step, step * 2.0, _hz(int(scale[(s + bar) % 8]) + 12), 0.09, rng)
	return _finish(buf)


# --------------------------------------------------------------- instruments ----

static func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (float(midi) - 69.0) / 12.0)


static func _new_buffer(steps: int, step_seconds: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(int(steps * step_seconds * RATE))
	return buf


static func _add(buf: PackedFloat32Array, i: int, v: float) -> void:
	buf[i % buf.size()] += v   # wrap so tails flow into the start of the loop


## Generic oscillator voice. `drive` adds guitar-style saturation, vib_* is vibrato.
static func _osc(buf: PackedFloat32Array, start: float, dur: float, freq: float, amp: float,
		wave: int, attack: float, decay: float, vib_hz: float = 0.0, vib_depth: float = 0.0,
		drive: float = 0.0) -> void:
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var phase := 0.0
	var release := 0.01
	for k in n:
		var t := float(k) / RATE
		var env := minf(t / maxf(attack, 0.0005), 1.0) * exp(-t * decay)
		var tail := dur - t
		if tail < release:
			env *= tail / release
		var f := freq
		if vib_hz > 0.0:
			f *= 1.0 + vib_depth * sin(TAU * vib_hz * t) * minf(t * 4.0, 1.0)
		phase += f / RATE
		var ph := phase - floorf(phase)
		var s := 0.0
		match wave:
			W_SINE:
				s = sin(TAU * ph)
			W_SAW:
				s = ph * 2.0 - 1.0
			W_SQUARE:
				s = 1.0 if ph < 0.5 else -1.0
			W_TRI:
				s = absf(ph * 4.0 - 2.0) - 1.0
		if drive > 0.0:
			s = tanh(s * drive) * 0.8
		_add(buf, i0 + k, s * env * amp)


## Karplus-Strong plucked string (oud).
static func _pluck(buf: PackedFloat32Array, start: float, dur: float, freq: float, amp: float,
		rng: RandomNumberGenerator) -> void:
	var delay := maxi(2, int(RATE / freq))
	var line := PackedFloat32Array()
	line.resize(delay)
	for i in delay:
		line[i] = rng.randf() * 2.0 - 1.0
	var i0 := int(start * RATE)
	var n := int((dur + 0.25) * RATE)
	var pos := 0
	var last := 0.0
	for k in n:
		var cur := line[pos]
		var nxt := line[(pos + 1) % delay]
		var v := (cur + nxt) * 0.5 * 0.997
		line[pos] = v
		pos = (pos + 1) % delay
		last = v
		var tail := float(n - k) / RATE
		var fade := minf(tail / 0.05, 1.0)
		_add(buf, i0 + k, last * amp * fade)


## Breathy reed flute (nay): sine + soft harmonics + vibrato + a little air noise.
static func _nay(buf: PackedFloat32Array, start: float, dur: float, freq: float, amp: float,
		rng: RandomNumberGenerator) -> void:
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var phase := 0.0
	for k in n:
		var t := float(k) / RATE
		var env := minf(t / 0.06, 1.0) * minf((dur - t) / 0.08, 1.0) * (0.85 + 0.15 * sin(TAU * 4.5 * t))
		phase += freq * (1.0 + 0.007 * sin(TAU * 5.2 * t) * minf(t * 3.0, 1.0)) / RATE
		var s := sin(TAU * phase) + 0.25 * sin(TAU * phase * 2.0) + 0.08 * sin(TAU * phase * 3.0)
		s += (rng.randf() * 2.0 - 1.0) * 0.07
		_add(buf, i0 + k, s * env * amp)


static func _kick(buf: PackedFloat32Array, start: float, amp: float) -> void:
	var i0 := int(start * RATE)
	var n := int(0.28 * RATE)
	var phase := 0.0
	for k in n:
		var t := float(k) / RATE
		phase += (48.0 + 110.0 * exp(-t * 28.0)) / RATE
		_add(buf, i0 + k, sin(TAU * phase) * exp(-t * 11.0) * amp)


static func _snare(buf: PackedFloat32Array, start: float, amp: float, rng: RandomNumberGenerator) -> void:
	var i0 := int(start * RATE)
	var n := int(0.22 * RATE)
	for k in n:
		var t := float(k) / RATE
		var noise := rng.randf() * 2.0 - 1.0
		_add(buf, i0 + k, (noise * exp(-t * 20.0) * 0.6 + sin(TAU * 190.0 * t) * exp(-t * 28.0) * 0.5) * amp)


static func _clap(buf: PackedFloat32Array, start: float, amp: float, rng: RandomNumberGenerator) -> void:
	for burst in 3:
		var i0 := int((start + burst * 0.011) * RATE)
		var n := int(0.07 * RATE)
		for k in n:
			var t := float(k) / RATE
			_add(buf, i0 + k, (rng.randf() * 2.0 - 1.0) * exp(-t * 55.0) * amp * 0.6)


static func _hat(buf: PackedFloat32Array, start: float, amp: float, rng: RandomNumberGenerator, dur: float) -> void:
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var last := 0.0
	for k in n:
		var t := float(k) / RATE
		var noise := rng.randf() * 2.0 - 1.0
		_add(buf, i0 + k, (noise - last) * 0.5 * exp(-t * (30.0 / maxf(dur, 0.02) * 0.35)) * amp)
		last = noise


## Darbuka "dum": deep resonant stroke at the centre of the skin.
static func _dum(buf: PackedFloat32Array, start: float, amp: float) -> void:
	var i0 := int(start * RATE)
	var n := int(0.3 * RATE)
	var phase := 0.0
	for k in n:
		var t := float(k) / RATE
		phase += (92.0 + 60.0 * exp(-t * 30.0)) / RATE
		_add(buf, i0 + k, sin(TAU * phase) * exp(-t * 12.0) * amp)


## Darbuka "tek": bright rim stroke.
static func _tek(buf: PackedFloat32Array, start: float, amp: float, rng: RandomNumberGenerator) -> void:
	var i0 := int(start * RATE)
	var n := int(0.09 * RATE)
	var last := 0.0
	for k in n:
		var t := float(k) / RATE
		var noise := rng.randf() * 2.0 - 1.0
		var s := (noise - last) * 0.5 * exp(-t * 45.0) + sin(TAU * 1700.0 * t) * exp(-t * 60.0) * 0.4
		last = noise
		_add(buf, i0 + k, s * amp)


# ------------------------------------------------------------------- output -----

static func _finish(buf: PackedFloat32Array) -> PackedFloat32Array:
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var gain := 0.85 / peak
	for i in buf.size():
		buf[i] = tanh(buf[i] * gain * 1.1) * 0.9
	return buf


static func _to_pcm16(buf: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	return bytes
