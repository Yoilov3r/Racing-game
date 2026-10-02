extends SceneTree

const TEST_SIZES := [
	Vector2i(1280, 800),
	Vector2i(1920, 1080),
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var report_lines := PackedStringArray([
		"AUDIO routing=RaceEngine,RaceTires,RaceFx,RaceAmbience,RaceUI",
		"AUDIO transitions=exponential fade stop_threshold=-52.0dB clipping_check=sample_peak",
	])
	for target_size in TEST_SIZES:
		await _capture_matrix(target_size, report_lines)
	var report_path := "res://qa/audio_test.txt"
	_write_text(report_path, "\n".join(report_lines) + "\n")
	print("RACE_UI_AUDIT_COMPLETE report=%s" % report_path)
	quit()


func _capture_matrix(target_size: Vector2i, report_lines: PackedStringArray) -> void:
	root.size = target_size
	root.content_scale_size = target_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	await process_frame

	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	for frame in 12:
		await process_frame
	await process_frame
	var size_label := "%dx%d" % [target_size.x, target_size.y]
	_save_viewport(main, "res://qa/after_%s_menu.png" % size_label)
	var menu_bounds := _validate_bounds(main, size_label, "menu")
	report_lines.append("[%s] menu_bounds=%s" % [size_label, menu_bounds])

	var menu_audio := _run_audio_state(main, "waiting", 0.0, 0.0, 0.0, 0.0, false)
	report_lines.append("[%s] audio_menu=%s" % [size_label, _dict_text(menu_audio)])

	main.start_overlay.visible = false
	main.showroom_root.visible = false
	main._prepare_race_grid()
	main.race_state = "countdown"
	main.countdown_time = 1.6
	main.last_countdown_value = 2
	main.center_message.text = "2"
	main.center_message.modulate.a = 1.0
	main._update_engine_audio(0.25)
	for frame in 4:
		await process_frame
	await process_frame
	_save_viewport(main, "res://qa/after_%s_countdown.png" % size_label)
	report_lines.append(
		"[%s] countdown_bounds=%s" % [
			size_label,
			_validate_bounds(main, size_label, "countdown"),
		]
	)

	main.set_physics_process(false)
	main.race_state = "racing"
	main.race_time = 22.456
	main.race_elapsed_time = 22.456
	main.player_lap = 1
	main.player_place = 2
	main.player_forward_speed = 41.5
	main.player_lateral_speed = 5.8
	main.player_slip_angle = 0.48
	main.player_drift_angle = 0.42
	main.player_drift_blend = 0.92
	main.player_drifting = true
	main.player_drift_charge = 78.0
	main.player_nitro_time = 1.25
	main.nitro_requested = true
	main.player_velocity = -main.player.global_transform.basis.z * main.player_forward_speed
	main.speed_particles.emitting = true
	main.speed_overlay.visible = true
	main.speed_overlay_material.set_shader_parameter("intensity", 0.20)
	main.nitro_overlay.visible = true
	main.nitro_overlay_material.set_shader_parameter("intensity", 0.28)
	for frame in 5:
		await process_frame
	await process_frame
	_save_viewport(main, "res://qa/after_%s_race.png" % size_label)
	report_lines.append(
		"[%s] race_bounds=%s" % [
			size_label,
			_validate_bounds(main, size_label, "race"),
		]
	)
	var racing_audio := _run_audio_state(main, "racing", 0.85, 0.72, 0.66, 0.74, true)
	report_lines.append("[%s] audio_race=%s" % [size_label, _dict_text(racing_audio)])

	main.race_state = "paused"
	main.pause_overlay.visible = true
	main._update_pause_summary()
	await process_frame
	await process_frame
	_save_viewport(main, "res://qa/after_%s_pause.png" % size_label)
	report_lines.append(
		"[%s] pause_bounds=%s" % [
			size_label,
			_validate_bounds(main, size_label, "pause"),
		]
	)

	main.race_state = "finished"
	main.player_finished = true
	main.player_finish_time = main.race_time
	main._finish_race()
	await process_frame
	await process_frame
	_save_viewport(main, "res://qa/after_%s_finish.png" % size_label)
	report_lines.append(
		"[%s] finish_bounds=%s" % [
			size_label,
			_validate_bounds(main, size_label, "finish"),
		]
	)
	var quiet_audio := _run_audio_state(main, "waiting", 0.0, 0.0, 0.0, 0.0, false)
	report_lines.append("[%s] audio_after_exit=%s" % [size_label, _dict_text(quiet_audio)])

	main.queue_free()
	await process_frame


func _run_audio_state(
		main: Node,
		state: String,
		speed_ratio: float,
		drift_ratio: float,
		slip_ratio: float,
		boost_ratio: float,
		offroad: bool
	) -> Dictionary:
	for step in 4:
		main.race_audio.update(
			0.35,
			state,
			speed_ratio,
			drift_ratio,
			slip_ratio,
			boost_ratio,
			offroad,
			1.0 if state == "racing" else 0.0
		)
	main.race_audio.play_ui("confirm")
	main.race_audio.play_countdown(2)
	main.race_audio.play_impact(0.72)
	return main.race_audio.debug_snapshot()


func _validate_bounds(main: Node, size_label: String, state: String) -> String:
	var viewport_rect := Rect2(Vector2.ZERO, main.get_viewport().get_visible_rect().size)
	var checks: Array[Control] = []
	if state == "menu":
		checks = [
			main.start_overlay.get_child(0),
			main.track_option_labels[0],
			main.track_option_labels[1],
			main.track_option_labels[2],
			main.menu_start_prompt,
		]
	elif state == "countdown":
		checks = [
			main.countdown_lights,
			main.center_message,
			main.top_center_panel,
			main.top_right_panel,
		]
	elif state == "race":
		checks = [
			main.top_left_panel,
			main.top_center_panel,
			main.top_right_panel,
			main.speed_panel,
			main.aux_panel,
			main.minimap,
			main.nitro_gauge,
			main.drift_gauge,
		]
	else:
		var overlay: Control = main.pause_overlay if state == "pause" else main.finish_overlay
		checks = [overlay.get_node("ResultPanel")]
	var overflow_count := 0
	for control in checks:
		if not control:
			continue
		var rect := control.get_global_rect()
		if (
			rect.position.x < viewport_rect.position.x - 0.5
			or rect.position.y < viewport_rect.position.y - 0.5
			or rect.end.x > viewport_rect.end.x + 0.5
			or rect.end.y > viewport_rect.end.y + 0.5
		):
			overflow_count += 1
	var race_overlap := false
	if state == "race":
		race_overlap = (
			_controls_overlap(main.speed_panel, main.aux_panel)
			or _controls_overlap(main.top_left_panel, main.top_center_panel)
			or _controls_overlap(main.top_center_panel, main.top_right_panel)
			or _controls_overlap(main.speed_panel, main.top_left_panel)
			or _controls_overlap(main.aux_panel, main.top_right_panel)
		)
	return "overflow=%d overlap=%s" % [overflow_count, race_overlap]


func _controls_overlap(a: Control, b: Control) -> bool:
	if not a or not b:
		return false
	return a.get_global_rect().intersects(b.get_global_rect(), false)


func _dict_text(data: Dictionary) -> String:
	return "layers=%s transitions=%d events=%d fade=exponential abrupt_stops=%d clip=%s" % [
		str(data["audible_layers"]),
		int(data["transition_count"]),
		int(data["events_played"]),
		int(data["abrupt_stop_count"]),
		str(data["clip_detected"]),
	]


func _save_viewport(main: Node, path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var image: Image = main.get_viewport().get_texture().get_image()
	if image:
		image.save_png(path)


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(text)
