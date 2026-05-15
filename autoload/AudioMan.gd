extends Node

# Procedural SFX. Every byte is synthesized in pure GDScript on _ready,
# baked into AudioStreamWAV buffers, and played through a small pool of
# AudioStreamPlayers. No external audio files.
#
# Tag mapping (use AudioMan.play(&"<tag>")):
#   click, fire_bullet, fire_shell, fire_laser, fire_drop,
#   hit, death, wave_start, boss_roar, victory, defeat, achievement

const MIX_RATE: int = 22050
const POOL_SIZE: int = 12

var muted: bool = false
var music_muted: bool = false
var master_volume_db: float = -4.0
var music_volume_db: float = -16.0

var _streams: Dictionary = {}        ## StringName -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _music_player: AudioStreamPlayer = null
var _music_stream: AudioStreamWAV = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)
	_build_bank()
	_music_stream = _bake(_march_loop_pcm())
	_music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_stream.loop_end = _music_stream.data.size() / 2  ## sample count
	_music_player.stream = _music_stream
	_music_player.volume_db = music_volume_db
	start_music()

func _build_bank() -> void:
	_streams[&"click"]        = _bake(_click_pcm())
	_streams[&"fire_bullet"]  = _bake(_bullet_pcm())
	_streams[&"fire_shell"]   = _bake(_shell_pcm())
	_streams[&"fire_laser"]   = _bake(_laser_pcm())
	_streams[&"fire_drop"]    = _bake(_drop_pcm())
	_streams[&"hit"]          = _bake(_hit_pcm())
	_streams[&"death"]        = _bake(_death_pcm())
	_streams[&"wave_start"]   = _bake(_wave_start_pcm())
	_streams[&"boss_roar"]    = _bake(_boss_roar_pcm())
	_streams[&"victory"]      = _bake(_victory_pcm())
	_streams[&"defeat"]       = _bake(_defeat_pcm())
	_streams[&"achievement"]  = _bake(_ach_pcm())

func play(tag: StringName, volume_offset_db: float = 0.0) -> void:
	if muted:
		return
	var stream: AudioStreamWAV = _streams.get(tag)
	if stream == null:
		return
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.volume_db = master_volume_db + volume_offset_db
	p.play()

func set_muted(b: bool) -> void:
	muted = b
	music_muted = b
	if b:
		_music_player.stop()
	else:
		start_music()

func set_master_volume_db(db: float) -> void:
	master_volume_db = db

func set_music_volume_db(db: float) -> void:
	music_volume_db = db
	if _music_player:
		_music_player.volume_db = db

func start_music() -> void:
	if music_muted or _music_player == null or _music_stream == null:
		return
	if not _music_player.playing:
		var target_db: float = music_volume_db
		_music_player.volume_db = -60.0
		_music_player.play()
		var t := create_tween()
		t.tween_property(_music_player, "volume_db", target_db, 1.2)

func stop_music() -> void:
	if _music_player:
		_music_player.stop()

# ---------- Synthesis ----------

func _bake(pcm: PackedFloat32Array) -> AudioStreamWAV:
	# Convert -1..1 float samples to int16 PCM (little-endian).
	var bytes := PackedByteArray()
	bytes.resize(pcm.size() * 2)
	for i in pcm.size():
		var s: float = clamp(pcm[i], -1.0, 1.0)
		var v: int = int(s * 32767.0)
		if v < 0:
			v += 65536
		bytes[i * 2] = v & 0xff
		bytes[i * 2 + 1] = (v >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	return wav

func _make_buffer(duration: float) -> PackedFloat32Array:
	var n: int = int(duration * MIX_RATE)
	var arr := PackedFloat32Array()
	arr.resize(n)
	return arr

func _click_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.05)
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		arr[i] = sin(t * TAU * 1800.0) * exp(-t * 80.0) * 0.6
	return arr

func _bullet_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.09)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var freq: float = 1600.0 - t * 8000.0
		var tone: float = sin(t * TAU * max(120.0, freq))
		var noise: float = rng.randf_range(-1.0, 1.0)
		var env: float = exp(-t * 35.0)
		arr[i] = (tone * 0.55 + noise * 0.45) * env
	return arr

func _shell_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.32)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23456
	var last: float = 0.0
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var noise: float = rng.randf_range(-1.0, 1.0)
		last = last * 0.92 + noise * 0.08  ## 1-pole low-pass
		var thump: float = sin(t * TAU * 70.0) * exp(-t * 4.0)
		var env: float = exp(-t * 6.5)
		arr[i] = (last * 0.7 + thump * 0.6) * env
	return arr

func _laser_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.17)
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var freq: float = 2400.0 - t * 5000.0
		arr[i] = sin(t * TAU * max(80.0, freq)) * exp(-t * 16.0) * 0.55
	return arr

func _drop_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.42)
	var rng := RandomNumberGenerator.new()
	rng.seed = 34567
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		if t < 0.25:
			var freq: float = 1400.0 - (t / 0.25) * 1100.0
			arr[i] = sin(t * TAU * freq) * 0.4 * (1.0 - t / 0.25)
		else:
			var u: float = t - 0.25
			var noise: float = rng.randf_range(-1.0, 1.0)
			var thump: float = sin(u * TAU * 55.0) * exp(-u * 8.0)
			arr[i] = (noise * 0.6 + thump * 0.7) * exp(-u * 7.0)
	return arr

func _hit_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.07)
	var rng := RandomNumberGenerator.new()
	rng.seed = 45678
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		arr[i] = rng.randf_range(-1.0, 1.0) * exp(-t * 80.0) * 0.6
	return arr

func _death_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.22)
	var rng := RandomNumberGenerator.new()
	rng.seed = 56789
	var last: float = 0.0
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var noise: float = rng.randf_range(-1.0, 1.0)
		last = last * 0.85 + noise * 0.15
		arr[i] = last * exp(-t * 8.0) * 0.7
	return arr

func _wave_start_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.55)
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var freq: float = 440.0 if t <= 0.2 else 660.0
		var env: float = 0.5
		if t > 0.45:
			env = exp(-(t - 0.45) * 6.0) * 0.5
		arr[i] = (sin(t * TAU * freq) * 0.6 + sin(t * TAU * freq * 2.0) * 0.2) * env
	return arr

func _boss_roar_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.95)
	var rng := RandomNumberGenerator.new()
	rng.seed = 67890
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var freq: float = 90.0 + sin(t * 4.0) * 14.0
		var growl: float = sin(t * TAU * freq) * 0.6
		var noise: float = rng.randf_range(-1.0, 1.0) * 0.25
		var env: float = 1.0
		if t < 0.08:
			env = t / 0.08
		elif t > 0.75:
			env = max(0.0, 1.0 - (t - 0.75) / 0.20)
		arr[i] = (growl + noise) * env * 0.8
	return arr

func _victory_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(1.35)
	var notes: Array = [440.0, 554.37, 659.25, 880.0]
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var phase: int = int(t / 0.18)
		if phase >= notes.size():
			phase = notes.size() - 1
		var f: float = float(notes[phase])
		var local_t: float = t - phase * 0.18
		var env: float = exp(-local_t * 3.0)
		arr[i] = (sin(t * TAU * f) * 0.6 + sin(t * TAU * f * 2.0) * 0.15) * env
	return arr

func _defeat_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(1.15)
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var f: float = 220.0 if t <= 0.4 else 165.0
		var local_t: float = t if t <= 0.4 else (t - 0.4)
		var env: float = exp(-local_t * 3.0)
		arr[i] = sin(t * TAU * f) * env * 0.55
	return arr

func _ach_pcm() -> PackedFloat32Array:
	var arr := _make_buffer(0.45)
	var notes: Array = [659.25, 783.99, 987.77]
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var phase: int = int(t / 0.12)
		if phase >= notes.size():
			phase = notes.size() - 1
		var f: float = float(notes[phase])
		var local_t: float = t - phase * 0.12
		arr[i] = sin(t * TAU * f) * exp(-local_t * 9.0) * 0.5
	return arr

func _march_loop_pcm() -> PackedFloat32Array:
	# 8-second wartime march loop at ~60 BPM (1 beat = 1.0 s, 8 beats).
	# Layers: low bass note per beat (Am-Dm-F-E walk), snare on beats 1 & 3
	# of each 4-beat measure, and a soft sustained low pad.
	const BPM: float = 60.0
	const BEATS: int = 8
	var beat_sec: float = 60.0 / BPM
	var total_sec: float = beat_sec * BEATS
	var arr := _make_buffer(total_sec)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	# Bass note progression (Hz): A2 A2 D2 D2 F2 F2 E2 E2 — i i iv iv VI VI V V
	var bass_notes: Array = [110.0, 110.0, 73.42, 73.42, 87.31, 87.31, 82.41, 82.41]
	# Pad chord: drone on A2 + E3 fifth, very low volume.
	var pad_freqs: Array = [110.0, 164.81]
	for i in arr.size():
		var t: float = float(i) / MIX_RATE
		var beat: int = int(t / beat_sec) % BEATS
		var local_t: float = t - beat * beat_sec
		# Bass
		var bf: float = float(bass_notes[beat])
		var bass_env: float = exp(-local_t * 2.0)
		var bass: float = sin(t * TAU * bf) * bass_env * 0.45
		# Sub-octave for body
		bass += sin(t * TAU * bf * 0.5) * bass_env * 0.15
		# Pad (always on, slow vibrato)
		var pad: float = 0.0
		for f in pad_freqs:
			pad += sin(t * TAU * float(f) * (1.0 + 0.003 * sin(t * 3.0))) * 0.06
		# Snare on beats 0 and 2 of each measure (so 0,2,4,6 within the 8 beats)
		var snare: float = 0.0
		if beat % 2 == 0 and local_t < 0.10:
			var sn_t: float = local_t
			snare = rng.randf_range(-1.0, 1.0) * exp(-sn_t * 50.0) * 0.35
		# Hi-hat tick on every offbeat half-beat
		var hat: float = 0.0
		var hat_phase: float = fmod(t, beat_sec * 0.5)
		if hat_phase < 0.04:
			hat = rng.randf_range(-1.0, 1.0) * exp(-hat_phase * 120.0) * 0.07
		# Tail-off fade near loop end to avoid click on wrap
		var loop_fade: float = 1.0
		var tail: float = total_sec - t
		if tail < 0.05:
			loop_fade = tail / 0.05
		arr[i] = (bass + pad + snare + hat) * loop_fade * 0.95
	return arr
