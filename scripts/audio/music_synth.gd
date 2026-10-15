class_name MusicSynth
extends RefCounted
## Procedural music: each sister's soundtrack is composed in code and rendered, one
## bar at a time, into a looping 16-bit mono WAV (no audio assets needed).
##
##  american  - Daniah: driving classic-rock (E-A-B-A, power-chord guitar, backbeat)
##  korean    - Sarah : bright K-pop (royal-road IV-V-iii-vi, four-on-the-floor, synth arps)
##  arabic    - Lamia : maqam Hijaz on D, oud + nay, darbuka playing the maqsum rhythm
##
## Usage:  var job := MusicSynth.new("korean"); while not job.render_next_bar(): pass
##         var stream := MusicSynth.make_stream(job.result())

const RATE := 22050

const W_SINE := 0
const W_SAW := 1
const W_SQUARE := 2
const W_TRI := 3

var style: String
var bars: int = 8
var next_bar: int = 0

var _buf: PackedFloat32Array
var _step: float          # seconds per 16th note
var _rng := RandomNumberGenerator.new()


func _init(style_name: String) -> void:
	style = style_name
	var bpm := 126.0
	match style:
		"korean":
			bpm = 120.0
			_rng.seed = 23
		"arabic":
			bpm = 96.0
			_rng.seed = 37
		_:
			style = "american"
			_rng.seed = 11
	_step = 60.0 / bpm / 4.0
	_buf = PackedFloat32Array()
	_buf.resize(int(bars * 16 * _step * RATE))


## Renders one bar. Returns true once every bar is done.
func render_next_bar() -> bool:
	match style:
		"korean":
			_korean_bar(next_bar)
		"arabic":
			_arabic_bar(next_bar)
		_:
			_american_bar(next_bar)
	next_bar += 1
	return next_bar >= bars


func progress() -> float:
	return float(next_bar) / float(bars)


func result() -> PackedByteArray:
	var peak := 0.0001
	for v in _buf:
		peak = maxf(peak, absf(v))
	var gain := 0.85 / peak * 1.1
	var bytes := PackedByteArray()
	bytes.resize(_buf.size() * 2)
	for i in _buf.size():
		bytes.encode_s16(i * 2, int(clampf(tanh(_buf[i] * gain) * 0.9, -1.0, 1.0) * 32767.0))
	return bytes


static func render_bytes(style_name: String) -> PackedByteArray:
	var job := MusicSynth.new(style_name)
	while not job.render_next_bar():
		pass
	return job.result()


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
# I - IV - V - IV in E, twice. Lead riff: E-minor pentatonic over two bars.

const RIFF_A := [[0, 71, 2], [3, 74, 1], [4, 76, 3], [8, 74, 2], [10, 71, 2], [12, 69, 2], [14, 71, 2],
		[16, 67, 3], [20, 69, 1], [21, 71, 3], [24, 74, 2], [26, 71, 2], [28, 69, 4]]
const RIFF_B := [[0, 76, 2], [2, 74, 2], [4, 71, 4], [8, 69, 2], [10, 71, 2], [12, 74, 4],
		[16, 76, 3], [19, 79, 1], [20, 76, 2], [22, 74, 2], [24, 71, 4], [28, 67, 4]]
const AM_ROOTS := [40, 45, 47, 45, 40, 45, 47, 45]
const AM_BASS := [0, 0, 12, 0, 0, 7, 12, 5]


func _american_bar(bar: int) -> void:
	var t0 := bar * 16 * _step
	var root: int = AM_ROOTS[bar]
	for s in [0, 8, 10]:
		_kick(t0 + s * _step, 0.8)
	for s in [4, 12]:
		_snare(t0 + s * _step, 0.7)
	for s in range(0, 16, 2):
		_hat(t0 + s * _step, 0.22 if s % 4 == 0 else 0.15, 0.05)
	if bar == 7:  # drum fill
		for s in [12, 13, 14, 15]:
			_snare(t0 + s * _step, 0.5)
	for i in 8:   # bass guitar: driving 8ths
		_osc(t0 + i * 2 * _step, _step * 1.9, _hz(root + int(AM_BASS[i])), 0.30, W_SAW, 0.004, 5.0, 0.0, 0.0, 1.6)
	for i in 8:   # rhythm guitar: palm-muted power chords, open on 1 and 3
		var open := i == 0 or i == 4
		var d := _step * (3.5 if open else 1.2)
		for iv in [0, 7, 12]:
			_osc(t0 + i * 2 * _step, d, _hz(root + 12 + iv), 0.10, W_SAW, 0.003, 3.0 if open else 14.0, 0.0, 0.0, 4.0)
	# lead guitar: this bar's slice of the 2-bar riff (octave up in the second round)
	var round := bar / 4
	var pair := (bar % 4) / 2
	var bar_in_pair := bar % 2
	var riff: Array = RIFF_A if pair == 0 else RIFF_B
	for n in riff:
		var note: Array = n
		if int(note[0]) / 16 != bar_in_pair:
			continue
		var start := t0 + (int(note[0]) % 16) * _step
		_osc(start, _step * float(note[2]) * 0.95, _hz(int(note[1]) + 12 * round - 12), 0.15, W_SAW, 0.01, 1.6, 5.5, 0.006, 2.5)


# ----------------------------------------------------------------- KOREAN -------
# IV - V - iii - vi in C ("royal road"): Fmaj7, G, Em7, Am

const KP_CHORDS := [[53, 57, 60, 64], [55, 59, 62, 67], [52, 55, 59, 62], [57, 60, 64, 69]]
const KP_HOOKS := [
	[[0, 76, 2], [2, 77, 2], [4, 81, 4], [8, 79, 2], [10, 77, 2], [12, 76, 4]],
	[[0, 74, 2], [2, 76, 2], [4, 79, 4], [8, 77, 2], [10, 76, 2], [12, 74, 4]],
	[[0, 71, 2], [2, 74, 2], [4, 76, 4], [8, 79, 2], [10, 76, 2], [12, 74, 2], [14, 71, 2]],
	[[0, 69, 2], [2, 72, 2], [4, 76, 4], [8, 72, 2], [10, 69, 2], [12, 72, 4]]]
const KP_ARP := [0, 1, 2, 3, 2, 1, 2, 3, 0, 1, 2, 3, 2, 1, 2, 3]


func _korean_bar(bar: int) -> void:
	var t0 := bar * 16 * _step
	var chord: Array = KP_CHORDS[bar % 4]
	var root: int = int(chord[0]) - 12
	for s in [0, 4, 8, 12]:       # four-on-the-floor
		_kick(t0 + s * _step, 0.85)
	for s in [4, 12]:
		_clap(t0 + s * _step, 0.45)
	for s in 16:
		_hat(t0 + s * _step, 0.10 if s % 2 else 0.14, 0.03)
	for s in [2, 6, 10, 14]:      # open hats + pumping off-beat bass
		_hat(t0 + s * _step, 0.17, 0.11)
		_osc(t0 + s * _step, _step * 1.8, _hz(root), 0.26, W_SAW, 0.004, 4.0, 0.0, 0.0, 1.2)
	_osc(t0, _step * 1.5, _hz(root), 0.22, W_SINE, 0.003, 6.0)
	for note in chord:            # warm detuned pad
		for det in [-0.004, 0.004]:
			_osc(t0, _step * 16.0, _hz(int(note)) * (1.0 + det), 0.035, W_SAW, 0.25, 0.25)
	for s in 16:                  # sparkly 16th arpeggio
		var m: int = int(chord[int(KP_ARP[s]) % 4]) + 12
		_osc(t0 + s * _step, _step * 0.9, _hz(m), 0.075, W_SQUARE, 0.002, 18.0)
	for n in KP_HOOKS[bar % 4]:   # the hook (bell layer on the repeat)
		var note: Array = n
		var midi := int(note[1])
		var start := t0 + int(note[0]) * _step
		var dur := _step * float(note[2]) * 0.95
		_osc(start, dur, _hz(midi), 0.16, W_TRI, 0.01, 2.2, 5.0, 0.004)
		_osc(start, dur, _hz(midi), 0.05, W_SQUARE, 0.01, 3.0)
		if bar >= 4:
			_osc(start, _step * 2.0, _hz(midi + 12), 0.07, W_SINE, 0.002, 7.0)


# ------------------------------------------------------------------ ARABIC ------
# Maqam Hijaz on D: D Eb F# G A Bb C D (the augmented second Eb -> F# is the signature).

const AR_PHRASES := [
	[[0, 62, 2], [2, 63, 2], [4, 66, 4], [8, 67, 2], [10, 69, 2], [12, 67, 2], [14, 66, 2]],
	[[0, 69, 3], [3, 70, 1], [4, 69, 2], [6, 67, 2], [8, 66, 2], [10, 63, 2], [12, 62, 4]],
	[[0, 74, 3], [3, 75, 1], [4, 74, 2], [6, 72, 2], [8, 70, 2], [10, 69, 2], [12, 67, 2], [14, 66, 2]],
	[[0, 67, 2], [2, 66, 2], [4, 63, 2], [6, 62, 2], [8, 62, 8]]]
const AR_BASS := [38, 38, 39, 38]
const AR_SCALE := [62, 63, 66, 67, 69, 70, 72, 74]


func _arabic_bar(bar: int) -> void:
	var t0 := bar * 16 * _step
	for s in [0, 8]:              # darbuka maqsum: Dum Tek _ Tek Dum _ Tek _
		_dum(t0 + s * _step, 0.9)
	for s in [2, 6, 12]:
		_tek(t0 + s * _step, 0.55)
	for s in [4, 14]:
		_tek(t0 + s * _step, 0.2)  # soft ghost taks
	for s in range(0, 16, 2):     # riq jingles
		_hat(t0 + s * _step, 0.07, 0.06)
	var root: int = AR_BASS[bar % 4]
	_osc(t0, _step * 16.0, _hz(root + 12), 0.075, W_TRI, 0.3, 0.05, 0.4, 0.004)   # drone
	_osc(t0, _step * 16.0, _hz(root + 19), 0.03, W_SINE, 0.3, 0.05)
	for s in [0, 8]:
		_osc(t0 + s * _step, _step * 3.0, _hz(root), 0.28, W_SINE, 0.004, 3.0)
	for n in AR_PHRASES[bar % 4]:
		var note: Array = n
		var len_steps := int(note[2])
		var start := int(note[0])
		var midi := int(note[1])
		if bar < 4:
			# oud melody; long notes are tremolo-picked like a real oud
			_pluck(t0 + start * _step, _step * float(len_steps), _hz(midi), 0.34)
			if len_steps >= 4:
				for k in range(1, len_steps):
					_pluck(t0 + (start + k) * _step, _step * 1.2, _hz(midi), 0.14)
		else:
			# second half: nay (reed flute) carries the tune, oud answers an octave below
			_nay(t0 + start * _step, _step * float(len_steps) * 0.98, _hz(midi + 12), 0.15)
			_pluck(t0 + start * _step, _step * float(len_steps), _hz(midi - 12), 0.2)
	if bar >= 4:                  # qanun-style plucks on the off-beats
		for s in [1, 5, 9, 13]:
			_pluck(t0 + s * _step, _step * 2.0, _hz(int(AR_SCALE[(s + bar) % 8]) + 12), 0.09)


# --------------------------------------------------------------- instruments ----

func _hz(midi: int) -> float:
	return 440.0 * pow(2.0, (float(midi) - 69.0) / 12.0)


## Generic oscillator voice. `drive` adds guitar-style saturation, vib_* is vibrato.
func _osc(start: float, dur: float, freq: float, amp: float, wave: int, attack: float,
		decay: float, vib_hz: float = 0.0, vib_depth: float = 0.0, drive: float = 0.0) -> void:
	var size := _buf.size()
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var inv := 1.0 / RATE
	var phase := 0.0
	var inc := freq * inv
	var att_inv := 1.0 / maxf(attack, 0.0005)
	var dec_k := exp(-decay * inv)
	var env_d := 1.0
	var release_n := int(0.01 * RATE)
	var vib := vib_hz > 0.0
	for k in n:
		env_d *= dec_k
		var t := float(k) * inv
		var env := minf(t * att_inv, 1.0) * env_d
		if n - k < release_n:
			env *= float(n - k) / float(release_n)
		if vib:
			inc = freq * (1.0 + vib_depth * sin(TAU * vib_hz * t) * minf(t * 4.0, 1.0)) * inv
		phase += inc
		var ph := phase - floorf(phase)
		var s := 0.0
		if wave == W_SINE:
			s = sin(TAU * ph)
		elif wave == W_SAW:
			s = ph * 2.0 - 1.0
		elif wave == W_SQUARE:
			s = 1.0 if ph < 0.5 else -1.0
		else:
			s = absf(ph * 4.0 - 2.0) - 1.0
		if drive > 0.0:
			s = tanh(s * drive) * 0.8
		_buf[(i0 + k) % size] += s * env * amp   # wraps so tails flow into the loop start


## Karplus-Strong plucked string (oud).
func _pluck(start: float, dur: float, freq: float, amp: float) -> void:
	var size := _buf.size()
	var delay := maxi(2, int(RATE / freq))
	var line := PackedFloat32Array()
	line.resize(delay)
	for i in delay:
		line[i] = _rng.randf() * 2.0 - 1.0
	var i0 := int(start * RATE)
	var n := int((dur + 0.25) * RATE)
	var pos := 0
	var fade_n := int(0.05 * RATE)
	for k in n:
		var nxt_pos := pos + 1
		if nxt_pos == delay:
			nxt_pos = 0
		var v := (line[pos] + line[nxt_pos]) * 0.4985
		line[pos] = v
		pos = nxt_pos
		var fade := minf(float(n - k) / float(fade_n), 1.0)
		_buf[(i0 + k) % size] += v * amp * fade


## Breathy reed flute (nay): sine + soft harmonics + vibrato + a little air noise.
func _nay(start: float, dur: float, freq: float, amp: float) -> void:
	var size := _buf.size()
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var phase := 0.0
	for k in n:
		var t := float(k) / RATE
		var env := minf(t / 0.06, 1.0) * minf((dur - t) / 0.08, 1.0) * (0.85 + 0.15 * sin(TAU * 4.5 * t))
		phase += freq * (1.0 + 0.007 * sin(TAU * 5.2 * t) * minf(t * 3.0, 1.0)) / RATE
		var s := sin(TAU * phase) + 0.25 * sin(TAU * phase * 2.0) + 0.08 * sin(TAU * phase * 3.0)
		s += (_rng.randf() * 2.0 - 1.0) * 0.07
		_buf[(i0 + k) % size] += s * env * amp


func _kick(start: float, amp: float) -> void:
	var size := _buf.size()
	var i0 := int(start * RATE)
	var n := int(0.28 * RATE)
	var phase := 0.0
	for k in n:
		var t := float(k) / RATE
		phase += (48.0 + 110.0 * exp(-t * 28.0)) / RATE
		_buf[(i0 + k) % size] += sin(TAU * phase) * exp(-t * 11.0) * amp


func _snare(start: float, amp: float) -> void:
	var size := _buf.size()
	var i0 := int(start * RATE)
	var n := int(0.22 * RATE)
	for k in n:
		var t := float(k) / RATE
		var noise := _rng.randf() * 2.0 - 1.0
		_buf[(i0 + k) % size] += (noise * exp(-t * 20.0) * 0.6 + sin(TAU * 190.0 * t) * exp(-t * 28.0) * 0.5) * amp


func _clap(start: float, amp: float) -> void:
	var size := _buf.size()
	for burst in 3:
		var i0 := int((start + burst * 0.011) * RATE)
		var n := int(0.07 * RATE)
		for k in n:
			var t := float(k) / RATE
			_buf[(i0 + k) % size] += (_rng.randf() * 2.0 - 1.0) * exp(-t * 55.0) * amp * 0.6


func _hat(start: float, amp: float, dur: float) -> void:
	var size := _buf.size()
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var last := 0.0
	var k_decay := 30.0 / maxf(dur, 0.02) * 0.35
	for k in n:
		var t := float(k) / RATE
		var noise := _rng.randf() * 2.0 - 1.0
		_buf[(i0 + k) % size] += (noise - last) * 0.5 * exp(-t * k_decay) * amp
		last = noise


## Darbuka "dum": deep resonant stroke at the centre of the skin.
func _dum(start: float, amp: float) -> void:
	var size := _buf.size()
	var i0 := int(start * RATE)
	var n := int(0.3 * RATE)
	var phase := 0.0
	for k in n:
		var t := float(k) / RATE
		phase += (92.0 + 60.0 * exp(-t * 30.0)) / RATE
		_buf[(i0 + k) % size] += sin(TAU * phase) * exp(-t * 12.0) * amp


## Darbuka "tek": bright rim stroke.
func _tek(start: float, amp: float) -> void:
	var size := _buf.size()
	var i0 := int(start * RATE)
	var n := int(0.09 * RATE)
	var last := 0.0
	for k in n:
		var t := float(k) / RATE
		var noise := _rng.randf() * 2.0 - 1.0
		var s := (noise - last) * 0.5 * exp(-t * 45.0) + sin(TAU * 1700.0 * t) * exp(-t * 60.0) * 0.4
		last = noise
		_buf[(i0 + k) % size] += s * amp
