extends SceneTree

const DT := 1.0 / 60.0

var main: Node
var results: Array[Dictionary] = []
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	main.set_physics_process(false)
	for track_index in 3:
		main._load_track(track_index)
		await process_frame
		main.ai_cars.clear()
		_run_engine_brake_test(track_index)
		_run_steering_test(track_index)
		_run_drift_test(track_index)
		_run_offroad_test(track_index)
		_run_collision_test(track_index)
		_run_slope_test(track_index)
		_run_shortcut_tests(track_index)
	_write_report()
	main.queue_free()
	quit(1 if failures > 0 else 0)


func _run_engine_brake_test(track_index: int) -> void:
	_start_scenario(track_index, 0.012, 0.0, true)
	_set_input(1.0, 0.0, false, false, false, false)
	var max_speed := 0.0
	var max_speed_step := 0.0
	var time_to_100 := -1.0
	for frame in 900:
		var before: float = main.player_forward_speed
		main._update_player(DT)
		max_speed = maxf(max_speed, main.player_forward_speed)
		max_speed_step = maxf(max_speed_step, absf(main.player_forward_speed - before))
		if time_to_100 < 0.0 and max_speed >= 100.0 / 3.6:
			time_to_100 = float(frame + 1) * DT
	var top_speed_ok: bool = (
		max_speed >= main.driving_tuning.max_forward_speed * 0.88
		and max_speed <= main.driving_tuning.max_forward_speed + 0.15
	)
	var acceleration_ok: bool = (
		time_to_100 > 0.0
		and time_to_100 < 7.0
		and max_speed_step < 0.65
	)
	_record(
		"acceleration_curve",
		track_index,
		top_speed_ok and acceleration_ok,
		{
			"top_speed_mps": snappedf(max_speed, 0.01),
			"zero_to_100_s": snappedf(time_to_100, 0.01) if time_to_100 > 0.0 else -1.0,
			"max_step_mps": snappedf(max_speed_step, 0.001),
		}
	)

	_set_input(0.0, 1.0, false, false, false, false)
	var stop_time := -1.0
	var max_brake_step := 0.0
	for frame in 240:
		var before: float = main.player_forward_speed
		main._update_player(DT)
		max_brake_step = maxf(max_brake_step, absf(main.player_forward_speed - before))
		if stop_time < 0.0 and main.player_forward_speed <= 0.05:
			stop_time = float(frame + 1) * DT
			break
	var reverse_speed := 0.0
	for frame in 150:
		main._update_player(DT)
		reverse_speed = minf(reverse_speed, main.player_forward_speed)
	var braking_ok: bool = (
		stop_time > 0.0
		and stop_time < 2.0
		and max_brake_step < 1.15
		and reverse_speed <= -5.0
		and reverse_speed >= -main.driving_tuning.reverse_max_speed - 0.15
	)
	_record(
		"brake_reverse",
		track_index,
		braking_ok,
		{
			"stop_time_s": snappedf(stop_time, 0.01),
			"max_step_mps": snappedf(max_brake_step, 0.001),
			"reverse_mps": snappedf(reverse_speed, 0.01),
		}
	)

	_start_scenario(track_index, 0.012, 30.0, true)
	main.player_drift_charge = 100.0
	_set_input(1.0, 0.0, false, false, false, true)
	var max_boost_speed := 30.0
	var max_fov: float = main.player_camera.fov
	for frame in 210:
		main._update_player(DT)
		main._update_camera(DT)
		max_boost_speed = maxf(max_boost_speed, main.player_forward_speed)
		max_fov = maxf(max_fov, main.player_camera.fov)
	var nitro_ok: bool = (
		max_boost_speed > main.driving_tuning.max_forward_speed + 5.0
		and max_boost_speed <= main.driving_tuning.nitro_max_speed + 0.15
		and max_fov <= main.driving_tuning.base_fov + main.driving_tuning.speed_fov_gain
			+ main.driving_tuning.nitro_fov_boost + 2.0
	)
	_record(
		"nitro_camera",
		track_index,
		nitro_ok,
		{
			"boost_speed_mps": snappedf(max_boost_speed, 0.01),
			"max_fov": snappedf(max_fov, 0.01),
		}
	)


func _run_steering_test(track_index: int) -> void:
	_start_scenario(track_index, 0.10, 8.0, true)
	_set_input(0.55, 0.0, true, false, false, false)
	var max_yaw := 0.0
	var max_heading_step := 0.0
	var sign_flips := 0
	var last_sign := 0
	var previous_heading: float = main.player.rotation.y
	for frame in 300:
		main._update_player(DT)
		max_yaw = maxf(max_yaw, absf(main.player_yaw_rate))
		var heading: float = main.player.rotation.y
		var heading_step := absf(wrapf(heading - previous_heading, -PI, PI))
		max_heading_step = maxf(max_heading_step, heading_step)
		previous_heading = heading
		if frame >= 30:
			var current_sign := signi(int(round(signf(main.player_yaw_rate))))
			if current_sign != 0 and last_sign != 0 and current_sign != last_sign:
				sign_flips += 1
			if current_sign != 0:
				last_sign = current_sign
	var steering_ok: bool = (
		sign_flips == 0
		and max_yaw <= main.driving_tuning.max_yaw_rate + 0.08
		and max_heading_step <= main.driving_tuning.max_yaw_rate * DT + 0.002
		and _finite_scalar(main.player.rotation.y)
	)
	_record(
		"low_speed_steering",
		track_index,
		steering_ok,
		{
			"max_yaw_rps": snappedf(max_yaw, 0.01),
			"sign_flips": sign_flips,
			"max_heading_step_rad": snappedf(max_heading_step, 0.0001),
		}
	)

	_start_scenario(track_index, 0.10, 32.0, true)
	_set_input(0.0, 0.0, true, false, false, false)
	max_yaw = 0.0
	sign_flips = 0
	last_sign = 0
	for frame in 180:
		main._update_player(DT)
		max_yaw = maxf(max_yaw, absf(main.player_yaw_rate))
		if frame >= 20:
			var current_sign := signi(int(round(signf(main.player_yaw_rate))))
			if current_sign != 0 and last_sign != 0 and current_sign != last_sign:
				sign_flips += 1
			if current_sign != 0:
				last_sign = current_sign
	var high_speed_ok: bool = (
		sign_flips == 0
		and max_yaw <= main.driving_tuning.max_yaw_rate + 0.08
		and absf(main.player_slip_angle) <= deg_to_rad(
			main.driving_tuning.max_normal_slip_angle_degrees
		) + 0.02
	)
	_record(
		"high_speed_steering",
		track_index,
		high_speed_ok,
		{
			"max_yaw_rps": snappedf(max_yaw, 0.01),
			"sign_flips": sign_flips,
			"final_slip_deg": snappedf(rad_to_deg(absf(main.player_slip_angle)), 0.01),
		}
	)


func _run_drift_test(track_index: int) -> void:
	_start_scenario(track_index, 0.10, 26.0, true)
	_set_input(1.0, 0.0, true, false, true, false)
	var max_slip := 0.0
	var max_yaw := 0.0
	var max_smoke := 0.0
	for frame in 240:
		main._update_player(DT)
		main._update_particle_effects()
		max_slip = maxf(max_slip, absf(main.player_slip_angle))
		max_yaw = maxf(max_yaw, absf(main.player_yaw_rate))
		max_smoke = maxf(max_smoke, main.player_smoke_intensity)
	var marks_created := 0
	if main.skid_multimesh:
		marks_created = main.skid_multimesh.visible_instance_count
	var sustained_ok: bool = (
		max_slip >= deg_to_rad(12.0)
		and max_slip <= deg_to_rad(main.driving_tuning.max_slip_angle_degrees) + 0.03
		and max_yaw <= main.driving_tuning.max_yaw_rate + 0.08
		and max_smoke > 0.35
		and marks_created > 0
	)
	_record(
		"drift_entry",
		track_index,
		sustained_ok,
		{
			"peak_slip_deg": snappedf(rad_to_deg(max_slip), 0.01),
			"peak_yaw_rps": snappedf(max_yaw, 0.01),
			"peak_smoke": snappedf(max_smoke, 0.01),
			"skid_segments": marks_created,
		}
	)

	_set_input(0.35, 0.0, false, true, false, false)
	var recovery_frames := -1
	for frame in 210:
		main._update_player(DT)
		main._update_particle_effects()
		if main.player_drift_angle < deg_to_rad(7.0) and main.player_drift_blend < 0.06:
			recovery_frames = frame + 1
			break
	var recovery_ok: bool = (
		recovery_frames > 0
		and recovery_frames < 180
		and absf(main.player_yaw_rate) <= main.driving_tuning.max_yaw_rate + 0.08
		and _finite_scalar(main.player.rotation.y)
	)
	_record(
		"drift_exit",
		track_index,
		recovery_ok,
		{
			"recovery_frames": recovery_frames,
			"final_slip_deg": snappedf(rad_to_deg(main.player_drift_angle), 0.01),
			"final_blend": snappedf(main.player_drift_blend, 0.01),
		}
	)


func _run_offroad_test(track_index: int) -> void:
	_start_scenario(track_index, 0.10, 28.0, false)
	var nearest: Dictionary = main._nearest_track_point(
		main.player.global_position,
		main.player_progress_index
	)
	var side: Vector3 = nearest["side"]
	var tangent: Vector3 = main.track_tangents[int(nearest["index"])]
	main.player.global_position = (
		nearest["center"]
		+ side * (main.road_half_width + 1.2)
		+ Vector3.UP * 0.055
	)
	main.offroad_limit = 1000.0
	main.player_velocity = tangent * 28.0
	_set_input(1.0, 0.0, false, false, false, false)
	var offroad_frames := 0
	var max_speed_step := 0.0
	var max_speed := 0.0
	for frame in 300:
		var before: float = main.player_forward_speed
		main._update_player(DT)
		if main.player_offroad:
			offroad_frames += 1
		max_speed = maxf(max_speed, main.player_forward_speed)
		max_speed_step = maxf(max_speed_step, absf(main.player_forward_speed - before))
	var offroad_limit: float = (
		main.driving_tuning.max_forward_speed
		* main.driving_tuning.offroad_speed_factor
	)
	var offroad_ok: bool = (
		offroad_frames > 240
		and main.player_forward_speed <= offroad_limit * 1.04
		and max_speed_step < 0.65
	)
	_record(
		"offroad_penalty",
		track_index,
		offroad_ok,
		{
			"offroad_frames": offroad_frames,
			"final_speed_mps": snappedf(main.player_forward_speed, 0.01),
			"soft_limit_mps": snappedf(offroad_limit, 0.01),
			"max_step_mps": snappedf(max_speed_step, 0.001),
		}
	)


func _run_collision_test(track_index: int) -> void:
	_start_scenario(track_index, 0.10, 12.0, false)
	var nearest: Dictionary = main._nearest_track_point(
		main.player.global_position,
		main.player_progress_index
	)
	var side: Vector3 = nearest["side"]
	var tangent: Vector3 = main.track_tangents[int(nearest["index"])]
	var collision_limit: float = main.offroad_limit
	for attempt in 4:
		main.player.global_position = (
			nearest["center"]
			+ side * (collision_limit + 0.24 + float(attempt) * 0.18)
			+ Vector3.UP * 0.055
		)
		nearest = main._nearest_track_point(
			main.player.global_position,
			main.player_progress_index
		)
		side = nearest["side"]
		tangent = main.track_tangents[int(nearest["index"])]
		if float(nearest["distance"]) > collision_limit:
			break
	main.player_velocity = tangent * 12.0 + side * 14.0
	var initial_outward_speed: float = main.player_velocity.dot(side)
	var initial_distance: float = nearest["distance"]
	_set_input(0.0, 0.0, false, false, false, false)
	var events_before := int(main.race_audio.debug_snapshot()["events_played"])
	main._resolve_player_boundary(nearest)
	var cooldown_before_camera: float = main.impact_cooldown
	var events_after := int(main.race_audio.debug_snapshot()["events_played"])
	var trauma_after_impact: float = main.camera_collision_trauma
	main._update_camera(DT)
	var collision_ok: bool = (
		trauma_after_impact > 0.05
		and main.impact_cooldown > 0.0
		and main.player_velocity.dot(side) < 0.5
		and _finite_vector(main.camera_collision_kick)
	)
	_record(
		"collision_feedback",
		track_index,
		collision_ok,
		{
			"trauma": snappedf(trauma_after_impact, 0.01),
			"cooldown_s": snappedf(main.impact_cooldown, 0.01),
			"cooldown_before_camera_s": snappedf(cooldown_before_camera, 0.01),
			"audio_events_delta": events_after - events_before,
			"outward_speed_after_mps": snappedf(main.player_velocity.dot(side), 0.01),
			"initial_outward_speed_mps": snappedf(initial_outward_speed, 0.01),
			"initial_distance_m": snappedf(initial_distance, 0.01),
			"offroad_limit_m": snappedf(main.offroad_limit, 0.01),
		}
	)


func _run_slope_test(track_index: int) -> void:
	var uphill_index := 0
	var downhill_index := 0
	for index in main.track_tangents.size():
		if main.track_tangents[index].y > main.track_tangents[uphill_index].y:
			uphill_index = index
		if main.track_tangents[index].y < main.track_tangents[downhill_index].y:
			downhill_index = index
	for slope_name in ["uphill", "downhill"]:
		var sample_index := uphill_index if slope_name == "uphill" else downhill_index
		var sample_t := float(sample_index) / float(main.track_samples.size())
		_start_scenario(track_index, sample_t, 22.0, true)
		_set_input(0.0, 0.0, false, false, false, false)
		var max_y_step := 0.0
		var previous_y: float = main.player.global_position.y
		for frame in 180:
			main._update_player(DT)
			max_y_step = maxf(max_y_step, absf(main.player.global_position.y - previous_y))
			previous_y = main.player.global_position.y
		var slope_ok: bool = (
			max_y_step < 0.16
			and _finite_vector(main.player.global_position)
			and _finite_scalar(main.player_slip_angle)
		)
		_record(
			"slope_%s" % slope_name,
			track_index,
			slope_ok,
			{
				"grade_percent": snappedf(main.track_tangents[sample_index].y * 100.0, 0.1),
				"max_y_step_m": snappedf(max_y_step, 0.0001),
				"final_speed_mps": snappedf(main.player_forward_speed, 0.01),
			}
		)


func _run_shortcut_tests(track_index: int) -> void:
	for shortcut_index in main.shortcut_samples.size():
		var points: PackedVector3Array = main.shortcut_samples[shortcut_index]
		var tangents: PackedVector3Array = main.shortcut_tangents[shortcut_index]
		_start_scenario(track_index, 0.10, 6.0, false)
		main.player.global_position = points[0] + Vector3.UP * 0.15
		main.player.look_at(main.player.global_position + tangents[0], Vector3.UP)
		main.player_velocity = tangents[0] * 6.0
		main.player_progress_index = main._nearest_track_index(main.player.global_position)
		main.player_previous_index = main.player_progress_index
		var current_index := 0
		var on_shortcut_frames := 0
		var max_y_step := 0.0
		var max_slip := 0.0
		var completed := false
		var frames_used := 0
		var previous_y: float = main.player.global_position.y
		for frame in 10000:
			frames_used = frame + 1
			var nearest_path_index := current_index
			var nearest_path_distance := INF
			for scan in points.size():
				var path_distance: float = main.player.global_position.distance_squared_to(
					points[scan]
				)
				if path_distance < nearest_path_distance:
					nearest_path_distance = path_distance
					nearest_path_index = scan
			current_index = nearest_path_index
			var path_tangent: Vector3 = tangents[current_index]
			var path_side := Vector3.UP.cross(path_tangent).normalized()
			var cross_track: float = (
				main.player.global_position - points[current_index]
			).dot(path_side)
			var target_index := mini(current_index + 3, points.size() - 1)
			var forward: Vector3 = -main.player.global_transform.basis.z
			var to_target: Vector3 = points[target_index] - main.player.global_position
			to_target.y = 0.0
			var heading_error := 0.0
			if forward.length_squared() > 0.001 and to_target.length_squared() > 0.001:
				heading_error = atan2(
					forward.cross(to_target.normalized()).y,
					forward.dot(to_target.normalized())
				)
			var steer := clampf(
				heading_error * 2.35 - cross_track * 0.16,
				-1.0,
				1.0
			)
			if absf(steer) < 0.02:
				steer = 0.0
			var control_speed: float = main.player_forward_speed
			_set_input(
				1.0 if control_speed < 6.0 else 0.0,
				1.0 if control_speed > 7.2 else 0.0,
				steer > 0.0,
				steer < 0.0,
				false,
				false
			)
			main._update_player(DT)
			if main.player_in_shortcut:
				on_shortcut_frames += 1
			max_y_step = maxf(max_y_step, absf(main.player.global_position.y - previous_y))
			previous_y = main.player.global_position.y
			max_slip = maxf(max_slip, absf(main.player_slip_angle))
			if current_index >= points.size() - 4:
				completed = true
				break
		var shortcut_ok: bool = (
			completed
			and on_shortcut_frames > int(float(frames_used) * 0.78)
			and max_y_step < 0.16
			and max_slip <= deg_to_rad(main.driving_tuning.max_normal_slip_angle_degrees) + 0.04
		)
		var final_path_distance: float = main.player.global_position.distance_to(
			points[current_index]
		)
		_record(
			"shortcut_%d" % shortcut_index,
			track_index,
			shortcut_ok,
			{
				"completed": completed,
				"on_shortcut_frames": on_shortcut_frames,
				"max_y_step_m": snappedf(max_y_step, 0.0001),
				"max_slip_deg": snappedf(rad_to_deg(max_slip), 0.01),
				"frames_used": frames_used,
				"final_index": current_index,
				"final_path_distance_m": snappedf(final_path_distance, 0.01),
				"final_speed_mps": snappedf(main.player_forward_speed, 0.01),
			}
		)


func _start_scenario(
	track_index: int,
	track_t: float,
	speed: float,
	wide_track: bool
) -> void:
	main.ai_cars.clear()
	main.race_state = "racing"
	main.race_time = 0.0
	main.start_overlay.visible = false
	main.showroom_root.visible = false
	main._apply_track_environment()
	main._set_race_hud_visible(true)
	main.menu_camera.current = false
	main.player_camera.current = true
	main.player_track_t = track_t
	main._place_car(main.player, track_t, 0.0)
	var body: Node3D = main.player.get_child(0)
	body.rotation = Vector3.ZERO
	for wheel in main.player.get_meta("all_wheels"):
		wheel.rotation = Vector3.ZERO
	var tangent := TrackFactory.tangent_at(
		main.curve,
		track_t * main.track_length,
		main.track_length
	)
	main.player_velocity = tangent * speed
	main.player_forward_speed = speed
	main.player_lateral_speed = 0.0
	main.player_steering = 0.0
	main.player_yaw_rate = 0.0
	main.player_slip_angle = 0.0
	main.player_longitudinal_acceleration = 0.0
	main.player_drift_angle = 0.0
	main.player_drift_blend = 0.0
	main.player_drifting = false
	main.player_offroad = false
	main.player_in_shortcut = false
	main.player_drift_charge = 20.0
	main.player_nitro_time = 0.0
	main.nitro_requested = false
	main.player_lap = 0
	main.player_finished = false
	main.player_previous_index = main._nearest_track_index(main.player.global_position)
	main.player_progress_index = main.player_previous_index
	main.impact_cooldown = 0.0
	main.camera_collision_kick = Vector3.ZERO
	main.camera_collision_trauma = 0.0
	main.camera_acceleration_stretch = 0.0
	main.player_smoke_intensity = 0.0
	main.road_half_width = 1000.0 if wide_track else float(
		main.track_data["half_width"]
	)
	main.offroad_limit = (
		1002.0
		if wide_track
		else main.road_half_width + 2.25
	)
	main._clear_skid_marks()
	_set_input(0.0, 0.0, false, false, false, false)


func _set_input(
	throttle: float,
	brake: float,
	left: bool,
	right: bool,
	drift: bool,
	nitro: bool
) -> void:
	main.debug_drive_input = {
		"throttle": throttle > 0.0,
		"brake": brake > 0.0,
		"steer_left": left,
		"steer_right": right,
		"drift": drift,
		"nitro": nitro,
	}


func _record(
	test_name: String,
	track_index: int,
	passed: bool,
	metrics: Dictionary
) -> void:
	if not passed:
		failures += 1
	results.append({
		"test": test_name,
		"track": main.track_catalog[track_index]["name"],
		"passed": passed,
		"metrics": metrics,
	})
	print(
		"%s | %s | %s | %s" % [
			"PASS" if passed else "FAIL",
			main.track_catalog[track_index]["name"],
			test_name,
			JSON.stringify(metrics),
		]
	)


func _write_report() -> void:
	var lines: Array[String] = [
		"# Q版氮气竞速驾驶审计",
		"",
		"- 固定步长：60 Hz",
		"- 测试用例：%d" % results.size(),
		"- 失败：%d" % failures,
		"- 输入入口：与实机相同的 `_update_player` 驾驶路径",
		"",
		"| 结果 | 赛道 | 用例 | 指标 |",
		"| --- | --- | --- | --- |",
	]
	for result in results:
		lines.append(
			"| %s | %s | %s | `%s` |" % [
				"通过" if result["passed"] else "失败",
				result["track"],
				result["test"],
				JSON.stringify(result["metrics"]),
			]
		)
	lines.append("")
	lines.append(
		"自动测试不会替代人工手感评估；它用于阻止不连续速度、无限侧滑、"
		+ "坡度/捷径高度跳变和输入抖动回归。"
	)
	var file := FileAccess.open("res://DRIVING_AUDIT.md", FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines))
		file.close()


func _finite_scalar(value: float) -> bool:
	return is_finite(value)


func _finite_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
