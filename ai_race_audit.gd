extends SceneTree

const MainScript = preload("res://main.gd")
const STEP := 1.0 / 60.0
const MAX_SIM_SECONDS := 420.0


func _init() -> void:
	call_deferred("_run_audit")


func _run_audit() -> void:
	var report_lines: PackedStringArray = PackedStringArray()
	report_lines.append("# AI Race Audit")
	report_lines.append("")
	report_lines.append("Simulation: fixed 60 Hz, standard difficulty, five personality profiles.")
	report_lines.append("Rubber band: target-speed factor only, hard-capped at +/-6%; no position or collision bypass.")
	report_lines.append("")
	report_lines.append("## Driver Profiles")
	report_lines.append("")
	report_lines.append("| Driver | Speed | Corner | Aggression | Drift | Mistake | Reaction |")
	report_lines.append("|---|---:|---:|---:|---:|---:|---:|")
	for profile in MainScript.AI_PROFILES:
		report_lines.append(
			"| %s | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f |"
			% [
				String(profile["name"]),
				float(profile["speed"]),
				float(profile["corner"]),
				float(profile["aggression"]),
				float(profile["drift"]),
				float(profile["mistake"]),
				float(profile["reaction"]),
			]
		)
	report_lines.append("")
	report_lines.append("## Difficulty Presets")
	report_lines.append("")
	report_lines.append("| Difficulty | Speed | Corner | Reaction | Mistake | Racecraft |")
	report_lines.append("|---|---:|---:|---:|---:|---:|")
	for preset in MainScript.DIFFICULTY_PRESETS:
		report_lines.append(
			"| %s | %.2f | %.2f | %.2f | %.2f | %.2f |"
			% [
				String(preset["name"]),
				float(preset["speed"]),
				float(preset["corner"]),
				float(preset["reaction"]),
				float(preset["mistake"]),
				float(preset["racecraft"]),
			]
		)
	report_lines.append("")
	var failures: PackedStringArray = PackedStringArray()
	for track_index in range(3):
		var result := await _run_track(track_index)
		report_lines.append_array(_format_track_result(result))
		if not bool(result["all_finished"]):
			failures.append("%s: unfinished AI" % result["track_name"])
		if int(result["max_simultaneous_offroad"]) > 2:
			failures.append("%s: too many AI offroad at once" % result["track_name"])
		if float(result["max_rubber_factor"]) > 0.0601:
			failures.append("%s: rubber band exceeded 6%%" % result["track_name"])
		for ai_result in result["ai_results"]:
			if int(ai_result["out_of_bounds"]) > 0:
				failures.append("%s / %s: left track boundary" % [
					result["track_name"],
					ai_result["name"],
				])
			if int(ai_result["shortcut_block_frames"]) > 0:
				failures.append("%s / %s: blocked a shortcut entry" % [
					result["track_name"],
					ai_result["name"],
				])
			if float(ai_result["max_step_m"]) > 1.05:
				failures.append("%s / %s: abnormal frame displacement" % [
					result["track_name"],
					ai_result["name"],
				])
	report_lines.append("## Verdict")
	report_lines.append("")
	if failures.is_empty():
		report_lines.append("- PASS: all acceptance checks passed.")
	else:
		report_lines.append("- FAIL: %d checks failed." % failures.size())
		for failure in failures:
			report_lines.append("- %s" % failure)
	report_lines.append("")
	var output_path := "res://AI_RACE_TEST_RESULTS.md"
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(report_lines) + "\n")
		file.close()
	print("\n".join(report_lines))
	quit(0 if failures.is_empty() else 1)


func _run_track(track_index: int) -> Dictionary:
	var main = MainScript.new()
	root.add_child(main)
	main._load_track(track_index)
	main._prepare_race_grid()
	main.race_state = "racing"
	main.race_elapsed_time = 0.0
	main.race_time = 0.0
	var track_descriptor: Dictionary = main.track_catalog[track_index]
	var start_usec := Time.get_ticks_usec()
	var simulated_steps := 0
	var max_simultaneous_offroad := 0
	var max_simultaneous_shortcut := 0
	var max_rubber_factor := 0.0
	var all_finished := false
	var first_finish := -1.0
	var last_finish := -1.0
	while float(simulated_steps) * STEP < MAX_SIM_SECONDS:
		main.race_elapsed_time += STEP
		main.race_time += STEP
		main._update_ai(STEP, false)
		simulated_steps += 1
		var offroad_count := 0
		var shortcut_count := 0
		var finished_count := 0
		for ai in main.ai_cars:
			if bool(ai["offroad"]):
				offroad_count += 1
			if bool(ai["in_shortcut"]):
				shortcut_count += 1
			max_rubber_factor = maxf(
				max_rubber_factor,
				absf(float(ai["rubber_factor"]))
			)
			if bool(ai["finished"]):
				finished_count += 1
				var finish_time := float(ai["finish_time"])
				first_finish = (
					finish_time
					if first_finish < 0.0
					else minf(first_finish, finish_time)
				)
				last_finish = maxf(last_finish, finish_time)
		max_simultaneous_offroad = maxi(max_simultaneous_offroad, offroad_count)
		max_simultaneous_shortcut = maxi(max_simultaneous_shortcut, shortcut_count)
		if finished_count == main.ai_cars.size():
			all_finished = true
			break
	var elapsed_usec := Time.get_ticks_usec() - start_usec
	var ai_results: Array[Dictionary] = []
	for ai in main.ai_cars:
		var stats: Dictionary = ai["stats"]
		var frames := maxi(int(stats["frames"]), 1)
		var profile: Dictionary = ai["profile"]
		ai_results.append({
			"name": profile["name"],
			"profile": profile["id"],
			"finished": bool(ai["finished"]),
			"finish_time": float(ai["finish_time"]),
			"avg_speed_kph": float(stats["speed_sum"]) / float(frames) * 3.6,
			"max_speed_kph": float(stats["max_speed"]) * 3.6,
			"max_step_m": float(stats["max_step"]),
			"offroad_pct": float(stats["offroad_frames"]) / float(frames) * 100.0,
			"out_of_bounds": int(stats["out_of_bounds_frames"]),
			"shortcut_frames": int(stats["shortcut_frames"]),
			"shortcut_block_frames": int(stats["shortcut_block_frames"]),
			"zero_speed_frames": int(stats["zero_speed_frames"]),
			"stuck_events": int(stats["stuck_events"]),
			"recoveries": int(stats["recoveries"]),
			"mistakes": int(stats["mistakes"]),
			"collision_frames": int(stats["collision_frames"]),
		})
	var total_ai_frames := 0
	var metric_frames := 0
	for stats_ai in main.ai_cars:
		var stats: Dictionary = stats_ai["stats"]
		total_ai_frames += int(stats["frames"])
		metric_frames = maxi(metric_frames, int(stats["frames"]))
	var wall_seconds := float(elapsed_usec) / 1_000_000.0
	var result := {
		"track_id": String(track_descriptor["id"]),
		"track_name": String(track_descriptor["name"]),
		"track_length": float(main.track_length),
		"laps": int(main.total_laps),
		"shortcuts": main.shortcut_samples.size(),
		"all_finished": all_finished,
		"sim_seconds": float(simulated_steps) * STEP,
		"first_finish": first_finish,
		"last_finish": last_finish,
		"max_simultaneous_offroad": max_simultaneous_offroad,
		"max_simultaneous_shortcut": max_simultaneous_shortcut,
		"max_rubber_factor": max_rubber_factor,
		"wall_seconds": wall_seconds,
		"ms_per_ai_frame": wall_seconds * 1000.0 / float(maxi(total_ai_frames, 1)),
		"realtime_factor": (
			float(simulated_steps) * STEP / maxf(wall_seconds, 0.0001)
		),
		"ai_results": ai_results,
	}
	main.queue_free()
	await process_frame
	return result


func _format_track_result(result: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("## %s" % result["track_name"])
	lines.append("")
	lines.append(
		"- Track: %.0f m, %d laps, %d shortcuts"
		% [float(result["track_length"]), int(result["laps"]), int(result["shortcuts"])]
	)
	lines.append("- All five AI finished: %s" % ("YES" if bool(result["all_finished"]) else "NO"))
	lines.append(
		"- Race window: %.3f s to %.3f s; simulated %.1f s"
		% [
			float(result["first_finish"]),
			float(result["last_finish"]),
			float(result["sim_seconds"]),
		]
	)
	lines.append(
		"- Peak simultaneous offroad: %d/5; peak in shortcut: %d/5; rubber band cap observed: %.2f%%"
		% [
			int(result["max_simultaneous_offroad"]),
			int(result["max_simultaneous_shortcut"]),
			float(result["max_rubber_factor"]) * 100.0,
		]
	)
	lines.append(
		"- Performance: %.3f s wall, %.4f ms per AI-frame, %.1fx realtime"
		% [
			float(result["wall_seconds"]),
			float(result["ms_per_ai_frame"]),
			float(result["realtime_factor"]),
		]
	)
	lines.append("")
	lines.append(
		"| AI | Finished | Time | Avg km/h | Max km/h | Max step m | Offroad | Out bounds | "
		+ "Shortcut block | Stuck | Recoveries | Mistakes | Collision frames |"
	)
	lines.append("|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
	for ai_result in result["ai_results"]:
		lines.append(
			"| %s | %s | %.3f | %.1f | %.1f | %.3f | %.2f%% | %d | %d | %d | %d | %d | %d |"
			% [
				String(ai_result["name"]),
				"YES" if bool(ai_result["finished"]) else "NO",
				float(ai_result["finish_time"]),
				float(ai_result["avg_speed_kph"]),
				float(ai_result["max_speed_kph"]),
				float(ai_result["max_step_m"]),
				float(ai_result["offroad_pct"]),
				int(ai_result["out_of_bounds"]),
				int(ai_result["shortcut_block_frames"]),
				int(ai_result["stuck_events"]),
				int(ai_result["recoveries"]),
				int(ai_result["mistakes"]),
				int(ai_result["collision_frames"]),
			]
		)
	lines.append("")
	return lines
