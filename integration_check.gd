extends SceneTree

const EXPECTED_DOC_VERSION := "2.8"
const EXPECTED_PRODUCT_VERSION := "2.8.0"
const REQUIRED_TRACK_KEYS := [
	"curve",
	"length",
	"samples",
	"tangents",
	"track_id",
	"half_width",
	"shortcuts",
	"quality",
]
const REQUIRED_SHORTCUT_KEYS := [
	"samples",
	"tangents",
	"width",
]
const REQUIRED_TUNING_PROPERTIES := [
	"max_forward_speed",
	"nitro_max_speed",
	"launch_acceleration",
	"high_speed_acceleration",
	"brake_deceleration",
	"steering_input_attack",
	"low_speed_yaw_rate",
	"high_speed_yaw_rate",
	"normal_lateral_grip",
	"drift_lateral_grip",
	"offroad_speed_factor",
	"nitro_activation_cost",
	"collision_speed_retention",
	"base_fov",
	"max_skid_segments",
]
const REQUIRED_CAR_METADATA := [
	"camera",
	"all_wheels",
	"front_wheels",
	"brake_material",
	"brake_lights",
	"smoke_emitters",
	"boost_flames",
	"visual_layers",
]
const REQUIRED_BUDGET_KEYS := [
	"max_lights",
	"camera_far",
	"shadow_distance",
	"near_cover",
	"mid_cover",
]
const REQUIRED_UI_MEMBERS := [
	"race_audio",
	"top_left_panel",
	"top_center_panel",
	"top_right_panel",
	"speed_panel",
	"aux_panel",
	"nitro_gauge",
	"drift_gauge",
	"countdown_lights",
	"menu_start_prompt",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error("[INTEGRATION] %s" % message)


func _run() -> void:
	var packed_scene: PackedScene = load("res://main.tscn")
	_check(packed_scene != null, "main.tscn cannot be loaded")
	if packed_scene == null:
		_finish()
		return

	var main: Node = packed_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_check(main.get_script() != null, "main.gd failed to load")
	if main.get_script() == null:
		_finish()
		return
	var track_catalog: Variant = main.get("track_catalog")
	var tuning: Variant = main.get("driving_tuning")
	var showroom: Variant = main.get("showroom_root")
	_check(track_catalog is Array and track_catalog.size() == 3, "track catalog must contain exactly 3 tracks")
	_check(tuning != null, "DrivingTuning resource is missing")
	_check(showroom is Node3D, "showroom root is missing")
	if showroom is Node3D:
		_check(showroom.get_child_count() >= 20, "showroom root has too few nodes")
	if tuning == null or track_catalog == null:
		_finish()
		return

	for property_name in REQUIRED_TUNING_PROPERTIES:
		_check(
			tuning.get(property_name) != null,
			"DrivingTuning is missing property: %s" % property_name
		)
	_check(
		float(tuning.max_forward_speed) > float(tuning.reverse_max_speed),
		"forward speed must exceed reverse speed"
	)
	_check(
		float(tuning.nitro_max_speed) > float(tuning.max_forward_speed),
		"nitro speed must exceed normal maximum speed"
	)
	_check(main.get("hud_layer") != null, "HUD layer is missing")
	_check(main.get("minimap") != null, "minimap is missing")
	_check(main.get("start_overlay") != null, "start overlay is missing")
	_check(main.get("pause_overlay") != null, "pause overlay is missing")
	_check(main.get("finish_overlay") != null, "finish overlay is missing")
	for member_name in REQUIRED_UI_MEMBERS:
		_check(main.get(member_name) != null, "UI/audio contract member is missing: %s" % member_name)
	var race_audio: Variant = main.get("race_audio")
	if race_audio != null:
		for method_name in ["setup", "update", "debug_snapshot"]:
			_check(
				race_audio.has_method(method_name),
				"RaceAudioDirector is missing method: %s" % method_name
			)

	for track_index in 3:
		main.call("_load_track", track_index)
		await process_frame
		await process_frame
		var track_id := String(main.get("current_track_id"))
		var track_data: Variant = main.get("track_data")
		_check(
			track_id in ["neon", "snow", "loop"],
			"unexpected track id: %s" % track_id
		)
		_check(track_data is Dictionary, "track_data is not a Dictionary for %s" % track_id)
		if not track_data is Dictionary:
			continue
		for key in REQUIRED_TRACK_KEYS:
			_check(track_data.has(key), "track %s is missing key: %s" % [track_id, key])
		if not track_data.has("samples"):
			continue
		var samples: PackedVector3Array = track_data["samples"]
		var tangents: PackedVector3Array = track_data["tangents"]
		var shortcuts: Array = track_data["shortcuts"]
		_check(samples.size() > 100, "track %s has too few samples" % track_id)
		_check(
			samples.size() == tangents.size(),
			"track %s sample/tangent counts differ" % track_id
		)
		_check(float(track_data["length"]) > 100.0, "track %s is too short" % track_id)
		_check(float(track_data["half_width"]) > 5.0, "track %s half width is invalid" % track_id)
		_check(shortcuts.size() >= 1, "track %s must provide at least one shortcut" % track_id)
		for shortcut in shortcuts:
			_check(shortcut is Dictionary, "track %s shortcut is not a Dictionary" % track_id)
			for key in REQUIRED_SHORTCUT_KEYS:
				_check(shortcut.has(key), "track %s shortcut is missing key: %s" % [track_id, key])
		var budget: Dictionary = TrackFactory.get_quality_budget(track_id)
		for key in REQUIRED_BUDGET_KEYS:
			_check(budget.has(key), "track %s quality budget is missing key: %s" % [track_id, key])
		var quality: Dictionary = track_data["quality"]
		_check(int(quality.get("violations", 1)) == 0, "track %s has quality clearance violations" % track_id)
		_check(
			int(quality.get("shortcut_count", 0)) == shortcuts.size(),
			"track %s quality shortcut count differs from track data" % track_id
		)

		main.call("_prepare_race_grid")
		main.set("race_state", "racing")
		main.set("debug_drive_input", {
			"throttle": true,
			"brake": false,
			"steer_left": false,
			"steer_right": false,
			"drift": false,
			"nitro": false,
		})
		main.call("_update_player", 1.0 / 60.0)
		var player: Variant = main.get("player")
		_check(player != null, "player is missing for %s" % track_id)
		if player == null:
			continue
		for metadata_name in REQUIRED_CAR_METADATA:
			_check(
				player.has_meta(metadata_name),
				"player metadata is missing: %s" % metadata_name
			)
		if player.has_meta("all_wheels"):
			var wheels: Array = player.get_meta("all_wheels")
			_check(wheels.size() == 4, "player must expose exactly 4 wheels")
		if player.has_meta("front_wheels"):
			var front_wheels: Array = player.get_meta("front_wheels")
			_check(front_wheels.size() == 2, "player must expose exactly 2 front wheels")
		_check(
			is_finite(float(main.get("player_forward_speed"))),
			"player speed became non-finite for %s" % track_id
		)

	_check(
		FileAccess.get_file_as_string("res://export_presets.cfg").contains(
			"application/product_version=\"%s\"" % EXPECTED_PRODUCT_VERSION
		),
		"export preset product version is not %s" % EXPECTED_PRODUCT_VERSION
	)
	_check(
		FileAccess.get_file_as_string("res://README.md").contains(
			"# Q版氮气竞速 %s" % EXPECTED_DOC_VERSION
		),
		"README version is not %s" % EXPECTED_DOC_VERSION
	)
	_check(
		FileAccess.get_file_as_string("res://CODEX_HANDOFF.md").contains(
			"当前文档版本：%s" % EXPECTED_DOC_VERSION
		),
		"handoff version is not %s" % EXPECTED_DOC_VERSION
	)
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("[INTEGRATION] PASS version=%s parts=5 tracks=3" % EXPECTED_DOC_VERSION)
		quit(0)
		return
	print("[INTEGRATION] FAIL count=%d" % failures.size())
	for failure in failures:
		print(" - %s" % failure)
	quit(1)
