extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	for frame in 24:
		await process_frame
	await RenderingServer.frame_post_draw
	_save_viewport(main, "res://art_audit_showroom.png")
	for track_index in 3:
		main._load_track(track_index)
		main.race_state = "racing"
		main.start_overlay.visible = false
		main.showroom_root.visible = false
		main._apply_track_environment()
		main._set_race_hud_visible(true)
		main.menu_camera.current = false
		main.player_camera.current = true
		main._place_car(main.player, 0.10, 1.7)
		main.player_velocity = -main.player.global_transform.basis.z * 20.0
		for frame in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		_save_viewport(main, "res://art_audit_%d.png" % track_index)
		var mesh_count := 0
		var light_count := 0
		var particle_count := 0
		for node in main.find_children("*", "", true, false):
			if node is MeshInstance3D:
				mesh_count += 1
			elif node is Light3D:
				light_count += 1
			elif node is GPUParticles3D:
				particle_count += 1
		var fps_total := 0.0
		for frame in 60:
			fps_total += Engine.get_frames_per_second()
			await process_frame
		print("%s meshes=%d lights=%d particles=%d fps=%.1f" % [
			main.current_track_name,
			mesh_count,
			light_count,
			particle_count,
			fps_total / 60.0,
		])
	quit()


func _save_viewport(main: Node, path: String) -> void:
	var image: Image = main.get_viewport().get_texture().get_image()
	image.save_png(path)
