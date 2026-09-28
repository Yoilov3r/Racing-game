extends Node3D

const BASE_MAX_SPEED := 34.0
const BOOST_MAX_SPEED := 52.0
var road_half_width := TrackFactory.HALF_WIDTH
var offroad_limit := TrackFactory.HALF_WIDTH + 2.25

var world_root: Node3D
var track_root: Node3D
var racers_root: Node3D
var showroom_root: Node3D
var showroom_origin := Vector3(0.0, 5000.0, 0.0)
var world_environment: WorldEnvironment
var environment: Environment
var sky_material: ProceduralSkyMaterial
var sunlight: DirectionalLight3D
var fill_light: DirectionalLight3D
var track_catalog: Array[Dictionary] = []
var current_track_index := 0
var current_track_id := "neon"
var current_track_name := "霓虹夜街"
var total_laps := 3

var track_data: Dictionary
var curve: Curve3D
var track_length := 0.0
var track_samples: PackedVector3Array
var track_tangents: PackedVector3Array
var shortcut_samples: Array[PackedVector3Array] = []
var shortcut_tangents: Array[PackedVector3Array] = []
var shortcut_widths: PackedFloat32Array = PackedFloat32Array()

var player: Node3D
var player_camera: Camera3D
var menu_camera: Camera3D
var player_velocity := Vector3.ZERO
var player_forward_speed := 0.0
var player_lateral_speed := 0.0
var player_steering := 0.0
var player_lap := 0
var player_progress_index := 0
var player_previous_index := 0
var player_track_t := 0.002
var player_drift_angle := 0.0
var player_drift_charge := 0.0
var player_drifting := false
var player_offroad := false
var player_in_shortcut := false
var player_nitro_time := 0.0
var nitro_requested := false
var player_finished := false
var player_finish_time := 0.0
var front_wheel_spin := 0.0
var camera_base_position := Vector3(0.0, 1.58, -0.32)

var ai_cars: Array[Dictionary] = []
var player_place := 1
var race_state := "waiting"
var countdown_time := 3.6
var race_time := 0.0
var last_countdown_value := 4

var hud_layer: CanvasLayer
var top_strip: ColorRect
var speed_label: Label
var gear_label: Label
var lap_label: Label
var place_label: Label
var timer_label: Label
var nitro_bar: ProgressBar
var drift_bar: ProgressBar
var nitro_state_label: Label
var drift_state_label: Label
var center_message: Label
var start_overlay: Control
var pause_overlay: Control
var finish_overlay: Control
var finish_place_label: Label
var finish_time_label: Label
var offroad_label: Label
var track_name_label: Label
var track_info_label: Label
var track_option_labels: Array[Label] = []
var finish_prompt_label: Label
var controls_label: Label
var minimap: RaceMinimap
var minimap_lap_label: Label

var engine_player: AudioStreamPlayer
var engine_high_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var impact_players: Array[AudioStreamPlayer] = []
var impact_cooldown := 0.0


func _ready() -> void:
	get_window().title = "Q版氮气竞速"
	track_catalog = TrackFactory.get_track_catalog()
	world_root = Node3D.new()
	world_root.name = "WorldRoot"
	add_child(world_root)
	_setup_world()
	_setup_showroom()
	_load_track(0)
	_setup_hud()
	_configure_minimap()
	_set_race_hud_visible(false)
	_setup_audio()
	_refresh_track_menu()
	set_process(true)
	set_physics_process(true)


func _setup_world() -> void:
	world_environment = WorldEnvironment.new()
	environment = Environment.new()
	var sky := Sky.new()
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#167fb6")
	sky_material.sky_horizon_color = Color("#b7e3ed")
	sky_material.ground_bottom_color = Color("#617765")
	sky_material.ground_horizon_color = Color("#b8d2bd")
	sky_material.sun_angle_max = 18.0
	sky_material.sun_curve = 0.08
	sky_material.sky_energy_multiplier = 1.25
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.52
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 0.9
	environment.ssao_enabled = true
	environment.ssao_radius = 2.4
	environment.ssao_intensity = 1.15
	environment.ssr_enabled = true
	environment.ssr_max_steps = 48
	environment.ssr_fade_in = 0.25
	environment.ssr_fade_out = 18.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.85
	environment.glow_bloom = 0.18
	environment.glow_hdr_threshold = 0.82
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.10
	environment.fog_enabled = true
	environment.fog_light_color = Color("#b9dbe0")
	environment.fog_light_energy = 0.8
	environment.fog_density = 0.0018
	environment.fog_sky_affect = 0.55
	world_environment.environment = environment
	world_root.add_child(world_environment)

	sunlight = DirectionalLight3D.new()
	sunlight.name = "Sunlight"
	sunlight.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	sunlight.light_color = Color("#fff0d0")
	sunlight.light_energy = 0.82
	sunlight.shadow_enabled = true
	sunlight.shadow_bias = 0.035
	sunlight.directional_shadow_max_distance = 260.0
	world_root.add_child(sunlight)

	fill_light = DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-25.0, 145.0, 0.0)
	fill_light.light_color = Color("#a7d5ff")
	fill_light.light_energy = 0.18
	fill_light.shadow_enabled = false
	world_root.add_child(fill_light)


func _setup_showroom() -> void:
	showroom_root = ShowroomFactory.build(world_root)
	showroom_root.position = showroom_origin
	showroom_root.visible = false


func _load_track(track_index: int) -> void:
	current_track_index = clampi(track_index, 0, track_catalog.size() - 1)
	var descriptor: Dictionary = track_catalog[current_track_index]
	current_track_id = String(descriptor["id"])
	current_track_name = String(descriptor["name"])
	total_laps = int(descriptor["laps"])

	if track_root:
		track_root.queue_free()
	if racers_root:
		racers_root.queue_free()
	ai_cars.clear()
	player = null
	player_camera = null

	track_root = Node3D.new()
	track_root.name = "Track_%s" % current_track_id
	world_root.add_child(track_root)
	track_data = TrackFactory.build_track(track_root, current_track_id)
	curve = track_data["curve"]
	track_length = track_data["length"]
	track_samples = track_data["samples"]
	track_tangents = track_data["tangents"]
	shortcut_samples.clear()
	shortcut_tangents.clear()
	shortcut_widths.clear()
	for shortcut in track_data["shortcuts"]:
		shortcut_samples.append(shortcut["samples"])
		shortcut_tangents.append(shortcut["tangents"])
		shortcut_widths.append(float(shortcut["width"]))
	road_half_width = float(track_data["half_width"])
	offroad_limit = road_half_width + 2.25
	_apply_track_environment()
	_update_ambient_for_track()

	racers_root = Node3D.new()
	racers_root.name = "Racers"
	world_root.add_child(racers_root)
	_setup_racers()
	_reset_race_state()
	_enter_showroom()
	if minimap:
		_configure_minimap()
	if start_overlay:
		start_overlay.visible = true
		_refresh_track_menu()


func _setup_racers() -> void:
	player = CarFactory.create_car(Color("#d3182b"), true)
	racers_root.add_child(player)
	_place_car(player, player_track_t, 1.7)
	player_camera = player.get_meta("camera")
	player_camera.current = false
	menu_camera = Camera3D.new()
	menu_camera.name = "ShowcaseCamera"
	menu_camera.fov = 52.0
	menu_camera.current = true
	racers_root.add_child(menu_camera)
	player_previous_index = _nearest_track_index(player.global_position)
	player_progress_index = player_previous_index

	var ai_colors := [
		Color("#1db7cf"),
		Color("#f2c532"),
		Color("#e43e57"),
		Color("#7c58d6"),
		Color("#28b86f"),
	]
	var lane_offsets := [-2.6, 2.6, -2.6, 2.6, -2.6]
	var descriptor: Dictionary = track_catalog[current_track_index]
	var race_target_speed := track_length / float(descriptor["lap_time"])
	for i in ai_colors.size():
		var start_t := fposmod(1.0 - float(i + 1) * 7.4 / track_length, 1.0)
		var car := CarFactory.create_car(ai_colors[i], false)
		racers_root.add_child(car)
		_place_car(car, start_t, lane_offsets[i])
		var ai := {
			"node": car,
			"t": start_t,
			"lap": -1,
			"base_speed": clampf(race_target_speed * (0.99 + float(i) * 0.008), 27.0, 38.0),
			"current_speed": 0.0,
			"lane": lane_offsets[i],
			"lane_phase": float(i) * 1.37,
			"boost": 0.0,
			"color": ai_colors[i],
			"last_t": start_t,
			"total": float(i + 1) * 3.0,
		}
		ai_cars.append(ai)
	if current_track_id == "snow" and player_camera:
		_create_snow_particles(player_camera)
	_update_race_place()


func _create_snow_particles(camera: Camera3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Snowfall"
	particles.amount = 520
	particles.lifetime = 7.0
	particles.preprocess = 3.0
	particles.local_coords = true
	particles.position = Vector3(0.0, 7.0, -22.0)
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(70.0, 20.0, 70.0)
	process_material.direction = Vector3(0.0, -1.0, 0.0)
	process_material.spread = 55.0
	process_material.initial_velocity_min = 3.0
	process_material.initial_velocity_max = 8.0
	process_material.gravity = Vector3(0.0, -2.6, 0.0)
	process_material.scale_min = 0.45
	process_material.scale_max = 1.25
	particles.process_material = process_material
	var snow_mesh := QuadMesh.new()
	snow_mesh.size = Vector2(0.10, 0.10)
	var snow_material := CarFactory.make_material(Color(0.94, 0.98, 1.0, 0.88), 0.0, 0.5)
	snow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	snow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	snow_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	snow_mesh.material = snow_material
	particles.draw_pass_1 = snow_mesh
	camera.add_child(particles)


func _apply_track_environment() -> void:
	sunlight.shadow_enabled = true
	match current_track_id:
		"neon":
			sky_material.sky_top_color = Color("#01040c")
			sky_material.sky_horizon_color = Color("#15264e")
			sky_material.ground_bottom_color = Color("#090d17")
			sky_material.ground_horizon_color = Color("#171d34")
			sky_material.sky_energy_multiplier = 0.45
			environment.ambient_light_energy = 0.72
			environment.fog_light_color = Color("#101c31")
			environment.fog_light_energy = 0.7
			environment.fog_density = 0.0017
			environment.fog_sky_affect = 0.78
			environment.volumetric_fog_enabled = true
			environment.volumetric_fog_density = 0.011
			environment.volumetric_fog_albedo = Color("#122640")
			environment.glow_intensity = 1.52
			environment.glow_bloom = 0.28
			environment.tonemap_exposure = 1.24
			sunlight.light_color = Color("#8fb8ff")
			sunlight.light_energy = 0.52
			fill_light.light_color = Color("#3f79ff")
			fill_light.light_energy = 0.24
		"snow":
			sky_material.sky_top_color = Color("#86b9d8")
			sky_material.sky_horizon_color = Color("#e4f2f4")
			sky_material.ground_bottom_color = Color("#b9cbd1")
			sky_material.ground_horizon_color = Color("#dbe7e6")
			sky_material.sky_energy_multiplier = 1.05
			environment.ambient_light_energy = 0.78
			environment.fog_light_color = Color("#d5e5e9")
			environment.fog_light_energy = 0.94
			environment.fog_density = 0.0021
			environment.fog_sky_affect = 0.58
			environment.volumetric_fog_enabled = true
			environment.volumetric_fog_density = 0.0045
			environment.volumetric_fog_albedo = Color("#e9f4f6")
			environment.glow_intensity = 0.58
			environment.glow_bloom = 0.10
			environment.tonemap_exposure = 0.98
			sunlight.light_color = Color("#eaf4ff")
			sunlight.light_energy = 1.04
			fill_light.light_color = Color("#a8d3ff")
			fill_light.light_energy = 0.25
		_:
			sky_material.sky_top_color = Color("#187db6")
			sky_material.sky_horizon_color = Color("#c9e4e8")
			sky_material.ground_bottom_color = Color("#6d7d6d")
			sky_material.ground_horizon_color = Color("#b9cdb7")
			sky_material.sky_energy_multiplier = 1.15
			environment.ambient_light_energy = 0.64
			environment.fog_light_color = Color("#c4dfe2")
			environment.fog_light_energy = 0.86
			environment.fog_density = 0.0017
			environment.fog_sky_affect = 0.58
			environment.volumetric_fog_enabled = true
			environment.volumetric_fog_density = 0.004
			environment.volumetric_fog_albedo = Color("#d7e9eb")
			environment.glow_intensity = 0.72
			environment.glow_bloom = 0.14
			environment.tonemap_exposure = 0.92
			sunlight.light_color = Color("#fff0d0")
			sunlight.light_energy = 0.88
			fill_light.light_color = Color("#a7d5ff")
			fill_light.light_energy = 0.20


func _enter_showroom() -> void:
	if not showroom_root or not player:
		return
	showroom_root.visible = true
	for ai in ai_cars:
		var node: Node3D = ai["node"]
		node.visible = false
	player.visible = true
	player.global_position = showroom_origin
	player.rotation = Vector3.ZERO
	player_velocity = Vector3.ZERO
	if engine_player:
		engine_player.stop()
	if engine_high_player:
		engine_high_player.stop()
	if ambient_player:
		ambient_player.stop()
	_apply_showroom_environment()
	_set_race_hud_visible(false)
	if menu_camera:
		menu_camera.current = true
	if player_camera:
		player_camera.current = false


func _prepare_race_grid() -> void:
	showroom_root.visible = false
	_apply_track_environment()
	_set_race_hud_visible(true)
	player_track_t = 0.002
	_place_car(player, player_track_t, 1.7)
	player_previous_index = _nearest_track_index(player.global_position)
	player_progress_index = player_previous_index
	var lane_offsets := [-2.6, 2.6, -2.6, 2.6, -2.6]
	for i in ai_cars.size():
		var ai: Dictionary = ai_cars[i]
		var start_t := fposmod(1.0 - float(i + 1) * 7.4 / track_length, 1.0)
		var node: Node3D = ai["node"]
		node.visible = true
		_place_car(node, start_t, lane_offsets[i])
		ai["t"] = start_t
		ai["lap"] = -1
		ai["current_speed"] = 0.0
	menu_camera.current = false
	player_camera.current = true
	if engine_player and not engine_player.playing:
		engine_player.play()
	if engine_high_player and not engine_high_player.playing:
		engine_high_player.play()
	if ambient_player and ambient_player.stream and not ambient_player.playing:
		ambient_player.play()


func _apply_showroom_environment() -> void:
	sky_material.sky_top_color = Color("#02040a")
	sky_material.sky_horizon_color = Color("#080d18")
	sky_material.ground_bottom_color = Color("#020308")
	sky_material.ground_horizon_color = Color("#070b13")
	sky_material.sky_energy_multiplier = 0.28
	environment.ambient_light_energy = 0.42
	environment.fog_light_color = Color("#08101d")
	environment.fog_light_energy = 0.5
	environment.fog_density = 0.0015
	environment.fog_sky_affect = 0.42
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.004
	environment.volumetric_fog_albedo = Color("#0c1624")
	environment.glow_intensity = 1.45
	environment.glow_bloom = 0.28
	environment.tonemap_exposure = 1.22
	sunlight.light_color = Color("#758fff")
	sunlight.light_energy = 0.08
	fill_light.light_color = Color("#3aa8ff")
	fill_light.light_energy = 0.18


func _set_race_hud_visible(visible_state: bool) -> void:
	for node in [
		top_strip,
		place_label,
		lap_label,
		timer_label,
		speed_label,
		gear_label,
		nitro_bar,
		drift_bar,
		nitro_state_label,
		drift_state_label,
		controls_label,
		offroad_label,
		track_name_label,
		track_info_label,
		minimap,
		minimap_lap_label,
	]:
		if node:
			node.visible = visible_state


func _place_car(car: Node3D, t: float, lane_offset: float) -> void:
	var distance := fposmod(t, 1.0) * track_length
	var position := curve.sample_baked(distance, true)
	var tangent := TrackFactory.tangent_at(curve, distance, track_length)
	var side := Vector3.UP.cross(tangent).normalized()
	car.global_position = position + side * lane_offset + Vector3.UP * 0.055
	car.look_at(car.global_position + tangent, Vector3.UP)


func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 20
	add_child(hud_layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(root)

	top_strip = ColorRect.new()
	top_strip.color = Color(0.03, 0.08, 0.12, 0.68)
	top_strip.position = Vector2(24.0, 22.0)
	top_strip.size = Vector2(470.0, 94.0)
	root.add_child(top_strip)

	place_label = _make_label(root, Vector2(42.0, 34.0), Vector2(420.0, 32.0), 24, Color("#dffaff"))
	place_label.text = "P1 / 6"
	lap_label = _make_label(root, Vector2(42.0, 70.0), Vector2(420.0, 28.0), 18, Color("#a8c4cf"))
	lap_label.text = "第 1 / 2 圈"
	track_name_label = _make_label(root, Vector2.ZERO, Vector2.ZERO, 24, Color("#ffffff"))
	track_name_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	track_name_label.offset_left = -260.0
	track_name_label.offset_top = 28.0
	track_name_label.offset_right = 260.0
	track_name_label.offset_bottom = 62.0
	track_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	track_name_label.text = current_track_name
	track_info_label = _make_label(root, Vector2.ZERO, Vector2.ZERO, 15, Color("#9fdce4"))
	track_info_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	track_info_label.offset_left = -300.0
	track_info_label.offset_top = 64.0
	track_info_label.offset_right = 300.0
	track_info_label.offset_bottom = 88.0
	track_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	track_info_label.text = ""

	timer_label = _make_label(root, Vector2(0.0, 30.0), Vector2(-42.0, 34.0), 30, Color.WHITE)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	timer_label.offset_left = -340.0
	timer_label.offset_right = -42.0
	timer_label.offset_top = 28.0
	timer_label.offset_bottom = 72.0
	timer_label.text = "00:00.000"

	minimap = RaceMinimap.new()
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -344.0
	minimap.offset_top = 94.0
	minimap.offset_right = -28.0
	minimap.offset_bottom = 292.0
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(minimap)
	minimap_lap_label = _make_label(root, Vector2.ZERO, Vector2.ZERO, 15, Color("#d8f7f8"))
	minimap_lap_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap_lap_label.offset_left = -338.0
	minimap_lap_label.offset_top = 302.0
	minimap_lap_label.offset_right = -34.0
	minimap_lap_label.offset_bottom = 328.0
	minimap_lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	minimap_lap_label.text = ""

	speed_label = _make_label(root, Vector2.ZERO, Vector2.ZERO, 54, Color("#ffffff"))
	speed_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	speed_label.offset_left = 48.0
	speed_label.offset_top = -142.0
	speed_label.offset_right = 330.0
	speed_label.offset_bottom = -42.0
	speed_label.text = "000"
	gear_label = _make_label(root, Vector2.ZERO, Vector2.ZERO, 18, Color("#9edbe3"))
	gear_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	gear_label.offset_left = 222.0
	gear_label.offset_top = -88.0
	gear_label.offset_right = 350.0
	gear_label.offset_bottom = -46.0
	gear_label.text = "km/h  ·  D"

	nitro_state_label = _make_label(root, Vector2.ZERO, Vector2.ZERO, 15, Color("#ffdf75"))
	nitro_state_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	nitro_state_label.offset_left = -365.0
	nitro_state_label.offset_top = -126.0
	nitro_state_label.offset_right = -42.0
	nitro_state_label.offset_bottom = -102.0
	nitro_state_label.text = "氮气  未充能"
	nitro_bar = _make_progress(root, Color("#24d5dc"), Vector2(-365.0, -98.0), Vector2(323.0, 14.0), Control.PRESET_BOTTOM_RIGHT)
	drift_state_label = _make_label(root, Vector2.ZERO, Vector2.ZERO, 15, Color("#d9e8ec"))
	drift_state_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	drift_state_label.offset_left = -365.0
	drift_state_label.offset_top = -72.0
	drift_state_label.offset_right = -42.0
	drift_state_label.offset_bottom = -50.0
	drift_state_label.text = "漂移角度  0°"
	drift_bar = _make_progress(root, Color("#ff9c2b"), Vector2(-365.0, -44.0), Vector2(323.0, 10.0), Control.PRESET_BOTTOM_RIGHT)

	controls_label = _make_label(root, Vector2.ZERO, Vector2.ZERO, 14, Color(0.85, 0.94, 0.96, 0.86))
	controls_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls_label.offset_left = 48.0
	controls_label.offset_top = -28.0
	controls_label.offset_right = 720.0
	controls_label.offset_bottom = -8.0
	controls_label.text = "WASD 驾驶   SPACE 漂移   SHIFT 喷射氮气   R 重新开始   ESC 暂停"

	offroad_label = _make_label(root, Vector2.ZERO, Vector2.ZERO, 24, Color("#ffdf70"))
	offroad_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	offroad_label.offset_left = -260.0
	offroad_label.offset_top = 128.0
	offroad_label.offset_right = 260.0
	offroad_label.offset_bottom = 170.0
	offroad_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offroad_label.text = ""

	center_message = _make_label(root, Vector2.ZERO, Vector2.ZERO, 118, Color.WHITE)
	center_message.set_anchors_preset(Control.PRESET_CENTER)
	center_message.offset_left = -210.0
	center_message.offset_top = -130.0
	center_message.offset_right = 210.0
	center_message.offset_bottom = 80.0
	center_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_message.text = ""

	start_overlay = ColorRect.new()
	start_overlay.color = Color(0.018, 0.045, 0.065, 0.25)
	start_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(start_overlay)
	var title := _make_label(start_overlay, Vector2.ZERO, Vector2.ZERO, 68, Color.WHITE)
	title.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	title.offset_left = 54.0
	title.offset_top = -310.0
	title.offset_right = 700.0
	title.offset_bottom = -220.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.text = "Q版氮气竞速"
	var subtitle := _make_label(start_overlay, Vector2.ZERO, Vector2.ZERO, 23, Color("#8ce5ee"))
	subtitle.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	subtitle.offset_left = 58.0
	subtitle.offset_top = -206.0
	subtitle.offset_right = 700.0
	subtitle.offset_bottom = -168.0
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.text = "选择赛道后按 Enter 发车"
	for index in 3:
		var option := _make_label(start_overlay, Vector2.ZERO, Vector2.ZERO, 22, Color("#c8eef1"))
		option.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		option.offset_left = 58.0
		option.offset_top = -154.0 + float(index) * 39.0
		option.offset_right = 700.0
		option.offset_bottom = -115.0 + float(index) * 39.0
		option.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		track_option_labels.append(option)
	var start_prompt := _make_label(start_overlay, Vector2.ZERO, Vector2.ZERO, 32, Color("#ffd968"))
	start_prompt.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	start_prompt.offset_left = 58.0
	start_prompt.offset_top = -54.0
	start_prompt.offset_right = 760.0
	start_prompt.offset_bottom = 10.0
	start_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	start_prompt.text = "1 / 2 / 3 选择赛道 · ENTER 发车"

	pause_overlay = _make_modal_overlay(root, "比赛已暂停", "按 ESC 返回赛道")
	pause_overlay.visible = false
	finish_overlay = ColorRect.new()
	finish_overlay.color = Color(0.018, 0.045, 0.065, 0.9)
	finish_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	finish_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finish_overlay.visible = false
	root.add_child(finish_overlay)
	var finish_title := _make_label(finish_overlay, Vector2.ZERO, Vector2.ZERO, 62, Color.WHITE)
	finish_title.set_anchors_preset(Control.PRESET_CENTER)
	finish_title.offset_left = -430.0
	finish_title.offset_top = -170.0
	finish_title.offset_right = 430.0
	finish_title.offset_bottom = -80.0
	finish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_title.text = "比赛完成"
	finish_place_label = _make_label(finish_overlay, Vector2.ZERO, Vector2.ZERO, 46, Color("#ffd45d"))
	finish_place_label.set_anchors_preset(Control.PRESET_CENTER)
	finish_place_label.offset_left = -400.0
	finish_place_label.offset_top = -52.0
	finish_place_label.offset_right = 400.0
	finish_place_label.offset_bottom = 28.0
	finish_place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_place_label.text = "第 1 名"
	finish_time_label = _make_label(finish_overlay, Vector2.ZERO, Vector2.ZERO, 28, Color("#c8eef1"))
	finish_time_label.set_anchors_preset(Control.PRESET_CENTER)
	finish_time_label.offset_left = -400.0
	finish_time_label.offset_top = 54.0
	finish_time_label.offset_right = 400.0
	finish_time_label.offset_bottom = 100.0
	finish_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_time_label.text = "总用时 00:00.000"
	finish_prompt_label = _make_label(finish_overlay, Vector2.ZERO, Vector2.ZERO, 20, Color("#9bc2c8"))
	finish_prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	finish_prompt_label.offset_left = -400.0
	finish_prompt_label.offset_top = 150.0
	finish_prompt_label.offset_right = 400.0
	finish_prompt_label.offset_bottom = 194.0
	finish_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_prompt_label.text = "按 R 重新开始 · 按 T 选择赛道"


func _refresh_track_menu() -> void:
	if not track_name_label:
		return
	var descriptor: Dictionary = track_catalog[current_track_index]
	var theme_color: Color = descriptor["theme_color"]
	track_name_label.text = String(descriptor["name"])
	track_name_label.add_theme_color_override("font_color", theme_color)
	track_info_label.text = "%s · %d 圈 · 当前圈目标 %.0f 秒" % [
		String(descriptor["subtitle"]),
		total_laps,
		float(descriptor["lap_time"]),
	]
	for index in track_option_labels.size():
		var option_descriptor: Dictionary = track_catalog[index]
		var selected := index == current_track_index
		var option = track_option_labels[index]
		option.text = "%s  %d. %s  ·  %s" % [
			"▶" if selected else " ",
			index + 1,
			String(option_descriptor["name"]),
			String(option_descriptor["subtitle"]),
		]
		option.add_theme_color_override(
			"font_color",
			option_descriptor["theme_color"] if selected else Color("#7898a0")
		)


func _configure_minimap() -> void:
	if not minimap or track_samples.is_empty():
		return
	var colors: Array[Color] = []
	for ai in ai_cars:
		colors.append(ai["color"])
	minimap.configure(track_samples, track_data["shortcuts"], colors)


func _make_label(parent: Node, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.015, 0.03, 0.045, 0.95))
	label.add_theme_constant_override("outline_size", 8)
	parent.add_child(label)
	return label


func _make_progress(
		parent: Node,
		color: Color,
		position: Vector2,
		size: Vector2,
		preset: int
	) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.set_anchors_preset(preset)
	bar.offset_left = position.x
	bar.offset_top = position.y
	bar.offset_right = position.x + size.x
	bar.offset_bottom = position.y + size.y
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.02, 0.07, 0.09, 0.72)
	background.corner_radius_top_left = 2
	background.corner_radius_top_right = 2
	background.corner_radius_bottom_left = 2
	background.corner_radius_bottom_right = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar


func _make_modal_overlay(parent: Node, title_text: String, subtitle_text: String) -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.018, 0.045, 0.065, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	var title := _make_label(overlay, Vector2.ZERO, Vector2.ZERO, 62, Color.WHITE)
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -400.0
	title.offset_top = -74.0
	title.offset_right = 400.0
	title.offset_bottom = 0.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = title_text
	var subtitle := _make_label(overlay, Vector2.ZERO, Vector2.ZERO, 24, Color("#9fdfe7"))
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -400.0
	subtitle.offset_top = 36.0
	subtitle.offset_right = 400.0
	subtitle.offset_bottom = 82.0
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = subtitle_text
	return overlay


func _setup_audio() -> void:
	var engine_stream: AudioStreamWAV = load("res://assets/audio/engine.wav")
	engine_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	engine_stream.loop_begin = 0
	var bytes_per_frame := 4 if engine_stream.stereo else 2
	engine_stream.loop_end = maxi(1, engine_stream.data.size() / bytes_per_frame - 1)
	engine_player = AudioStreamPlayer.new()
	engine_player.stream = engine_stream
	engine_player.volume_db = -15.0
	add_child(engine_player)
	engine_high_player = AudioStreamPlayer.new()
	engine_high_player.stream = engine_stream
	engine_high_player.volume_db = -22.0
	engine_high_player.pitch_scale = 1.8
	add_child(engine_high_player)
	ambient_player = AudioStreamPlayer.new()
	ambient_player.volume_db = -24.0
	add_child(ambient_player)
	for impact_path in [
		"res://assets/audio/impact_1.wav",
		"res://assets/audio/impact_2.wav",
		"res://assets/audio/impact_3.wav",
	]:
		var impact_player := AudioStreamPlayer.new()
		impact_player.stream = load(impact_path)
		impact_player.volume_db = -8.0
		add_child(impact_player)
		impact_players.append(impact_player)
	_update_ambient_for_track()


func _update_ambient_for_track() -> void:
	if not ambient_player:
		return
	var path := "res://assets/audio/ambient_night.ogg"
	ambient_player.pitch_scale = 1.0
	if current_track_id == "snow":
		path = "res://assets/audio/ambient_day.ogg"
		ambient_player.pitch_scale = 0.82
	elif current_track_id == "loop":
		path = "res://assets/audio/ambient_day.ogg"
		ambient_player.pitch_scale = 0.94
	var stream := load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	ambient_player.stream = stream
	ambient_player.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if race_state == "paused":
				race_state = "racing"
				pause_overlay.visible = false
			elif race_state != "waiting" and race_state != "finished":
				race_state = "paused"
				pause_overlay.visible = true
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_R:
			_reset_race()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_T and (race_state == "finished" or race_state == "paused"):
			_reset_race()
			start_overlay.visible = true
			_refresh_track_menu()
			get_viewport().set_input_as_handled()
			return
		if race_state == "waiting":
			if event.keycode in [KEY_1, KEY_2, KEY_3]:
				_load_track(event.keycode - KEY_1)
				get_viewport().set_input_as_handled()
				return
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
				_prepare_race_grid()
				race_state = "countdown"
				countdown_time = 3.55
				last_countdown_value = 4
				start_overlay.visible = false
				get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if race_state == "waiting" or race_state == "paused":
		_update_camera_idle(delta)
		return
	if race_state == "countdown":
		countdown_time -= delta
		if countdown_time <= 0.0:
			race_state = "racing"
			center_message.text = "GO!"
			center_message.modulate.a = 1.0
		else:
			var countdown_value := int(ceil(countdown_time))
			if countdown_value != last_countdown_value:
				last_countdown_value = countdown_value
				center_message.text = str(countdown_value)
				center_message.modulate.a = 1.0
		_update_ai(delta, true)
		_update_camera_idle(delta)
		return
	if race_state == "finished":
		_update_ai(delta, false)
		_update_camera_idle(delta)
		return

	race_time += delta
	_update_player(delta)
	_update_ai(delta, false)
	_update_race_place()
	_update_camera(delta)


func _update_player(delta: float) -> void:
	var throttle := 0.0
	var steering := 0.0
	if Input.is_key_pressed(KEY_W):
		throttle += 1.0
	if Input.is_key_pressed(KEY_S):
		throttle -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steering += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steering -= 1.0
	player_steering = lerpf(player_steering, steering, 1.0 - exp(-9.5 * delta))
	var drift_held := Input.is_key_pressed(KEY_SPACE)
	var shift_held := Input.is_key_pressed(KEY_SHIFT)

	var forward := -player.global_transform.basis.z
	var right := player.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	player_forward_speed = player_velocity.dot(forward)
	player_lateral_speed = player_velocity.dot(right)

	var boost_active := player_nitro_time > 0.0
	var maximum_speed := BOOST_MAX_SPEED if boost_active else BASE_MAX_SPEED
	if throttle > 0.0:
		if player_forward_speed < -1.0:
			player_forward_speed += 30.0 * delta
		else:
			var speed_ratio := clampf(absf(player_forward_speed) / maximum_speed, 0.0, 1.0)
			var engine_force := lerpf(25.0, 8.0, speed_ratio)
			if boost_active:
				engine_force += 22.0
			player_forward_speed += engine_force * delta
	elif throttle < 0.0:
		if player_forward_speed > 1.0:
			player_forward_speed -= 42.0 * delta
		else:
			player_forward_speed -= 18.0 * delta
	else:
		player_forward_speed *= exp(-0.58 * delta)

	var nearest := _nearest_track_point(player.global_position, player_progress_index)
	player_in_shortcut = _is_in_shortcut(player.global_position)
	var is_offroad: bool = (
		not player_in_shortcut
		and float(nearest["distance"]) > road_half_width + 0.7
	)
	player_offroad = is_offroad
	if is_offroad and player_forward_speed > 15.0:
		player_forward_speed *= exp(-2.5 * delta)
		player_forward_speed = minf(player_forward_speed, 16.0)

	var drifting := (
		drift_held
		and absf(player_forward_speed) > 10.0
		and (absf(player_steering) > 0.18 or player_drift_angle > 0.10)
	)
	player_drifting = drifting
	var lateral_grip := 2.35 if drifting else 9.2
	if drifting:
		if absf(player_forward_speed) > 5.0:
			player_lateral_speed += player_steering * absf(player_forward_speed) * 1.16 * delta
			player_forward_speed *= exp(-0.18 * delta)
	else:
		player_lateral_speed *= exp(-lateral_grip * delta)
	player_lateral_speed *= exp(-lateral_grip * delta)
	var lateral_limit := 12.0 if drifting else 6.5
	player_lateral_speed = clampf(player_lateral_speed, -lateral_limit, lateral_limit)
	player_drift_angle = absf(atan2(player_lateral_speed, maxf(absf(player_forward_speed), 1.0)))
	var charge_speed_ratio := clampf(absf(player_forward_speed) / BASE_MAX_SPEED, 0.0, 1.0)
	var passive_charge := 2.8 * charge_speed_ratio
	if drifting:
		passive_charge += 20.0 + minf(player_drift_angle, 0.65) * 92.0
	elif player_drift_angle > 0.08 and absf(player_forward_speed) > 7.0:
		passive_charge += 8.0 + minf(player_drift_angle, 0.45) * 52.0
	if absf(player_forward_speed) > 5.0:
		player_drift_charge = minf(100.0, player_drift_charge + passive_charge * delta)
	else:
		player_drift_charge = maxf(0.0, player_drift_charge - delta * 1.8)

	var can_turn := absf(player_forward_speed) > 0.8
	if can_turn:
		var reverse_sign := -1.0 if player_forward_speed < 0.0 else 1.0
		var speed_ratio := clampf(absf(player_forward_speed) / BASE_MAX_SPEED, 0.0, 1.0)
		var steering_authority := lerpf(0.48, 0.90, speed_ratio)
		var turn_speed := lerpf(0.92, 1.28, speed_ratio)
		if absf(player_forward_speed) > 26.0:
			turn_speed *= 0.90
		if drifting:
			steering_authority *= 1.12
			turn_speed *= 1.16
		var turn_amount := player_steering * turn_speed * steering_authority * reverse_sign * delta
		player.rotate_y(turn_amount)

	forward = -player.global_transform.basis.z
	right = player.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	if shift_held and player_drift_charge >= 10.0 and player_nitro_time <= 0.0:
		player_nitro_time = clampf(0.85 + player_drift_charge / 58.0, 0.85, 2.25)
		player_drift_charge = maxf(0.0, player_drift_charge - 24.0)
	nitro_requested = player_nitro_time > 0.0
	if player_nitro_time > 0.0:
		player_nitro_time -= delta
		player_drift_charge = maxf(0.0, player_drift_charge - delta * 5.5)

	player_forward_speed = clampf(player_forward_speed, -13.0, maximum_speed + 2.0)
	if player_in_shortcut:
		player_forward_speed = minf(player_forward_speed, maximum_speed * 0.90)
	player_velocity = forward * player_forward_speed + right * player_lateral_speed
	player.global_position += player_velocity * delta
	if player_in_shortcut:
		var shortcut_info := _nearest_shortcut_sample(player.global_position)
		var target_shortcut_y: float = shortcut_info["center"].y + 0.15
		player.global_position.y = lerpf(player.global_position.y, target_shortcut_y, 1.0 - exp(-22.0 * delta))
	else:
		var target_track_y := curve.sample_baked(fposmod(player_track_t, 1.0) * track_length, true).y + 0.055
		player.global_position.y = lerpf(player.global_position.y, target_track_y, 1.0 - exp(-24.0 * delta))

	_resolve_player_boundary(nearest)
	_resolve_ai_contact()

	player_progress_index = _nearest_track_index(player.global_position)
	if player_previous_index > int(track_samples.size() * 0.8) and player_progress_index < int(track_samples.size() * 0.2):
		player_lap += 1
		if player_lap >= total_laps:
			_finish_race()
	elif player_previous_index < int(track_samples.size() * 0.2) and player_progress_index > int(track_samples.size() * 0.8):
		player_lap = maxi(0, player_lap - 1)
	player_previous_index = player_progress_index
	player_track_t = float(player_progress_index) / float(track_samples.size())

	front_wheel_spin += player_forward_speed * delta * 2.8
	var wheel_steer := player_steering * 0.42
	var all_wheels: Array = player.get_meta("all_wheels")
	for wheel in all_wheels:
		wheel.rotation = Vector3(
			front_wheel_spin,
			wheel_steer if wheel.position.z < 0.0 else 0.0,
			0.0
		)

	var body := player.get_child(0)
	var visual_roll := -player_steering * (0.055 if drifting else 0.024)
	body.rotation.z = lerpf(body.rotation.z, visual_roll, 1.0 - exp(-7.0 * delta))
	var braking_pitch := 0.018 if throttle < 0.0 else -0.012 * clampf(player_forward_speed / BASE_MAX_SPEED, 0.0, 1.0)
	var slope_pitch := asin(clampf(track_tangents[player_progress_index].y, -0.55, 0.55))
	body.rotation.x = lerpf(body.rotation.x, braking_pitch + slope_pitch, 1.0 - exp(-5.0 * delta))
	var brake_material: StandardMaterial3D = player.get_meta("brake_material")
	var braking := throttle < 0.0 or (drift_held and absf(player_forward_speed) > 10.0)
	var target_brake_energy := 4.2 if braking else 1.15
	brake_material.emission_energy_multiplier = lerpf(
		brake_material.emission_energy_multiplier,
		target_brake_energy,
		1.0 - exp(-9.0 * delta)
	)

	offroad_label.visible = is_offroad or player_in_shortcut
	if player_in_shortcut:
		offroad_label.text = "捷径路段 · 窄路限速"
	elif is_offroad:
		offroad_label.text = "偏离赛道 · 抓地力下降"


func _update_ai(delta: float, countdown: bool) -> void:
	for ai in ai_cars:
		var node: Node3D = ai["node"]
		var old_t: float = ai["t"]
		var curve_index := clampi(int(float(old_t) * track_samples.size()), 0, track_samples.size() - 1)
		var tangent := track_tangents[curve_index]
		var next_index := (curve_index + 7) % track_samples.size()
		var future_tangent := track_tangents[next_index]
		var turn_factor := 1.0 - clampf(tangent.dot(future_tangent), -1.0, 1.0)
		var target_speed: float = float(ai["base_speed"]) * (1.0 - turn_factor * 1.15)
		target_speed = maxf(18.0, target_speed)
		if countdown:
			target_speed = 0.0
		var current_speed: float = ai["current_speed"]
		current_speed = lerpf(current_speed, target_speed, 1.0 - exp(-1.8 * delta))
		ai["current_speed"] = current_speed
		var new_t := fposmod(float(old_t) + current_speed * delta / track_length, 1.0)
		ai["t"] = new_t
		if float(old_t) > 0.8 and new_t < 0.2:
			ai["lap"] = int(ai["lap"]) + 1

		var distance := new_t * track_length
		var center := curve.sample_baked(distance, true)
		var new_tangent := TrackFactory.tangent_at(curve, distance, track_length)
		var side := Vector3.UP.cross(new_tangent).normalized()
		var lane_wave := sin(race_time * 0.48 + float(ai["lane_phase"])) * 0.65
		var target_position := center + side * (float(ai["lane"]) + lane_wave)
		target_position.y += 0.055
		node.global_position = node.global_position.lerp(target_position, 1.0 - exp(-9.0 * delta))
		var look_target := curve.sample_baked(fposmod(distance + 4.5, track_length), true)
		node.look_at(look_target + Vector3.UP * 0.055, Vector3.UP)

		var body := node.get_child(0)
		body.rotation.z = lerpf(body.rotation.z, -clampf(turn_factor * 2.4, -0.11, 0.11), 1.0 - exp(-4.0 * delta))
		var all_wheels: Array = node.get_meta("all_wheels")
		for wheel in all_wheels:
			if wheel.position.z < 0.0:
				wheel.rotation.y = clampf(turn_factor * 1.8, -0.34, 0.34)
		ai["total"] = float(ai["lap"]) * track_samples.size() + float(curve_index)


func _resolve_player_boundary(nearest: Dictionary) -> void:
	if player_in_shortcut:
		return
	if float(nearest["distance"]) <= offroad_limit:
		return
	var center: Vector3 = nearest["center"]
	var side: Vector3 = nearest["side"]
	var signed_distance := (player.global_position - center).dot(side)
	var direction := signf(signed_distance)
	if absf(direction) < 0.01:
		direction = 1.0
	player.global_position = center + side * direction * (offroad_limit - 0.08)
	if impact_cooldown <= 0.0 and player_velocity.length() > 6.0 and not impact_players.is_empty():
		var impact := impact_players[randi() % impact_players.size()]
		impact.pitch_scale = randf_range(0.88, 1.12)
		impact.play()
		impact_cooldown = 0.72
	player_velocity *= -0.16
	player_lateral_speed *= -0.22
	player_forward_speed *= 0.55


func _is_in_shortcut(position: Vector3) -> bool:
	for shortcut_index in shortcut_samples.size():
		var points := shortcut_samples[shortcut_index]
		var width := shortcut_widths[shortcut_index] + 0.75
		for point_index in range(points.size() - 1):
			var distance := _distance_to_segment_2d(
				Vector2(position.x, position.z),
				Vector2(points[point_index].x, points[point_index].z),
				Vector2(points[point_index + 1].x, points[point_index + 1].z)
			)
			if distance <= width:
				return true
	return false


func _nearest_shortcut_sample(position: Vector3) -> Dictionary:
	var best_index := 0
	var best_shortcut := 0
	var best_point := 0
	var best_interpolation := 0.0
	var best_distance := INF
	for shortcut_index in shortcut_samples.size():
		var points := shortcut_samples[shortcut_index]
		for point_index in range(points.size() - 1):
			var point_a := Vector2(points[point_index].x, points[point_index].z)
			var point_b := Vector2(points[point_index + 1].x, points[point_index + 1].z)
			var distance_info := _segment_projection_2d(Vector2(position.x, position.z), point_a, point_b)
			var distance: float = distance_info["distance_squared"]
			if distance < best_distance:
				best_distance = distance
				best_shortcut = shortcut_index
				best_point = point_index
				best_interpolation = float(distance_info["interpolation"])
	var shortcut_points := shortcut_samples[best_shortcut]
	var tangents := shortcut_tangents[best_shortcut]
	best_index = best_point
	var tangent := tangents[best_index]
	return {
		"index": best_index,
		"center": shortcut_points[best_index].lerp(shortcut_points[best_index + 1], best_interpolation),
		"side": Vector3.UP.cross(tangent).normalized(),
		"tangent": tangent,
	}


func _distance_to_segment_2d(point: Vector2, point_a: Vector2, point_b: Vector2) -> float:
	return sqrt(float(_segment_projection_2d(point, point_a, point_b)["distance_squared"]))


func _segment_projection_2d(point: Vector2, point_a: Vector2, point_b: Vector2) -> Dictionary:
	var segment := point_b - point_a
	var segment_length_squared := segment.length_squared()
	var interpolation := 0.0
	if segment_length_squared > 0.0001:
		interpolation = clampf((point - point_a).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest := point_a + segment * interpolation
	return {
		"distance_squared": point.distance_squared_to(closest),
		"interpolation": interpolation,
	}


func _resolve_ai_contact() -> void:
	for ai in ai_cars:
		var ai_node: Node3D = ai["node"]
		var offset := player.global_position - ai_node.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance < 1.48:
			var push_direction := offset.normalized() if distance > 0.04 else Vector3.RIGHT
			player.global_position += push_direction * (1.48 - distance) * 0.55
			player_velocity += push_direction * 2.2


func _nearest_track_index(position: Vector3) -> int:
	return int(_nearest_track_point(position, -1)["index"])


func _nearest_track_point(position: Vector3, guess: int) -> Dictionary:
	var best_index := 0
	var best_distance := INF
	var start_index := 0
	var end_index := track_samples.size()
	if guess >= 0:
		start_index = guess - 34
		end_index = guess + 34
	for i in range(start_index, end_index):
		var index := posmod(i, track_samples.size())
		var distance := position.distance_squared_to(track_samples[index])
		if distance < best_distance:
			best_distance = distance
			best_index = index
	if guess >= 0:
		# Verify against a sparse full-track pass to catch teleports or missed checkpoints.
		for i in range(0, track_samples.size(), 7):
			var distance := position.distance_squared_to(track_samples[i])
			if distance < best_distance:
				best_distance = distance
				best_index = i
	var tangent := track_tangents[best_index]
	var side := Vector3.UP.cross(tangent).normalized()
	return {
		"index": best_index,
		"distance": sqrt(best_distance),
		"center": track_samples[best_index],
		"side": side,
	}


func _update_race_place() -> void:
	var player_total := float(player_lap) * track_samples.size() + float(player_progress_index)
	var place := 1
	for ai in ai_cars:
		ai["total"] = float(ai["lap"]) * track_samples.size() + float(int(float(ai["t"]) * track_samples.size()))
		if float(ai["total"]) > player_total:
			place += 1
	player_place = place


func _update_camera(delta: float) -> void:
	if not player_camera:
		return
	var target_fov := 80.0 if nitro_requested else 76.0
	target_fov += clampf(absf(player_forward_speed) / BASE_MAX_SPEED, 0.0, 1.0) * 4.0
	player_camera.fov = lerpf(player_camera.fov, target_fov, 1.0 - exp(-5.0 * delta))
	var shake_strength := 0.006
	if player_drift_angle > 0.18:
		shake_strength += minf(player_drift_angle * 0.025, 0.014)
	if nitro_requested:
		shake_strength += 0.015
	var shake := Vector3(
		sin(race_time * 53.0) * shake_strength,
		sin(race_time * 67.0) * shake_strength * 0.62,
		0.0
	)
	player_camera.position = player_camera.position.lerp(camera_base_position + shake, 1.0 - exp(-18.0 * delta))


func _update_camera_idle(delta: float) -> void:
	if not player_camera:
		return
	player_camera.position = player_camera.position.lerp(camera_base_position, 1.0 - exp(-8.0 * delta))


func _update_menu_camera() -> void:
	if not menu_camera or not player:
		return
	var angle := -1.72
	var focus := player.global_position + Vector3.UP * 0.78
	menu_camera.global_position = focus + Vector3(cos(angle) * 4.8, 2.10, sin(angle) * 4.8)
	menu_camera.look_at(focus, Vector3.UP)


func _process(delta: float) -> void:
	impact_cooldown = maxf(0.0, impact_cooldown - delta)
	if race_state == "waiting":
		_update_menu_camera()
	if minimap and race_state != "waiting":
		var ai_positions: Array[Vector3] = []
		for ai in ai_cars:
			ai_positions.append(ai["node"].global_position)
		minimap.update_racers(player.global_position, -player.global_transform.basis.z, ai_positions)
		minimap_lap_label.text = "第 %d / %d 圈 · 橙色为捷径" % [
			mini(player_lap + 1, total_laps),
			total_laps,
		]
	if center_message and center_message.modulate.a > 0.0:
		center_message.modulate.a = maxf(0.0, center_message.modulate.a - delta * 0.42)
	if speed_label:
		var speed_kph := int(round(absf(player_forward_speed) * 3.6))
		speed_label.text = "%03d" % speed_kph
		gear_label.text = "km/h  ·  R" if player_forward_speed < -0.8 else "km/h  ·  D"
	if lap_label:
		lap_label.text = "第 %d / %d 圈" % [mini(player_lap + 1, total_laps), total_laps]
	if place_label:
		place_label.text = "P%d / %d" % [player_place, ai_cars.size() + 1]
	if timer_label:
		timer_label.text = _format_time(race_time if not player_finished else player_finish_time)
	if nitro_bar:
		nitro_bar.value = player_drift_charge
	if drift_bar:
		drift_bar.value = clampf(player_drift_angle / 0.7 * 100.0, 0.0, 100.0)
	if nitro_state_label and drift_state_label:
		if player_nitro_time > 0.0:
			nitro_state_label.text = "氮气  喷射中"
			nitro_state_label.add_theme_color_override("font_color", Color("#ff9c35"))
		elif player_drift_charge >= 10.0:
			nitro_state_label.text = "氮气  可按 SHIFT 释放"
			nitro_state_label.add_theme_color_override("font_color", Color("#ffe47b"))
		else:
			nitro_state_label.text = "氮气  高速巡航 / 漂移充能"
			nitro_state_label.add_theme_color_override("font_color", Color("#a9c4ca"))
		drift_state_label.text = "漂移角度  %d°" % int(round(rad_to_deg(player_drift_angle)))
	_update_boost_visuals()
	_update_particle_effects()
	_update_engine_audio()


func _update_boost_visuals() -> void:
	if not player:
		return
	var flame_visible := player_nitro_time > 0.0
	var flames: Array = player.get_meta("boost_flames")
	for flame in flames:
		flame.visible = flame_visible
		if flame_visible:
			flame.scale = Vector3(0.75, 0.42, 2.0 + sin(race_time * 35.0) * 0.45)


func _update_particle_effects() -> void:
	if not player or not player.has_meta("smoke_emitters"):
		return
	var smoke_emitters: Array = player.get_meta("smoke_emitters")
	var emitting := race_state == "racing" and (
		player_drifting
		or (player_offroad and absf(player_forward_speed) > 8.0)
	)
	for emitter in smoke_emitters:
		emitter.emitting = emitting


func _update_engine_audio() -> void:
	if not engine_player or not engine_high_player:
		return
	var speed_ratio := clampf(absf(player_forward_speed) / BASE_MAX_SPEED, 0.0, 1.0)
	var target_pitch := 0.72 + speed_ratio * 1.28
	if player_nitro_time > 0.0:
		target_pitch += 0.18
	engine_player.pitch_scale = lerpf(engine_player.pitch_scale, target_pitch, 0.055)
	engine_high_player.pitch_scale = lerpf(engine_high_player.pitch_scale, 1.42 + speed_ratio * 1.55, 0.045)
	var base_volume := -23.0
	if race_state == "racing":
		base_volume = lerpf(-15.0, -7.5, speed_ratio)
	engine_player.volume_db = lerpf(engine_player.volume_db, base_volume, 0.08)
	engine_high_player.volume_db = lerpf(
		engine_high_player.volume_db,
		-19.0 + speed_ratio * 7.0,
		0.07
	)


func _finish_race() -> void:
	player_finished = true
	race_state = "finished"
	player_finish_time = race_time
	_update_race_place()
	finish_place_label.text = "第 %d 名" % player_place
	finish_time_label.text = "总用时 %s" % _format_time(player_finish_time)
	finish_overlay.visible = true


func _format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var remaining := fmod(seconds, 60.0)
	return "%02d:%06.3f" % [minutes, remaining]


func _reset_race_state() -> void:
	race_state = "waiting"
	race_time = 0.0
	countdown_time = 3.6
	last_countdown_value = 4
	player_lap = 0
	player_finished = false
	player_finish_time = 0.0
	player_velocity = Vector3.ZERO
	player_forward_speed = 0.0
	player_lateral_speed = 0.0
	player_steering = 0.0
	player_drift_angle = 0.0
	player_drift_charge = 20.0
	player_nitro_time = 0.0
	player_place = 1
	player_track_t = 0.002
	impact_cooldown = 0.0
	if menu_camera:
		menu_camera.current = true
	if player_camera:
		player_camera.current = false


func _reset_race() -> void:
	_reset_race_state()
	_enter_showroom()
	start_overlay.visible = true
	pause_overlay.visible = false
	finish_overlay.visible = false
	center_message.text = ""
	_update_race_place()
