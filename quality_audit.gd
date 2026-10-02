extends SceneTree


const TRACK_VIEWS := [
	{
		"id": "neon",
		"turn_t": 0.255,
		"shortcut_t": 0.156,
	},
	{
		"id": "snow",
		"turn_t": 0.355,
		"shortcut_t": 0.208,
	},
	{
		"id": "loop",
		"turn_t": 0.465,
		"shortcut_t": 0.378,
	},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://qa")
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	for frame in 24:
		await process_frame
	for warmup_track in 3:
		main._load_track(warmup_track)
		main.race_state = "racing"
		main.showroom_root.visible = false
		main._apply_track_environment()
		main.menu_camera.current = false
		main.player_camera.current = true
		_place_view(main, 0.16 + float(warmup_track) * 0.08)
		for frame in 36:
			await process_frame
	var report_lines := PackedStringArray()
	report_lines.append("track\tmeshes\tinstances\tlights\tparticles\tfps_avg\tcamera_far\tshadow_distance\tlight_budget\ttexture_limit\tshortcuts\tmin_clearance\tviolations")
	for track_index in 3:
		var view: Dictionary = TRACK_VIEWS[track_index]
		main._load_track(track_index)
		main.race_state = "racing"
		main.start_overlay.visible = false
		main.showroom_root.visible = false
		main._apply_track_environment()
		main._set_race_hud_visible(true)
		main.menu_camera.current = false
		main.player_camera.current = true
		main.player_velocity = -main.player.global_transform.basis.z * 18.0
		_place_view(main, 0.10)
		for frame in 18:
			await process_frame
		await RenderingServer.frame_post_draw
		_save_viewport(main, "res://qa/after_%s.png" % view["id"])
		_place_view(main, float(view["turn_t"]))
		for frame in 12:
			await process_frame
		await RenderingServer.frame_post_draw
		_save_viewport(main, "res://qa/detail_%s_turn.png" % view["id"])
		_place_view(main, float(view["shortcut_t"]))
		for frame in 12:
			await process_frame
		await RenderingServer.frame_post_draw
		_save_viewport(main, "res://qa/detail_%s_shortcut.png" % view["id"])
		var stats: Dictionary = await _collect_stats(main)
		var quality: Dictionary = main.track_data["quality"]
		var budget := TrackFactory.get_quality_budget(String(view["id"]))
		report_lines.append("%s\t%d\t%d\t%d\t%d\t%.1f\t%.0f\t%.0f\t%d\t%d\t%d\t%.1f\t%d" % [
			view["id"],
			stats["meshes"],
			stats["instances"],
			stats["lights"],
			stats["particles"],
			stats["fps_avg"],
			main.player_camera.far,
			main.sunlight.directional_shadow_max_distance,
			int(budget["max_lights"]),
			int(budget["texture_limit"]),
			int(quality["shortcut_count"]),
			float(quality["nearest_horizontal"]),
			int(quality["violations"]),
		])
	var report_file := FileAccess.open("res://qa/quality_report.txt", FileAccess.WRITE)
	if report_file:
		report_file.store_string("\n".join(report_lines) + "\n")
		report_file.close()
	print("\n".join(report_lines))
	quit()


func _place_view(main: Node, track_t: float) -> void:
	main.player_track_t = track_t
	main._place_car(main.player, track_t, 1.70)
	main.player_progress_index = main._nearest_track_index(main.player.global_position)
	main.player_previous_index = main.player_progress_index
	main.player_velocity = -main.player.global_transform.basis.z * 18.0
	main.player_forward_speed = 18.0


func _collect_stats(main: Node) -> Dictionary:
	var mesh_count := 0
	var instance_count := 0
	var light_count := 0
	var particle_count := 0
	for node in main.find_children("*", "", true, false):
		if node is Node3D and not node.is_visible_in_tree():
			continue
		if node is MeshInstance3D:
			mesh_count += 1
		if node is MultiMeshInstance3D and node.multimesh:
			instance_count += node.multimesh.visible_instance_count
		elif node is MeshInstance3D:
			instance_count += 1
		if node is Light3D:
			light_count += 1
		elif node is GPUParticles3D:
			particle_count += 1
	var fps_total := 0.0
	for frame in 90:
		fps_total += Engine.get_frames_per_second()
		await process_frame
	return {
		"meshes": mesh_count,
		"instances": instance_count,
		"lights": light_count,
		"particles": particle_count,
		"fps_avg": fps_total / 90.0,
	}


func _save_viewport(main: Node, path: String) -> void:
	var image: Image = main.get_viewport().get_texture().get_image()
	image.save_png(path)
