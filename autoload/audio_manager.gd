extends Node
## Plays sound effects (jsfxr WAVs) and music (Suno tracks) by name.
## Missing files never crash: they log one warning and stay silent.
##   AudioManager.play_sfx("lock_open")
##   AudioManager.play_music("level_lounge")

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const AUDIO_EXTENSIONS: PackedStringArray = ["ogg", "mp3", "wav"]
const BUSES: PackedStringArray = ["Music", "SFX", "Ambience"]
const SFX_POOL_SIZE := 10
const CROSSFADE_SECONDS := 1.5

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _stream_cache: Dictionary = {}
var _warned: Dictionary = {}

var _music_players: Array[AudioStreamPlayer] = []
var _music_active := 0
var _music_track := ""
var _music_fading := false
var _ambience_player: AudioStreamPlayer
var _ambience_track := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -80.0
		add_child(m)
		_music_players.append(m)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Ambience"
	add_child(_ambience_player)
	_ambience_player.finished.connect(func() -> void:
		if _ambience_track != "":
			_ambience_player.play())
	apply_volumes()
	Events.settings_changed.connect(apply_volumes)


func _process(_delta: float) -> void:
	# Crossfade a music track's end into its own start, so Suno tracks don't need perfect loop points.
	if _music_track == "" or _music_fading:
		return
	var p := _music_players[_music_active]
	if not p.playing or p.stream == null:
		return
	var length := p.stream.get_length()
	if length > CROSSFADE_SECONDS * 3.0 and p.get_playback_position() >= length - CROSSFADE_SECONDS:
		_crossfade_to(p.stream)


## Plays a sound effect from assets/audio/sfx/<name>.wav.
func play_sfx(sfx_name: String, pitch_variation: float = 0.0, volume_db: float = 0.0) -> void:
	var stream := _load_stream(SFX_DIR, sfx_name)
	if stream == null:
		return
	var p := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + (randf_range(-pitch_variation, pitch_variation) if pitch_variation > 0.0 else 0.0)
	p.play()


## Starts (or keeps) a music track from assets/audio/music/<track>.(ogg|mp3|wav), crossfading from the current one.
func play_music(track: String) -> void:
	if track == _music_track:
		return
	_music_track = track
	var stream := _load_stream(MUSIC_DIR, track, true)
	if stream == null:
		stop_music()
		_music_track = track
		return
	_disable_native_loop(stream)
	_crossfade_to(stream)


func stop_music() -> void:
	_music_track = ""
	for p in _music_players:
		if p.playing:
			var tween := create_tween()
			tween.tween_property(p, "volume_db", -80.0, CROSSFADE_SECONDS)
			tween.tween_callback(p.stop)


func current_music() -> String:
	return _music_track


## Loops an ambience layer (e.g. "ambience_ocean") if the file exists.
func play_ambience(track: String) -> void:
	if track == _ambience_track:
		return
	_ambience_track = track
	var stream := _load_stream(MUSIC_DIR, track, true)
	if stream == null:
		_ambience_player.stop()
		return
	_ambience_player.stream = stream
	_ambience_player.play()


## Returns true if a sound or track file exists (used by tests and the settings screen).
func has_sfx(sfx_name: String) -> bool:
	return ResourceLoader.exists(SFX_DIR + sfx_name + ".wav")


func apply_volumes() -> void:
	var s := SaveManager.settings
	_set_bus_linear("Master", float(s.get("volume_master", 0.9)))
	_set_bus_linear("Music", float(s.get("volume_music", 0.55)))
	_set_bus_linear("SFX", float(s.get("volume_sfx", 0.8)))
	_set_bus_linear("Ambience", float(s.get("volume_ambience", 0.6)))


func _crossfade_to(stream: AudioStream) -> void:
	_music_fading = true
	var old := _music_players[_music_active]
	_music_active = 1 - _music_active
	var new := _music_players[_music_active]
	new.stream = stream
	new.volume_db = -40.0
	new.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(new, "volume_db", 0.0, CROSSFADE_SECONDS).set_trans(Tween.TRANS_SINE)
	if old.playing:
		tween.tween_property(old, "volume_db", -80.0, CROSSFADE_SECONDS).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(func() -> void:
		if old != _music_players[_music_active]:
			old.stop()
		_music_fading = false)


func _disable_native_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = false
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false


func _load_stream(dir: String, stream_name: String, any_extension: bool = false) -> AudioStream:
	var key := dir + stream_name
	if _stream_cache.has(key):
		return _stream_cache[key]
	var extensions: PackedStringArray = AUDIO_EXTENSIONS if any_extension else PackedStringArray(["wav"])
	for ext in extensions:
		var path := "%s%s.%s" % [dir, stream_name, ext]
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			_stream_cache[key] = stream
			return stream
	if not _warned.has(key):
		_warned[key] = true
		if dir == SFX_DIR:
			push_warning("Missing sound effect '%s' (add it to tools/sfx/sfx.json and run npm run sfx)" % stream_name)
		else:
			print("AudioManager: no music file for '%s' yet (see docs/SUNO_PROMPTS.md)" % stream_name)
	_stream_cache[key] = null
	return null


func _ensure_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _set_bus_linear(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	value = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, value <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.001)))
