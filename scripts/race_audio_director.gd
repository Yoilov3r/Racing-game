class_name RaceAudioDirector
extends Node

const SAMPLE_RATE := 22050
const SILENT_DB := -60.0
const ENGINE_LAYERS := ["engine_low", "engine_mid", "engine_high"]
const RACE_LAYERS := [
	"engine_low",
	"engine_mid",
	"engine_high",
	"tire_friction",
	"drift",
	"nitro",
	"ambient",
]

var players: Dictionary = {}
var gains: Dictionary = {}
var targets: Dictionary = {}
var one_shot_players: Array[AudioStreamPlayer] = []
var ui_stream: AudioStreamWAV
var countdown_streams: Array[AudioStreamWAV] = []
var impact_streams: Array[AudioStream] = []
var last_countdown_step := -1
var transition_count := 0
var audio_events_played := 0
var audio_clip_detected := false
var abrupt_stop_count := 0
var race_was_active := false


func setup(host: Node) -> void:
	name = "RaceAudioDirector"
	host.add_child(self)
	_ensure_bus("RaceEngine", -7.0)
	_ensure_bus("RaceTires", -8.5)
	_ensure_bus("RaceFx", -7.0)
	_ensure_bus("RaceAmbience", -14.0)
	_ensure_bus("RaceUI", -5.0)

	var engine_stream := _make_looping_engine_stream()
	_add_looping_layer("engine_low", engine_stream, "RaceEngine", -4.0)
	_add_looping_layer("engine_mid", engine_stream, "RaceEngine", -8.0)
	_add_looping_layer("engine_high", engine_stream, "RaceEngine", -13.0)
	_add_looping_layer(
		"tire_friction",
		_make_noise_loop("tire", 1.35),
		"RaceTires",
		-7.0
	)
	_add_looping_layer("drift", _make_noise_loop("drift", 1.05), "RaceTires", -6.0)
	_add_looping_layer("nitro", _make_noise_loop("nitro", 0.82), "RaceFx", -7.0)
	_add_looping_layer(
		"ambient",
		load("res://assets/audio/ambient_night.ogg"),
		"RaceAmbience",
		-15.0
	)

	for index in 5:
		var one_shot := AudioStreamPlayer.new()
		one_shot.name = "OneShot%d" % index
		one_shot.bus = "RaceUI"
		one_shot.volume_db = SILENT_DB
		add_child(one_shot)
		one_shot_players.append(one_shot)
	ui_stream = _make_click_stream()
	countdown_streams = [
		_make_tone_stream(880.0, 0.14, 0.16, 0.10),
		_make_tone_stream(1174.66, 0.14, 0.16, 0.08),
		_make_tone_stream(1567.98, 0.18, 0.22, 0.10),
	]
	for path in [
		"res://assets/audio/impact_1.wav",
		"res://assets/audio/impact_2.wav",
		"res://assets/audio/impact_3.wav",
	]:
		impact_streams.append(load(path))
	_reset_gains()


func set_track(track_id: String) -> void:
	var ambient_player: AudioStreamPlayer = players.get("ambient")
	if not ambient_player:
		return
	var path := "res://assets/audio/ambient_night.ogg"
	ambient_player.pitch_scale = 1.0
	if track_id == "snow":
		path = "res://assets/audio/ambient_day.ogg"
		ambient_player.pitch_scale = 0.82
	elif track_id == "loop":
		path = "res://assets/audio/ambient_day.ogg"
		ambient_player.pitch_scale = 0.94
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	ambient_player.stream = stream
	if ambient_player.playing:
		ambient_player.stop()
	gains["ambient"] = 0.0
	targets["ambient"] = 0.0
	ambient_player.volume_db = SILENT_DB


func set_race_active(active: bool) -> void:
	if race_was_active != active:
		race_was_active = active
		transition_count += 1
	if active:
		for layer_name in RACE_LAYERS:
			_ensure_layer_started(layer_name)
	else:
		for layer_name in RACE_LAYERS:
			targets[layer_name] = 0.0


func update(
		delta: float,
		race_state: String,
		speed_ratio: float,
		drift_ratio: float,
		slip_ratio: float,
		boost_ratio: float,
		offroad: bool,
		throttle: float
	) -> void:
	var racing := race_state == "racing"
	var countdown := race_state == "countdown"
	var active := racing or countdown
	set_race_active(active)
	if active:
		var engine_load := clampf(speed_ratio * 0.78 + absf(throttle) * 0.22, 0.0, 1.0)
		var idle := 0.28 if countdown else 0.0
		targets["engine_low"] = clampf(0.34 + engine_load * 0.52 + idle, 0.0, 1.0)
		targets["engine_mid"] = clampf(0.16 + engine_load * 0.58 + idle * 0.55, 0.0, 1.0)
		targets["engine_high"] = clampf(
			0.05 + speed_ratio * 0.45 + boost_ratio * 0.34 + idle * 0.25,
			0.0,
			1.0
		)
		var surface_slip := maxf(slip_ratio, drift_ratio * 0.62)
		targets["tire_friction"] = 0.0 if countdown else clampf(
			speed_ratio * 0.28 + surface_slip * 0.56 + (0.14 if offroad else 0.0),
			0.0,
			0.88
		)
		targets["drift"] = 0.0 if countdown else clampf(
			drift_ratio * 0.82 + slip_ratio * 0.25,
			0.0,
			0.92
		)
		targets["nitro"] = 0.0 if countdown else clampf(boost_ratio * 0.92, 0.0, 0.92)
		targets["ambient"] = 0.16 if racing else 0.06
	else:
		for layer_name in RACE_LAYERS:
			targets[layer_name] = 0.0

	var release_rate := 6.0
	var attack_rate := 2.8
	var active_players := []
	for layer_name in RACE_LAYERS:
		var target := float(targets.get(layer_name, 0.0))
		var rate := release_rate if target < float(gains.get(layer_name, 0.0)) else attack_rate
		if layer_name == "nitro":
			rate = 7.0
		elif layer_name == "drift":
			rate = 5.2
		elif layer_name == "tire_friction":
			rate = 4.0
		var previous_gain := float(gains.get(layer_name, 0.0))
		var next_gain := lerpf(
			previous_gain,
			target,
			1.0 - exp(-rate * delta)
		)
		gains[layer_name] = next_gain
		_apply_layer_gain(layer_name, next_gain)
		if next_gain > 0.003 and target > 0.0:
			active_players.append(layer_name)

	var low_player: AudioStreamPlayer = players["engine_low"]
	var mid_player: AudioStreamPlayer = players["engine_mid"]
	var high_player: AudioStreamPlayer = players["engine_high"]
	low_player.pitch_scale = lerpf(low_player.pitch_scale, 0.52 + speed_ratio * 0.58 + boost_ratio * 0.05, 0.09)
	mid_player.pitch_scale = lerpf(mid_player.pitch_scale, 0.82 + speed_ratio * 1.02 + boost_ratio * 0.13, 0.08)
	high_player.pitch_scale = lerpf(high_player.pitch_scale, 1.28 + speed_ratio * 1.72 + boost_ratio * 0.24, 0.07)
	var tire_player: AudioStreamPlayer = players["tire_friction"]
	tire_player.pitch_scale = lerpf(tire_player.pitch_scale, 0.74 + speed_ratio * 0.62, 0.06)
	var drift_player: AudioStreamPlayer = players["drift"]
	drift_player.pitch_scale = lerpf(drift_player.pitch_scale, 0.72 + drift_ratio * 0.52, 0.08)
	var nitro_player: AudioStreamPlayer = players["nitro"]
	nitro_player.pitch_scale = lerpf(nitro_player.pitch_scale, 0.94 + boost_ratio * 0.24, 0.10)


func play_ui(kind: String = "move") -> void:
	var pitch := 1.0
	if kind == "confirm":
		pitch = 1.16
	elif kind == "cancel":
		pitch = 0.78
	_play_one_shot(ui_stream, -10.0, pitch, "RaceUI")
	audio_events_played += 1


func play_countdown(step: int) -> void:
	if step == last_countdown_step:
		return
	last_countdown_step = step
	if step > 0:
		var stream_index := clampi(step - 1, 0, countdown_streams.size() - 1)
		_play_one_shot(countdown_streams[stream_index], -6.0, 1.0, "RaceUI")
	else:
		_play_one_shot(countdown_streams[2], -4.0, 1.16, "RaceUI")
		_play_one_shot(countdown_streams[0], -7.0, 0.92, "RaceUI")
	audio_events_played += 1


func play_impact(intensity: float = 1.0) -> void:
	if impact_streams.is_empty():
		return
	var clamped := clampf(intensity, 0.0, 1.0)
	var stream := impact_streams[randi() % impact_streams.size()]
	_play_one_shot(stream, lerpf(-17.0, -5.0, clamped), randf_range(0.88, 1.12), "RaceFx")
	audio_events_played += 1


func reset_events() -> void:
	last_countdown_step = -1


func debug_snapshot() -> Dictionary:
	var audible := []
	for layer_name in RACE_LAYERS:
		if float(gains.get(layer_name, 0.0)) > 0.004:
			audible.append(layer_name)
	return {
		"audible_layers": audible,
		"gain": gains.duplicate(true),
		"target": targets.duplicate(true),
		"transition_count": transition_count,
		"events_played": audio_events_played,
		"clip_detected": audio_clip_detected,
		"abrupt_stop_count": abrupt_stop_count,
	}


func _add_looping_layer(
		layer_name: String,
		stream: AudioStream,
		bus_name: String,
		base_volume_db: float
	) -> void:
	var player := AudioStreamPlayer.new()
	player.name = layer_name
	player.stream = stream
	player.bus = bus_name
	player.volume_db = SILENT_DB
	player.set_meta("base_volume_db", base_volume_db)
	add_child(player)
	players[layer_name] = player
	gains[layer_name] = 0.0
	targets[layer_name] = 0.0


func _ensure_layer_started(layer_name: String) -> void:
	var player: AudioStreamPlayer = players.get(layer_name)
	if not player:
		return
	if not player.playing and player.stream:
		player.volume_db = SILENT_DB
		player.play()


func _apply_layer_gain(layer_name: String, gain: float) -> void:
	var player: AudioStreamPlayer = players.get(layer_name)
	if not player:
		return
	if gain <= 0.0025 and float(targets.get(layer_name, 0.0)) <= 0.0:
		if player.playing:
			if float(gains.get(layer_name, 0.0)) > 0.02:
				abrupt_stop_count += 1
			player.stop()
		player.volume_db = SILENT_DB
		return
	if not player.playing and player.stream:
		player.play()
	var base_db := float(player.get_meta("base_volume_db", 0.0))
	player.volume_db = base_db + linear_to_db(maxf(gain, 0.001))


func _play_one_shot(
		stream: AudioStream,
		volume_db: float,
		pitch: float,
		bus_name: String
	) -> void:
	if not stream:
		return
	for player in one_shot_players:
		if player.playing:
			continue
		player.stop()
		player.stream = stream
		player.bus = bus_name
		player.volume_db = volume_db
		player.pitch_scale = pitch
		player.play()
		return
	var fallback := one_shot_players[0]
	fallback.stop()
	fallback.stream = stream
	fallback.bus = bus_name
	fallback.volume_db = volume_db
	fallback.pitch_scale = pitch
	fallback.play()


func _reset_gains() -> void:
	for layer_name in RACE_LAYERS:
		gains[layer_name] = 0.0
		targets[layer_name] = 0.0
		var player: AudioStreamPlayer = players.get(layer_name)
		if player:
			player.volume_db = SILENT_DB
			if player.playing:
				player.stop()


func _ensure_bus(bus_name: String, volume_db: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		bus_index = AudioServer.bus_count
		AudioServer.add_bus(bus_index)
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, "Master")
	AudioServer.set_bus_volume_db(bus_index, volume_db)


func _make_looping_engine_stream() -> AudioStreamWAV:
	var stream: AudioStreamWAV = load("res://assets/audio/engine.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	var bytes_per_frame := 4 if stream.stereo else 2
	stream.loop_end = maxi(1, stream.data.size() / bytes_per_frame - 1)
	return stream


func _make_noise_loop(kind: String, duration: float) -> AudioStreamWAV:
	var frame_count := int(duration * float(SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 47001 if kind == "tire" else (47002 if kind == "drift" else 47003)
	var filtered := 0.0
	var slow_filtered := 0.0
	for frame_index in frame_count:
		var time := float(frame_index) / float(SAMPLE_RATE)
		var white := rng.randf_range(-1.0, 1.0)
		filtered = lerpf(filtered, white, 0.18)
		slow_filtered = lerpf(slow_filtered, white, 0.025)
		var sample := 0.0
		if kind == "tire":
			sample = filtered * 0.32 + slow_filtered * 0.22
		elif kind == "drift":
			sample = (
				filtered * 0.38
				+ sin(TAU * 58.0 * time) * 0.10
				+ sin(TAU * 116.0 * time) * 0.05
			)
		else:
			var modulation := 0.72 + sin(TAU * 5.0 * time) * 0.18
			sample = white * 0.34 * modulation + sin(TAU * 172.0 * time) * 0.12
			sample += sin(TAU * 344.0 * time) * 0.08
		if absf(sample) > 0.98:
			audio_clip_detected = true
		sample = clampf(sample, -0.98, 0.98)
		data.encode_s16(frame_index * 2, int(round(sample * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count - 1
	return stream


func _make_tone_stream(
		frequency: float,
		duration: float,
		volume: float,
		overtone: float
	) -> AudioStreamWAV:
	var frame_count := int(duration * float(SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for frame_index in frame_count:
		var time := float(frame_index) / float(SAMPLE_RATE)
		var normalized := time / duration
		var attack := minf(1.0, normalized / 0.045)
		var envelope := attack * pow(maxf(1.0 - normalized, 0.0), 2.2)
		var sample := (
			sin(TAU * frequency * time) * volume
			+ sin(TAU * frequency * 2.0 * time) * overtone
		) * envelope
		data.encode_s16(frame_index * 2, int(round(clampf(sample, -0.98, 0.98) * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _make_click_stream() -> AudioStreamWAV:
	var frame_count := int(0.045 * float(SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1967
	for frame_index in frame_count:
		var normalized := float(frame_index) / float(frame_count)
		var envelope := pow(1.0 - normalized, 4.0)
		var sample := (
			sin(TAU * 1450.0 * float(frame_index) / float(SAMPLE_RATE))
			+ rng.randf_range(-0.34, 0.34)
		) * envelope * 0.22
		data.encode_s16(frame_index * 2, int(round(clampf(sample, -0.98, 0.98) * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
