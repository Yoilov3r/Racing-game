extends Node3D

const DrivingTuningConfig = preload("res://scripts/driving_tuning.gd")
const RaceHudWidgets = preload("res://scripts/race_hud_widgets.gd")
const RaceAudioDirectorConfig = preload("res://scripts/race_audio_director.gd")
const CAR_CONTACT_RADIUS := 1.48
const RUBBER_BAND_LIMIT := 0.06
const AI_BRAKE_DECEL := 12.5
const AI_PROFILES := [
	{
		"id": "steady",
		"name": "稳健 · 岚",
		"speed": 0.95,
		"corner": 0.98,
		"aggression": 0.24,
		"drift": 0.12,
		"mistake": 0.12,
		"reaction": 0.26,
		"line_bias": -0.35,
	},
	{
		"id": "aggressive",
		"name": "激进 · 赤锋",
		"speed": 1.01,
		"corner": 1.04,
		"aggression": 0.94,
		"drift": 0.38,
		"mistake": 0.34,
		"reaction": 0.12,
		"line_bias": 0.28,
	},
	{
		"id": "drift",
		"name": "漂移 · 白刃",
		"speed": 0.97,
		"corner": 0.96,
		"aggression": 0.58,
		"drift": 0.96,
		"mistake": 0.48,
		"reaction": 0.20,
		"line_bias": 0.52,
	},
	{
		"id": "error_prone",
		"name": "失误 · 小满",
		"speed": 0.93,
		"corner": 0.90,
		"aggression": 0.36,
		"drift": 0.26,
		"mistake": 1.0,
		"reaction": 0.38,
		"line_bias": -0.55,
	},
	{
		"id": "opportunist",
		"name": "机会 · 追星",
		"speed": 0.99,
		"corner": 1.00,
		"aggression": 0.68,
		"drift": 0.34,
		"mistake": 0.24,
		"reaction": 0.16,
		"line_bias": 0.68,
	},
]
const DIFFICULTY_PRESETS := [
	{
		"id": "rookie",
		"name": "新手",
		"speed": 0.88,
		"corner": 0.88,
		"reaction": 1.35,
		"mistake": 1.60,
		"racecraft": 0.55,
	},
	{
		"id": "standard",
		"name": "标准",
		"speed": 0.96,
		"corner": 0.96,
		"reaction": 1.00,
		"mistake": 1.00,
		"racecraft": 0.82,
	},
	{
		"id": "expert",
		"name": "高手",
		"speed": 1.02,
		"corner": 1.02,
		"reaction": 0.78,
		"mistake": 0.70,
		"racecraft": 1.00,
	},
	{
		"id": "master",
		"name": "大师",
		"speed": 1.06,
		"corner": 1.06,
		"reaction": 0.62,
		"mistake": 0.45,
		"racecraft": 1.18,
	},
]

@export var driving_tuning: DrivingTuningConfig = DrivingTuningConfig.new()

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
var difficulty_index := 1

var track_data: Dictionary
var curve: Curve3D
var track_length := 0.0
var track_samples: PackedVector3Array
var track_tangents: PackedVector3Array
var ai_corner_offsets := PackedFloat32Array()
var ai_speed_limits := PackedFloat32Array()
var ai_shortcut_guard_offsets := PackedFloat32Array()
var ai_shortcut_entry_indices: Array[int] = []
var ai_track_curvature := PackedFloat32Array()
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
var player_yaw_rate := 0.0
var player_slip_angle := 0.0
var player_longitudinal_acceleration := 0.0
var player_lap := 0
var player_progress_index := 0
var player_previous_index := 0
var player_track_t := 0.002
var player_drift_angle := 0.0
var player_drift_charge := 0.0
var player_drifting := false
var player_drift_blend := 0.0
var player_offroad := false
var player_in_shortcut := false
var player_nitro_time := 0.0
var nitro_requested := false
var player_finished := false
var player_finish_time := 0.0
var front_wheel_spin := 0.0
var camera_base_position := Vector3(0.0, 1.58, -0.32)
var camera_base_rotation := Vector3.ZERO
var camera_collision_kick := Vector3.ZERO
var camera_collision_trauma := 0.0
var camera_acceleration_stretch := 0.0
var player_smoke_intensity := 0.0
var debug_drive_input: Dictionary = {}

var skid_marks: MultiMeshInstance3D
var skid_multimesh: MultiMesh
var skid_next_instance := 0
var skid_previous_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var skid_has_previous: Array[bool] = [false, false]

var ai_cars: Array[Dictionary] = []
var player_place := 1
var race_state := "waiting"
var countdown_time := 3.6
var race_time := 0.0
var race_elapsed_time := 0.0
var last_countdown_value := 4

var hud_layer: CanvasLayer
var hud_root: Control
var top_left_panel: Panel
var top_center_panel: Panel
var top_right_panel: Panel
var speed_panel: Panel
var aux_panel: Panel
var place_suffix_label: Label
var lap_goal_label: Label
var race_status_label: Label
var menu_state_label: Label
var menu_track_detail_label: Label
var menu_difficulty_label: Label
var menu_start_prompt: Label
var pause_summary_label: Label
var pause_controls_label: Label
var finish_summary_label: Label
var finish_stats_label: Label
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
var speed_particles: GPUParticles3D
var speed_overlay: ColorRect
var nitro_overlay: ColorRect
var speed_overlay_material: ShaderMaterial
var nitro_overlay_material: ShaderMaterial
var speed_gauge
var nitro_gauge
var drift_gauge
var countdown_lights

var engine_player: AudioStreamPlayer
var engine_high_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var impact_players: Array[AudioStreamPlayer] = []
var impact_cooldown := 0.0
var race_audio = RaceAudioDirectorConfig.new()
var top_speed_kph := 0


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
	_setup_skid_marks()
	shortcut_samples.clear()
	shortcut_tangents.clear()
	shortcut_widths.clear()
	for shortcut in track_data["shortcuts"]:
		shortcut_samples.append(shortcut["samples"])
		shortcut_tangents.append(shortcut["tangents"])
		shortcut_widths.append(float(shortcut["width"]))
	road_half_width = float(track_data["half_width"])
	offroad_limit = road_half_width + 2.25
	_build_ai_track_profile()
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
	camera_base_position = player_camera.position
	camera_base_rotation = player_camera.rotation
	_apply_visual_budget()
	player_camera.current = false
	menu_camera = Camera3D.new()
	menu_camera.name = "ShowcaseCamera"
	menu_camera.fov = 52.0
	menu_camera.current = true
	racers_root.add_child(menu_camera)
	_create_speed_particles(player_camera)
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
	for i in ai_colors.size():
		var start_t := fposmod(1.0 - float(i + 1) * 7.4 / track_length, 1.0)
		var car := CarFactory.create_car(ai_colors[i], false)
		racers_root.add_child(car)
		_place_car(car, start_t, lane_offsets[i])
		var profile: Dictionary = AI_PROFILES[i % AI_PROFILES.size()]
		var rng := RandomNumberGenerator.new()
		rng.seed = 910241 + current_track_index * 1009 + i * 7919
		var ai := {
			"node": car,
			"lap": -1,
			"profile_index": i,
			"profile": profile,
			"rng": rng,
			"velocity": Vector3.ZERO,
			"forward_speed": 0.0,
			"lateral_speed": 0.0,
			"yaw_rate": 0.0,
			"slip_angle": 0.0,
			"steering": 0.0,
			"drift_angle": 0.0,
			"drift_blend": 0.0,
			"drift_charge": 18.0,
			"drifting": false,
			"nitro_time": 0.0,
			"nitro_requested": false,
			"wheel_spin": 0.0,
			"longitudinal_acceleration": 0.0,
			"offroad": false,
			"in_shortcut": false,
			"previous_index": _nearest_track_index(car.global_position),
			"progress_index": _nearest_track_index(car.global_position),
			"search_tick": i,
			"lane": lane_offsets[i],
			"lane_phase": float(i) * 1.37,
			"pass_side": -1.0 if i % 2 == 0 else 1.0,
			"target_offset": lane_offsets[i],
			"color": ai_colors[i],
			"total": -float(track_samples.size()) + float(_nearest_track_index(car.global_position)),
			"rubber_factor": 0.0,
			"launch_timer": 0.0,
			"stuck_timer": 0.0,
			"recovery_timer": 0.0,
			"mistake_timer": rng.randf_range(8.0, 18.0),
			"mistake_time": 0.0,
			"mistake_kind": "",
			"mistake_sign": 1.0,
			"finished": false,
			"finish_time": -1.0,
			"stats": _make_ai_stats(),
		}
		ai_cars.append(ai)
	if current_track_id == "snow" and player_camera:
		_create_snow_particles(player_camera)
	elif current_track_id == "neon" and player_camera:
		_create_neon_rain(player_camera)
	_update_race_place()
	_reset_skid_emitters()


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


func _create_neon_rain(camera: Camera3D) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "NeonRain"
	particles.amount = 420
	particles.lifetime = 1.65
	particles.preprocess = 1.1
	particles.local_coords = true
	particles.position = Vector3(0.0, 9.0, -18.0)
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(36.0, 16.0, 42.0)
	process_material.direction = Vector3(0.12, -1.0, 0.08)
	process_material.spread = 7.0
	process_material.initial_velocity_min = 24.0
	process_material.initial_velocity_max = 36.0
	process_material.gravity = Vector3(0.8, -16.0, 0.0)
	process_material.scale_min = 0.55
	process_material.scale_max = 1.35
	particles.process_material = process_material
	var rain_mesh := QuadMesh.new()
	rain_mesh.size = Vector2(0.024, 1.25)
	var rain_material := CarFactory.make_material(Color(0.52, 0.90, 1.0, 0.42), 0.0, 0.2)
	rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	rain_mesh.material = rain_material
	particles.draw_pass_1 = rain_mesh
	camera.add_child(particles)


func _create_speed_particles(camera: Camera3D) -> void:
	speed_particles = GPUParticles3D.new()
	speed_particles.name = "SpeedParticles"
	speed_particles.amount = 320
	speed_particles.lifetime = 0.8
	speed_particles.local_coords = true
	speed_particles.position = Vector3(0.0, 1.5, -12.0)
	speed_particles.emitting = false
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(52.0, 18.0, 55.0)
	process_material.direction = Vector3(0.0, 0.0, 1.0)
	process_material.spread = 8.0
	process_material.initial_velocity_min = 24.0
	process_material.initial_velocity_max = 46.0
	process_material.gravity = Vector3.ZERO
	process_material.scale_min = 0.35
	process_material.scale_max = 1.25
	speed_particles.process_material = process_material
	var streak_material := CarFactory.make_material(Color(0.72, 0.92, 1.0, 0.38), 0.0, 0.25)
	streak_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var streak_mesh := QuadMesh.new()
	streak_mesh.size = Vector2(0.018, 2.2)
	streak_mesh.material = streak_material
	speed_particles.draw_pass_1 = streak_mesh
	camera.add_child(speed_particles)


func _setup_skid_marks() -> void:
	skid_multimesh = MultiMesh.new()
	skid_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var mark_mesh := PlaneMesh.new()
	mark_mesh.size = Vector2(driving_tuning.skid_mark_width, 1.0)
	mark_mesh.subdivide_width = 0
	mark_mesh.subdivide_depth = 0
	var mark_material := CarFactory.make_material(
		Color(0.035, 0.038, 0.043, 0.52),
		0.0,
		0.96
	)
	mark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mark_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mark_material.render_priority = 1
	mark_mesh.material = mark_material
	skid_multimesh.mesh = mark_mesh
	skid_multimesh.instance_count = int(driving_tuning.max_skid_segments)
	skid_multimesh.visible_instance_count = 0
	skid_marks = MultiMeshInstance3D.new()
	skid_marks.name = "TireMarks"
	skid_marks.multimesh = skid_multimesh
	skid_marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	track_root.add_child(skid_marks)
	_clear_skid_marks()


func _clear_skid_marks() -> void:
	skid_next_instance = 0
	if skid_multimesh:
		skid_multimesh.visible_instance_count = 0
	_reset_skid_emitters()


func _reset_skid_emitters() -> void:
	skid_previous_positions.fill(Vector3.ZERO)
	skid_has_previous.fill(false)


func _emit_skid_marks(throttle: float, speed_abs: float) -> void:
	var should_emit := (
		race_state == "racing"
		and not player_offroad
		and speed_abs > driving_tuning.skid_min_speed
		and (
			player_drift_blend > 0.20
			or throttle < -0.05
			or player_drift_angle > 0.12
		)
	)
	if not should_emit or not player.has_meta("all_wheels"):
		_reset_skid_emitters()
		return
	var wheels: Array = player.get_meta("all_wheels")
	if wheels.size() < 4:
		_reset_skid_emitters()
		return
	for rear_index in 2:
		var wheel: Node3D = wheels[rear_index + 2]
		var mark_position := wheel.global_position + Vector3.DOWN * 0.39
		if not skid_has_previous[rear_index]:
			skid_previous_positions[rear_index] = mark_position
			skid_has_previous[rear_index] = true
			continue
		var previous := skid_previous_positions[rear_index]
		var segment := mark_position - previous
		var segment_length := segment.length()
		if segment_length < driving_tuning.skid_segment_length:
			continue
		if segment_length <= 2.0:
			_add_skid_segment(previous, mark_position, segment_length)
		skid_previous_positions[rear_index] = mark_position


func _add_skid_segment(point_a: Vector3, point_b: Vector3, segment_length: float) -> void:
	if not skid_multimesh or segment_length <= 0.001:
		return
	var direction := (point_b - point_a) / segment_length
	var basis := Basis.looking_at(direction, Vector3.UP)
	basis = basis.scaled(Vector3(1.0, 1.0, segment_length))
	var transform := Transform3D(basis, (point_a + point_b) * 0.5)
	skid_multimesh.set_instance_transform(skid_next_instance, transform)
	skid_next_instance = (skid_next_instance + 1) % int(driving_tuning.max_skid_segments)
	skid_multimesh.visible_instance_count = mini(
		skid_multimesh.visible_instance_count + 1,
		int(driving_tuning.max_skid_segments)
	)


func _smooth_value(current: float, target: float, rate: float, delta: float) -> float:
	return lerpf(current, target, 1.0 - exp(-maxf(rate, 0.0) * delta))


func _drive_key_pressed(keycode: int, override_name: String) -> bool:
	if not debug_drive_input.is_empty():
		return bool(debug_drive_input.get(override_name, false))
	return Input.is_key_pressed(keycode)


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
			environment.ssao_enabled = true
			environment.ssr_enabled = true
			sunlight.light_color = Color("#8fb8ff")
			sunlight.light_energy = 0.52
			fill_light.light_color = Color("#3f79ff")
			fill_light.light_energy = 0.24
		"snow":
			sky_material.sky_top_color = Color("#4f86b3")
			sky_material.sky_horizon_color = Color("#d0e7ed")
			sky_material.ground_bottom_color = Color("#7f99a5")
			sky_material.ground_horizon_color = Color("#c5d7dc")
			sky_material.sky_energy_multiplier = 0.92
			environment.ambient_light_energy = 0.66
			environment.fog_light_color = Color("#bacfd7")
			environment.fog_light_energy = 0.82
			environment.fog_density = 0.00185
			environment.fog_sky_affect = 0.50
			environment.volumetric_fog_enabled = true
			environment.volumetric_fog_density = 0.0041
			environment.volumetric_fog_albedo = Color("#cfe0e6")
			environment.glow_intensity = 0.50
			environment.glow_bloom = 0.085
			environment.tonemap_exposure = 0.86
			environment.ssao_enabled = true
			environment.ssr_enabled = false
			sunlight.light_color = Color("#eaf4ff")
			sunlight.light_energy = 0.94
			fill_light.light_color = Color("#a8d3ff")
			fill_light.light_energy = 0.19
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
			environment.volumetric_fog_enabled = false
			environment.volumetric_fog_density = 0.0
			environment.volumetric_fog_albedo = Color("#d7e9eb")
			environment.glow_intensity = 0.72
			environment.glow_bloom = 0.14
			environment.tonemap_exposure = 0.92
			environment.ssao_enabled = false
			environment.ssr_enabled = false
			sunlight.light_color = Color("#fff0d0")
			sunlight.light_energy = 0.88
			fill_light.light_color = Color("#a7d5ff")
			fill_light.light_energy = 0.20
	_apply_visual_budget()


func _apply_visual_budget() -> void:
	var budget := TrackFactory.get_quality_budget(current_track_id)
	if player_camera:
		player_camera.far = float(budget["camera_far"])
	sunlight.directional_shadow_max_distance = float(budget["shadow_distance"])
	environment.ssr_max_steps = 40 if current_track_id == "neon" else 24


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
	player_forward_speed = 0.0
	player_lateral_speed = 0.0
	player_drift_blend = 0.0
	player_drifting = false
	player_smoke_intensity = 0.0
	_clear_skid_marks()
	if race_audio:
		race_audio.set_race_active(false)
		race_audio.reset_events()
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
	race_elapsed_time = 0.0
	player_track_t = 0.002
	_place_car(player, player_track_t, 1.7)
	_clear_skid_marks()
	player_previous_index = _nearest_track_index(player.global_position)
	player_progress_index = player_previous_index
	var lane_offsets := [-2.6, 2.6, -2.6, 2.6, -2.6]
	for i in ai_cars.size():
		var ai: Dictionary = ai_cars[i]
		var start_t := fposmod(1.0 - float(i + 1) * 7.4 / track_length, 1.0)
		var node: Node3D = ai["node"]
		node.visible = true
		_place_car(node, start_t, lane_offsets[i])
		_reset_ai_driver_state(ai, start_t, lane_offsets[i])
	menu_camera.current = false
	player_camera.current = true
	if race_audio:
		race_audio.reset_events()
		race_audio.set_race_active(true)


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
		top_left_panel,
		top_center_panel,
		top_right_panel,
		speed_panel,
		aux_panel,
		place_suffix_label,
		lap_goal_label,
		race_status_label,
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
		speed_gauge,
		nitro_gauge,
		drift_gauge,
		controls_label,
		offroad_label,
		track_name_label,
		track_info_label,
		minimap,
		minimap_lap_label,
		speed_overlay,
		nitro_overlay,
		countdown_lights,
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

	hud_root = Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud_root)
	hud_root.resized.connect(_layout_hud)

	speed_overlay_material = _make_edge_glow_material(Color(0.45, 0.78, 1.0))
	speed_overlay = ColorRect.new()
	speed_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	speed_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed_overlay.material = speed_overlay_material
	speed_overlay.visible = false
	hud_root.add_child(speed_overlay)

	nitro_overlay_material = _make_edge_glow_material(Color(0.25, 0.72, 1.0))
	nitro_overlay = ColorRect.new()
	nitro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nitro_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nitro_overlay.material = nitro_overlay_material
	nitro_overlay.visible = false
	hud_root.add_child(nitro_overlay)

	top_left_panel = RaceHudWidgets.make_panel(
		"TopLeft",
		Color(0.015, 0.045, 0.065, 0.84),
		Color(0.22, 0.72, 0.76, 0.58),
		2,
		5
	)
	hud_root.add_child(top_left_panel)
	top_center_panel = RaceHudWidgets.make_panel(
		"TopCenter",
		Color(0.015, 0.035, 0.05, 0.66),
		Color(0.82, 0.94, 0.95, 0.20),
		1,
		5
	)
	hud_root.add_child(top_center_panel)
	top_right_panel = RaceHudWidgets.make_panel(
		"TopRight",
		Color(0.012, 0.03, 0.045, 0.72),
		Color(0.25, 0.78, 0.82, 0.34),
		1,
		5
	)
	hud_root.add_child(top_right_panel)
	speed_panel = RaceHudWidgets.make_panel(
		"SpeedPanel",
		Color(0.008, 0.024, 0.035, 0.74),
		Color(0.28, 0.76, 0.80, 0.28),
		1,
		6
	)
	hud_root.add_child(speed_panel)
	aux_panel = RaceHudWidgets.make_panel(
		"AuxPanel",
		Color(0.008, 0.024, 0.035, 0.78),
		Color(0.98, 0.63, 0.20, 0.42),
		1,
		6
	)
	hud_root.add_child(aux_panel)

	top_strip = ColorRect.new()
	top_strip.color = Color(0.22, 0.86, 0.90, 0.82)
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(top_strip)

	place_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 40, Color("#e8ffff"))
	place_label.text = "P1"
	place_suffix_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 15, Color("#9fc8cc"))
	place_suffix_label.text = "/ 6 CARS"
	lap_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 19, Color("#d8f4f5"))
	lap_label.text = "第 1 / 3 圈"
	lap_goal_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 13, Color("#90b4b8"))
	lap_goal_label.text = "目标 40 秒"
	track_name_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 22, Color("#ffffff"))
	track_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	track_name_label.text = current_track_name
	track_info_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 13, Color("#9fdce4"))
	track_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	track_info_label.text = ""
	timer_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 29, Color.WHITE)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.text = "00:00.000"
	race_status_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 13, Color("#9fdce4"))
	race_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	race_status_label.text = "准备"

	minimap = RaceMinimap.new()
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(minimap)
	minimap_lap_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 13, Color("#d8f7f8"))
	minimap_lap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	minimap_lap_label.text = ""

	speed_gauge = RaceHudWidgets.SpeedGauge.new()
	speed_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(speed_gauge)
	speed_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 58, Color("#ffffff"))
	speed_label.text = "000"
	gear_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 15, Color("#9edbe3"))
	gear_label.text = "km/h  ·  D"

	nitro_state_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 15, Color("#ffdf75"))
	nitro_state_label.text = "氮气  未充能"
	nitro_gauge = RaceHudWidgets.NitroGauge.new()
	nitro_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(nitro_gauge)
	drift_state_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 15, Color("#d9e8ec"))
	drift_state_label.text = "漂移角度  0°"
	drift_gauge = RaceHudWidgets.DriftGauge.new()
	drift_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(drift_gauge)

	nitro_bar = _make_progress(
		hud_root,
		Color("#24d5dc"),
		Vector2.ZERO,
		Vector2.ZERO,
		Control.PRESET_TOP_LEFT
	)
	nitro_bar.visible = false
	drift_bar = _make_progress(
		hud_root,
		Color("#ff9c2b"),
		Vector2.ZERO,
		Vector2.ZERO,
		Control.PRESET_TOP_LEFT
	)
	drift_bar.visible = false

	controls_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 13, Color(0.84, 0.93, 0.95, 0.85))
	controls_label.text = "WASD 驾驶   SPACE 漂移   SHIFT 氮气   R 重赛   ESC 暂停"

	offroad_label = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 22, Color("#ffdf70"))
	offroad_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	offroad_label.text = ""

	countdown_lights = RaceHudWidgets.CountdownLights.new()
	countdown_lights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(countdown_lights)
	center_message = _make_label(hud_root, Vector2.ZERO, Vector2.ZERO, 112, Color.WHITE)
	center_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_message.text = ""

	start_overlay = ColorRect.new()
	start_overlay.color = Color(0.008, 0.022, 0.034, 0.16)
	start_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(start_overlay)
	var menu_panel := RaceHudWidgets.make_panel(
		"MenuPanel",
		Color(0.008, 0.024, 0.038, 0.90),
		Color(0.24, 0.82, 0.86, 0.38),
		1,
		7
	)
	start_overlay.add_child(menu_panel)
	var title := _make_label(menu_panel, Vector2.ZERO, Vector2.ZERO, 50, Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.text = "Q版氮气竞速"
	var subtitle := _make_label(menu_panel, Vector2.ZERO, Vector2.ZERO, 18, Color("#8ce5ee"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.text = "ARCADE RACING"
	menu_state_label = _make_label(menu_panel, Vector2.ZERO, Vector2.ZERO, 14, Color("#d7f8f8"))
	menu_state_label.text = "展厅 · 赛道选择"
	for index in 3:
		var option := _make_label(menu_panel, Vector2.ZERO, Vector2.ZERO, 20, Color("#c8eef1"))
		option.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		track_option_labels.append(option)
	menu_track_detail_label = _make_label(menu_panel, Vector2.ZERO, Vector2.ZERO, 15, Color("#9edde2"))
	menu_track_detail_label.text = ""
	menu_difficulty_label = _make_label(menu_panel, Vector2.ZERO, Vector2.ZERO, 15, Color("#ffd56b"))
	menu_difficulty_label.text = ""
	menu_start_prompt = _make_label(menu_panel, Vector2.ZERO, Vector2.ZERO, 22, Color("#ffd968"))
	menu_start_prompt.text = "ENTER 发车"

	var menu_controls := _make_label(menu_panel, Vector2.ZERO, Vector2.ZERO, 13, Color("#93b6bb"))
	menu_controls.text = "1 / 2 / 3 切换赛道   Q / E 调整 AI   ENTER 发车"
	menu_controls.name = "MenuControls"

	pause_overlay = _make_result_overlay(
		hud_root,
		"比赛暂停",
		"PAUSE / RACE CONTROL",
		Color(0.16, 0.68, 0.72, 0.42)
	)
	pause_overlay.visible = false
	pause_summary_label = pause_overlay.get_meta("summary_label")
	pause_controls_label = pause_overlay.get_meta("prompt_label")
	finish_overlay = _make_result_overlay(
		hud_root,
		"比赛结果",
		"RACE COMPLETE",
		Color(0.98, 0.65, 0.24, 0.52)
	)
	finish_overlay.visible = false
	finish_summary_label = finish_overlay.get_meta("summary_label")
	finish_stats_label = finish_overlay.get_meta("prompt_label")
	finish_place_label = finish_overlay.get_meta("primary_label")
	finish_time_label = finish_overlay.get_meta("secondary_label")
	finish_place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_prompt_label = finish_stats_label
	_layout_hud()


func _layout_hud() -> void:
	if not hud_root:
		return
	var viewport_size := hud_root.size
	if viewport_size.x < 32.0 or viewport_size.y < 32.0:
		return
	var scale_factor := clampf(
		minf(viewport_size.x / 1440.0, viewport_size.y / 900.0),
		0.82,
		1.35
	)
	var margin := 24.0 * scale_factor
	var left_width := 286.0 * scale_factor
	var top_height := 86.0 * scale_factor
	var center_width := 470.0 * scale_factor
	var panel_gap := 14.0 * scale_factor
	_set_control_rect(top_left_panel, Vector2(margin, margin), Vector2(left_width, top_height))
	_set_control_rect(
		top_center_panel,
		Vector2((viewport_size.x - center_width) * 0.5, margin),
		Vector2(center_width, 72.0 * scale_factor)
	)
	var right_width := 352.0 * scale_factor
	_set_control_rect(
		top_right_panel,
		Vector2(viewport_size.x - margin - right_width, margin),
		Vector2(right_width, 72.0 * scale_factor)
	)

	_set_control_rect(
		place_label,
		Vector2(margin + 22.0 * scale_factor, margin + 10.0 * scale_factor),
		Vector2(126.0 * scale_factor, 49.0 * scale_factor)
	)
	_set_control_rect(
		place_suffix_label,
		Vector2(margin + 146.0 * scale_factor, margin + 22.0 * scale_factor),
		Vector2(120.0 * scale_factor, 34.0 * scale_factor)
	)
	_set_control_rect(
		lap_label,
		Vector2(margin + 21.0 * scale_factor, margin + 55.0 * scale_factor),
		Vector2(150.0 * scale_factor, 27.0 * scale_factor)
	)
	_set_control_rect(
		lap_goal_label,
		Vector2(margin + 176.0 * scale_factor, margin + 58.0 * scale_factor),
		Vector2(left_width - 198.0 * scale_factor, 22.0 * scale_factor)
	)
	_set_font_size(place_label, int(40.0 * scale_factor))
	_set_font_size(place_suffix_label, int(15.0 * scale_factor))
	_set_font_size(lap_label, int(19.0 * scale_factor))
	_set_font_size(lap_goal_label, int(13.0 * scale_factor))

	_set_control_rect(
		track_name_label,
		Vector2((viewport_size.x - center_width) * 0.5 + 12.0 * scale_factor, margin + 8.0 * scale_factor),
		Vector2(center_width - 24.0 * scale_factor, 31.0 * scale_factor)
	)
	_set_control_rect(
		track_info_label,
		Vector2((viewport_size.x - center_width) * 0.5 + 12.0 * scale_factor, margin + 41.0 * scale_factor),
		Vector2(center_width - 24.0 * scale_factor, 22.0 * scale_factor)
	)
	_set_font_size(track_name_label, int(22.0 * scale_factor))
	_set_font_size(track_info_label, int(13.0 * scale_factor))

	_set_control_rect(
		timer_label,
		Vector2(
			viewport_size.x - margin - right_width + 18.0 * scale_factor,
			margin + 8.0 * scale_factor
		),
		Vector2(right_width - 36.0 * scale_factor, 38.0 * scale_factor)
	)
	_set_control_rect(
		race_status_label,
		Vector2(
			viewport_size.x - margin - right_width + 18.0 * scale_factor,
			margin + 46.0 * scale_factor
		),
		Vector2(right_width - 36.0 * scale_factor, 18.0 * scale_factor)
	)
	_set_font_size(timer_label, int(29.0 * scale_factor))
	_set_font_size(race_status_label, int(13.0 * scale_factor))

	var minimap_size := Vector2(304.0 * scale_factor, 184.0 * scale_factor)
	_set_control_rect(
		minimap,
		Vector2(viewport_size.x - margin - minimap_size.x, margin + top_height + panel_gap),
		minimap_size
	)
	_set_control_rect(
		minimap_lap_label,
		Vector2(
			viewport_size.x - margin - minimap_size.x + 8.0 * scale_factor,
			margin + top_height + panel_gap + minimap_size.y + 6.0 * scale_factor
		),
		Vector2(minimap_size.x - 16.0 * scale_factor, 22.0 * scale_factor)
	)
	_set_font_size(minimap_lap_label, int(13.0 * scale_factor))

	var speed_width := 316.0 * scale_factor
	var speed_height := 142.0 * scale_factor
	_set_control_rect(
		speed_panel,
		Vector2(margin, viewport_size.y - margin - speed_height - 28.0 * scale_factor),
		Vector2(speed_width, speed_height)
	)
	_set_control_rect(
		speed_gauge,
		Vector2(margin + 8.0 * scale_factor, viewport_size.y - margin - speed_height - 20.0 * scale_factor),
		Vector2(speed_width - 16.0 * scale_factor, speed_height - 8.0 * scale_factor)
	)
	_set_control_rect(
		speed_label,
		Vector2(margin + 24.0 * scale_factor, viewport_size.y - margin - 92.0 * scale_factor),
		Vector2(196.0 * scale_factor, 68.0 * scale_factor)
	)
	_set_control_rect(
		gear_label,
		Vector2(margin + 203.0 * scale_factor, viewport_size.y - margin - 55.0 * scale_factor),
		Vector2(92.0 * scale_factor, 30.0 * scale_factor)
	)
	_set_font_size(speed_label, int(58.0 * scale_factor))
	_set_font_size(gear_label, int(15.0 * scale_factor))

	var aux_width := 392.0 * scale_factor
	var aux_height := 142.0 * scale_factor
	_set_control_rect(
		aux_panel,
		Vector2(
			viewport_size.x - margin - aux_width,
			viewport_size.y - margin - aux_height - 28.0 * scale_factor
		),
		Vector2(aux_width, aux_height)
	)
	_set_control_rect(
		nitro_state_label,
		Vector2(
			viewport_size.x - margin - aux_width + 20.0 * scale_factor,
			viewport_size.y - margin - aux_height - 20.0 * scale_factor
		),
		Vector2(aux_width - 40.0 * scale_factor, 25.0 * scale_factor)
	)
	_set_control_rect(
		nitro_gauge,
		Vector2(
			viewport_size.x - margin - aux_width + 20.0 * scale_factor,
			viewport_size.y - margin - aux_height + 6.0 * scale_factor
		),
		Vector2(aux_width - 40.0 * scale_factor, 19.0 * scale_factor)
	)
	_set_control_rect(
		drift_state_label,
		Vector2(
			viewport_size.x - margin - aux_width + 20.0 * scale_factor,
			viewport_size.y - margin - aux_height + 38.0 * scale_factor
		),
		Vector2(220.0 * scale_factor, 24.0 * scale_factor)
	)
	_set_control_rect(
		drift_gauge,
		Vector2(
			viewport_size.x - margin - 166.0 * scale_factor,
			viewport_size.y - margin - aux_height + 34.0 * scale_factor
		),
		Vector2(136.0 * scale_factor, 62.0 * scale_factor)
	)
	_set_font_size(nitro_state_label, int(15.0 * scale_factor))
	_set_font_size(drift_state_label, int(15.0 * scale_factor))

	_set_control_rect(
		controls_label,
		Vector2(margin + 2.0, viewport_size.y - margin - 4.0 * scale_factor),
		Vector2(minf(650.0 * scale_factor, viewport_size.x * 0.48), 20.0 * scale_factor)
	)
	_set_font_size(controls_label, int(13.0 * scale_factor))

	_set_control_rect(
		offroad_label,
		Vector2(viewport_size.x * 0.28, margin + top_height + panel_gap),
		Vector2(viewport_size.x * 0.44, 35.0 * scale_factor)
	)
	_set_font_size(offroad_label, int(22.0 * scale_factor))

	var countdown_width := 330.0 * scale_factor
	_set_control_rect(
		countdown_lights,
		Vector2(
			(viewport_size.x - countdown_width) * 0.5,
			viewport_size.y * 0.19
		),
		Vector2(countdown_width, 82.0 * scale_factor)
	)
	_set_control_rect(
		center_message,
		Vector2(viewport_size.x * 0.5 - 240.0 * scale_factor, viewport_size.y * 0.28),
		Vector2(480.0 * scale_factor, 170.0 * scale_factor)
	)
	_set_font_size(center_message, int(112.0 * scale_factor))

	_layout_menu_panel(viewport_size, scale_factor, margin)
	_layout_result_overlay(pause_overlay, viewport_size, scale_factor)
	_layout_result_overlay(finish_overlay, viewport_size, scale_factor)


func _layout_menu_panel(viewport_size: Vector2, scale_factor: float, margin: float) -> void:
	if not start_overlay or start_overlay.get_child_count() == 0:
		return
	var menu_panel := start_overlay.get_child(0) as Panel
	if not menu_panel:
		return
	var panel_width := minf(548.0 * scale_factor, viewport_size.x * 0.44)
	var panel_height := minf(630.0 * scale_factor, viewport_size.y - margin * 2.0)
	_set_control_rect(
		menu_panel,
		Vector2(margin + 10.0 * scale_factor, (viewport_size.y - panel_height) * 0.5),
		Vector2(panel_width, panel_height)
	)
	var labels := menu_panel.get_children()
	var title := labels[0] as Label
	var subtitle := labels[1] as Label
	_set_control_rect(
		title,
		Vector2(28.0 * scale_factor, 34.0 * scale_factor),
		Vector2(panel_width - 56.0 * scale_factor, 66.0 * scale_factor)
	)
	_set_control_rect(
		subtitle,
		Vector2(30.0 * scale_factor, 98.0 * scale_factor),
		Vector2(panel_width - 60.0 * scale_factor, 28.0 * scale_factor)
	)
	_set_control_rect(
		menu_state_label,
		Vector2(30.0 * scale_factor, 132.0 * scale_factor),
		Vector2(panel_width - 60.0 * scale_factor, 30.0 * scale_factor)
	)
	var options_top := 190.0 * scale_factor
	for index in track_option_labels.size():
		_set_control_rect(
			track_option_labels[index],
			Vector2(28.0 * scale_factor, options_top + float(index) * 54.0 * scale_factor),
			Vector2(panel_width - 56.0 * scale_factor, 38.0 * scale_factor)
		)
		_set_font_size(track_option_labels[index], int(20.0 * scale_factor))
	_set_control_rect(
		menu_track_detail_label,
		Vector2(30.0 * scale_factor, options_top + 170.0 * scale_factor),
		Vector2(panel_width - 60.0 * scale_factor, 28.0 * scale_factor)
	)
	_set_control_rect(
		menu_difficulty_label,
		Vector2(30.0 * scale_factor, options_top + 206.0 * scale_factor),
		Vector2(panel_width - 60.0 * scale_factor, 28.0 * scale_factor)
	)
	_set_control_rect(
		menu_start_prompt,
		Vector2(30.0 * scale_factor, panel_height - 118.0 * scale_factor),
		Vector2(panel_width - 60.0 * scale_factor, 42.0 * scale_factor)
	)
	var menu_controls := menu_panel.get_node_or_null("MenuControls") as Label
	if menu_controls:
		_set_control_rect(
			menu_controls,
			Vector2(30.0 * scale_factor, panel_height - 64.0 * scale_factor),
			Vector2(panel_width - 60.0 * scale_factor, 34.0 * scale_factor)
		)
	_set_font_size(title, int(50.0 * scale_factor))
	_set_font_size(subtitle, int(18.0 * scale_factor))
	_set_font_size(menu_state_label, int(14.0 * scale_factor))
	_set_font_size(menu_track_detail_label, int(15.0 * scale_factor))
	_set_font_size(menu_difficulty_label, int(15.0 * scale_factor))
	_set_font_size(menu_start_prompt, int(22.0 * scale_factor))
	if menu_controls:
		_set_font_size(menu_controls, int(13.0 * scale_factor))


func _layout_result_overlay(
		overlay: Control,
		viewport_size: Vector2,
		scale_factor: float
	) -> void:
	if not overlay:
		return
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := overlay.get_node_or_null("ResultPanel") as Panel
	if not panel:
		return
	var panel_size := Vector2(680.0 * scale_factor, 382.0 * scale_factor)
	panel.position = (viewport_size - panel_size) * 0.5
	panel.size = panel_size
	var title := panel.get_node("Title") as Label
	var kicker := panel.get_node("Kicker") as Label
	var primary := panel.get_node("Primary") as Label
	var secondary := panel.get_node("Secondary") as Label
	var summary := panel.get_node("Summary") as Label
	var prompt := panel.get_node("Prompt") as Label
	_set_control_rect(title, Vector2(32.0, 24.0) * scale_factor, Vector2(panel_size.x - 64.0 * scale_factor, 58.0 * scale_factor))
	_set_control_rect(kicker, Vector2(34.0, 78.0) * scale_factor, Vector2(panel_size.x - 68.0 * scale_factor, 24.0 * scale_factor))
	_set_control_rect(primary, Vector2(34.0, 112.0) * scale_factor, Vector2(panel_size.x - 68.0 * scale_factor, 54.0 * scale_factor))
	_set_control_rect(secondary, Vector2(34.0, 164.0) * scale_factor, Vector2(panel_size.x - 68.0 * scale_factor, 34.0 * scale_factor))
	_set_control_rect(summary, Vector2(34.0, 206.0) * scale_factor, Vector2(panel_size.x - 68.0 * scale_factor, 28.0 * scale_factor))
	_set_control_rect(prompt, Vector2(34.0, panel_size.y - 68.0 * scale_factor), Vector2(panel_size.x - 68.0 * scale_factor, 42.0 * scale_factor))
	_set_font_size(title, int(34.0 * scale_factor))
	_set_font_size(kicker, int(13.0 * scale_factor))
	_set_font_size(primary, int(42.0 * scale_factor))
	_set_font_size(secondary, int(22.0 * scale_factor))
	_set_font_size(summary, int(15.0 * scale_factor))
	_set_font_size(prompt, int(18.0 * scale_factor))


func _set_control_rect(control: Control, rect_position: Vector2, rect_size: Vector2) -> void:
	if not control:
		return
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect_position
	control.size = rect_size


func _set_font_size(label: Label, font_size: int) -> void:
	if label:
		label.add_theme_font_size_override("font_size", font_size)


func _make_result_overlay(
		parent: Control,
		title_text: String,
		kicker_text: String,
		accent: Color
	) -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.004, 0.015, 0.024, 0.78)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	var panel := RaceHudWidgets.make_panel(
		"ResultPanel",
		Color(0.012, 0.032, 0.048, 0.96),
		accent,
		2,
		8
	)
	overlay.add_child(panel)
	var accent_line := ColorRect.new()
	accent_line.color = accent
	accent_line.position = Vector2(0.0, 0.0)
	accent_line.size = Vector2(6.0, 382.0)
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(accent_line)
	var title := _make_label(panel, Vector2.ZERO, Vector2.ZERO, 34, Color.WHITE)
	title.name = "Title"
	title.text = title_text
	var kicker := _make_label(panel, Vector2.ZERO, Vector2.ZERO, 13, accent.lightened(0.22))
	kicker.name = "Kicker"
	kicker.text = kicker_text
	var primary := _make_label(panel, Vector2.ZERO, Vector2.ZERO, 42, Color("#ffd66b"))
	primary.name = "Primary"
	primary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	primary.text = "P1"
	var secondary := _make_label(panel, Vector2.ZERO, Vector2.ZERO, 22, Color("#d8f2f3"))
	secondary.name = "Secondary"
	secondary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secondary.text = "00:00.000"
	var summary := _make_label(panel, Vector2.ZERO, Vector2.ZERO, 15, Color("#9fc4c8"))
	summary.name = "Summary"
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.text = ""
	var prompt := _make_label(panel, Vector2.ZERO, Vector2.ZERO, 18, Color("#a8d9dd"))
	prompt.name = "Prompt"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.text = ""
	overlay.set_meta("summary_label", summary)
	overlay.set_meta("prompt_label", prompt)
	overlay.set_meta("primary_label", primary)
	overlay.set_meta("secondary_label", secondary)
	return overlay


func _make_edge_glow_material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.4, 0.8, 1.0, 1.0);

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float edge = smoothstep(0.35, 1.25, length(vec2(centered.x * 0.72, centered.y)));
	COLOR = vec4(tint.rgb, edge * intensity);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("intensity", 0.0)
	return material


func _refresh_track_menu() -> void:
	if not track_name_label:
		return
	var descriptor: Dictionary = track_catalog[current_track_index]
	var theme_color: Color = descriptor["theme_color"]
	var difficulty: Dictionary = DIFFICULTY_PRESETS[difficulty_index]
	track_name_label.text = String(descriptor["name"])
	track_name_label.add_theme_color_override("font_color", theme_color)
	track_info_label.text = "%d 圈 · AI %s · 目标 %.0f 秒" % [
		total_laps,
		String(difficulty["name"]),
		float(descriptor["lap_time"]),
	]
	if lap_goal_label:
		lap_goal_label.text = "目标 %.0f 秒 / 圈" % float(descriptor["lap_time"])
	if menu_state_label:
		menu_state_label.text = "展厅 · 赛道 %d / %d" % [
			current_track_index + 1,
			track_catalog.size(),
		]
	if menu_track_detail_label:
		menu_track_detail_label.text = "%s · %d 圈 · 目标 %.0f 秒/圈" % [
			String(descriptor["subtitle"]),
			total_laps,
			float(descriptor["lap_time"]),
		]
	if menu_difficulty_label:
		menu_difficulty_label.text = "AI 难度  %s   ·   Q / E 调整" % String(difficulty["name"])
		menu_difficulty_label.add_theme_color_override("font_color", theme_color.lightened(0.25))
	if menu_start_prompt:
		menu_start_prompt.text = "ENTER 发车"
		menu_start_prompt.add_theme_color_override("font_color", theme_color.lightened(0.30))
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
	if is_instance_valid(controls_label):
		controls_label.text = "WASD 驾驶   SPACE 漂移   SHIFT 氮气   R 重赛   ESC 暂停"


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
	race_audio.setup(self)
	engine_player = race_audio.players.get("engine_low")
	engine_high_player = race_audio.players.get("engine_high")
	ambient_player = race_audio.players.get("ambient")
	_update_ambient_for_track()


func _update_ambient_for_track() -> void:
	if not race_audio:
		return
	race_audio.set_track(current_track_id)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if race_state == "paused":
				race_state = "racing"
				pause_overlay.visible = false
				race_audio.play_ui("confirm")
			elif race_state != "waiting" and race_state != "finished":
				race_state = "paused"
				pause_overlay.visible = true
				_update_pause_summary()
				race_audio.play_ui("cancel")
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_R:
			if race_state != "waiting":
				race_audio.play_ui("confirm")
				_restart_race()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_T and (race_state == "finished" or race_state == "paused"):
			race_audio.play_ui("cancel")
			_return_to_showroom()
			get_viewport().set_input_as_handled()
			return
		if race_state == "waiting":
			if event.keycode in [KEY_Q, KEY_BRACKETLEFT]:
				difficulty_index = posmod(difficulty_index - 1, DIFFICULTY_PRESETS.size())
				race_audio.play_ui("move")
				_refresh_track_menu()
				get_viewport().set_input_as_handled()
				return
			if event.keycode in [KEY_E, KEY_BRACKETRIGHT]:
				difficulty_index = posmod(difficulty_index + 1, DIFFICULTY_PRESETS.size())
				race_audio.play_ui("move")
				_refresh_track_menu()
				get_viewport().set_input_as_handled()
				return
			if event.keycode in [KEY_1, KEY_2, KEY_3]:
				race_audio.play_ui("move")
				_load_track(event.keycode - KEY_1)
				get_viewport().set_input_as_handled()
				return
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
				race_audio.play_ui("confirm")
				race_audio.reset_events()
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
			race_audio.play_countdown(0)
		else:
			var countdown_value := int(ceil(countdown_time))
			if countdown_value != last_countdown_value:
				last_countdown_value = countdown_value
				center_message.text = str(countdown_value)
				center_message.modulate.a = 1.0
				race_audio.play_countdown(countdown_value)
		_update_ai(delta, true)
		_update_camera_idle(delta)
		return
	if race_state == "finished":
		race_elapsed_time += delta
		_update_ai(delta, false)
		_update_camera_idle(delta)
		return

	race_time += delta
	race_elapsed_time += delta
	_update_player(delta)
	_update_ai(delta, false)
	_update_race_place()
	_update_camera(delta)


func _update_player(delta: float) -> void:
	var throttle := 0.0
	var steering := 0.0
	if _drive_key_pressed(KEY_W, "throttle"):
		throttle += 1.0
	if _drive_key_pressed(KEY_S, "brake"):
		throttle -= 1.0
	if _drive_key_pressed(KEY_A, "steer_left") or _drive_key_pressed(KEY_LEFT, "steer_left"):
		steering += 1.0
	if _drive_key_pressed(KEY_D, "steer_right") or _drive_key_pressed(KEY_RIGHT, "steer_right"):
		steering -= 1.0
	var steering_rate := (
		driving_tuning.steering_input_attack
		if absf(steering) >= absf(player_steering)
		else driving_tuning.steering_input_release
	)
	player_steering = _smooth_value(player_steering, steering, steering_rate, delta)
	var drift_held := _drive_key_pressed(KEY_SPACE, "drift")
	var shift_held := _drive_key_pressed(KEY_SHIFT, "nitro")
	var previous_forward_speed := player_forward_speed

	var forward := -player.global_transform.basis.z
	var right := player.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	player_forward_speed = player_velocity.dot(forward)
	player_lateral_speed = player_velocity.dot(right)

	if shift_held and player_drift_charge >= 10.0 and player_nitro_time <= 0.0:
		player_nitro_time = clampf(0.85 + player_drift_charge / 58.0, 0.85, 2.25)
		player_drift_charge = maxf(
			0.0,
			player_drift_charge - driving_tuning.nitro_activation_cost
		)
	var boost_active := player_nitro_time > 0.0
	var maximum_speed := (
		driving_tuning.nitro_max_speed
		if boost_active
		else driving_tuning.max_forward_speed
	)
	var speed_abs := absf(player_forward_speed)
	var nearest := _nearest_track_point(player.global_position, player_progress_index)
	player_in_shortcut = _is_in_shortcut(player.global_position)
	player_offroad = (
		not player_in_shortcut
		and float(nearest["distance"]) > road_half_width + 0.7
	)
	var traction_multiplier := (
		driving_tuning.offroad_traction_multiplier if player_offroad else 1.0
	)
	if throttle > 0.0:
		if player_forward_speed < -1.0:
			player_forward_speed = move_toward(
				player_forward_speed,
				0.0,
				driving_tuning.brake_deceleration * 0.82 * delta
			)
		else:
			var speed_ratio := clampf(
				maxf(player_forward_speed, 0.0) / maximum_speed,
				0.0,
				1.0
			)
			var engine_force := lerpf(
				driving_tuning.high_speed_acceleration,
				driving_tuning.launch_acceleration,
				pow(1.0 - speed_ratio, driving_tuning.acceleration_curve_power)
			)
			if boost_active:
				engine_force += driving_tuning.nitro_acceleration_bonus * (
					0.72 + 0.28 * (1.0 - speed_ratio)
				)
			player_forward_speed += engine_force * traction_multiplier * delta
	elif throttle < 0.0:
		if player_forward_speed > 1.0:
			var brake_force := driving_tuning.brake_deceleration * (
				1.0
				+ driving_tuning.brake_high_speed_bonus
				* clampf(player_forward_speed / driving_tuning.max_forward_speed, 0.0, 1.0)
			)
			player_forward_speed = move_toward(
				player_forward_speed,
				0.0,
				brake_force * traction_multiplier * delta
			)
		else:
			player_forward_speed -= (
				driving_tuning.reverse_acceleration
				* traction_multiplier
				* delta
			)
	else:
		var coast_drag := driving_tuning.rolling_drag + (
			driving_tuning.aero_drag
			* player_forward_speed
			* absf(player_forward_speed)
		)
		player_forward_speed = move_toward(
			player_forward_speed,
			0.0,
			maxf(coast_drag, 0.0) * delta
		)
	if boost_active and throttle <= 0.0:
		player_forward_speed += driving_tuning.nitro_acceleration_bonus * 0.72 * delta

	if player_offroad:
		var offroad_limit_speed := maximum_speed * driving_tuning.offroad_speed_factor
		if player_forward_speed > offroad_limit_speed:
			var overspeed := player_forward_speed - offroad_limit_speed
			player_forward_speed = move_toward(
				player_forward_speed,
				offroad_limit_speed,
				(
					driving_tuning.offroad_overspeed_recovery
					+ overspeed * 2.4
				) * delta
			)
		player_forward_speed = move_toward(
			player_forward_speed,
			0.0,
			driving_tuning.offroad_extra_drag * delta
		)

	speed_abs = absf(player_forward_speed)
	var slip_seed := absf(atan2(player_lateral_speed, maxf(speed_abs, 1.0)))
	var drift_requested := (
		drift_held
		and speed_abs > driving_tuning.drift_min_speed
		and (absf(player_steering) > 0.18 or slip_seed > 0.07)
	)
	var countersteer := 0.0
	if absf(player_lateral_speed) > 0.15:
		countersteer = clampf(-signf(player_lateral_speed) * player_steering, 0.0, 1.0)
	var target_drift_blend := 1.0 if drift_requested else 0.0
	if drift_requested and countersteer > 0.02:
		target_drift_blend = maxf(0.0, 1.0 - countersteer * 0.55)
	var drift_blend_rate := (
		driving_tuning.drift_entry_rate
		if target_drift_blend > player_drift_blend
		else driving_tuning.drift_exit_rate
	)
	if countersteer > 0.02:
		drift_blend_rate = maxf(drift_blend_rate, driving_tuning.drift_exit_rate * 0.72)
	player_drift_blend = _smooth_value(
		player_drift_blend,
		target_drift_blend,
		drift_blend_rate,
		delta
	)
	player_drifting = (
		player_drift_blend > 0.26
		and speed_abs > driving_tuning.drift_min_speed
	)

	var speed_ratio := clampf(
		speed_abs / driving_tuning.max_forward_speed,
		0.0,
		1.0
	)
	var yaw_authority := lerpf(
		driving_tuning.low_speed_yaw_rate,
		driving_tuning.high_speed_yaw_rate,
		pow(speed_ratio, 1.05)
	)
	if speed_abs < driving_tuning.steering_min_speed:
		yaw_authority *= smoothstep(
			0.0,
			driving_tuning.steering_min_speed,
			speed_abs
		)
	yaw_authority *= lerpf(1.0, driving_tuning.drift_yaw_multiplier, player_drift_blend)
	if player_offroad:
		yaw_authority *= 0.78
	var reverse_sign := -1.0 if player_forward_speed < 0.0 else 1.0
	var target_yaw_rate := player_steering * yaw_authority * reverse_sign
	target_yaw_rate = clampf(
		target_yaw_rate,
		-driving_tuning.max_yaw_rate,
		driving_tuning.max_yaw_rate
	)
	player_yaw_rate = _smooth_value(player_yaw_rate, target_yaw_rate, 12.0, delta)
	player.rotate_y(player_yaw_rate * delta)

	forward = -player.global_transform.basis.z
	right = player.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var slip_generation := driving_tuning.slip_generation + (
		driving_tuning.drift_slip_generation_bonus
		* player_drift_blend
	)
	player_lateral_speed += (
		player_yaw_rate
		* speed_abs
		* slip_generation
		* delta
	)
	var lateral_grip := lerpf(
		driving_tuning.normal_lateral_grip,
		driving_tuning.drift_lateral_grip,
		player_drift_blend
	)
	lateral_grip += driving_tuning.countersteer_grip_bonus * countersteer
	if player_offroad:
		lateral_grip *= driving_tuning.offroad_grip_multiplier
	player_lateral_speed *= exp(-maxf(lateral_grip, 0.1) * delta)

	var slip_limit_degrees := lerpf(
		driving_tuning.max_normal_slip_angle_degrees,
		driving_tuning.max_slip_angle_degrees,
		player_drift_blend
	)
	var slip_limit := tan(deg_to_rad(slip_limit_degrees)) * maxf(speed_abs, 1.0)
	if absf(player_lateral_speed) > slip_limit:
		player_lateral_speed = signf(player_lateral_speed) * slip_limit
		player_yaw_rate *= 0.82
	player_slip_angle = atan2(
		player_lateral_speed,
		maxf(speed_abs, 1.0)
	)
	player_drift_angle = absf(player_slip_angle)
	if player_drifting:
		player_forward_speed *= exp(-driving_tuning.drift_drag * delta)

	var charge_speed_ratio := clampf(
		speed_abs / driving_tuning.max_forward_speed,
		0.0,
		1.0
	)
	if speed_abs > 5.0 and player_nitro_time <= 0.0:
		var charge_rate := driving_tuning.nitro_passive_charge * pow(
			charge_speed_ratio,
			0.82
		)
		charge_rate += (
			absf(player_steering)
			* driving_tuning.nitro_steering_charge
			* charge_speed_ratio
		)
		if player_drift_blend > 0.08:
			charge_rate += (
				driving_tuning.nitro_drift_charge
				+ minf(player_drift_angle, 0.76)
				* driving_tuning.nitro_drift_angle_charge
			) * player_drift_blend
		player_drift_charge = minf(
			100.0,
			player_drift_charge + charge_rate * delta
		)
	else:
		player_drift_charge = maxf(0.0, player_drift_charge - delta * 1.8)

	if player_nitro_time > 0.0:
		player_nitro_time = maxf(0.0, player_nitro_time - delta)
		player_drift_charge = maxf(
			0.0,
			player_drift_charge - driving_tuning.nitro_drain_rate * delta
		)
	nitro_requested = player_nitro_time > 0.0

	player_forward_speed = clampf(
		player_forward_speed,
		-driving_tuning.reverse_max_speed,
		maximum_speed
	)
	if player_in_shortcut:
		player_forward_speed = minf(player_forward_speed, maximum_speed * 0.90)
	player_velocity = forward * player_forward_speed + right * player_lateral_speed
	player_longitudinal_acceleration = _smooth_value(
		player_longitudinal_acceleration,
		(player_forward_speed - previous_forward_speed) / maxf(delta, 0.0001),
		9.0,
		delta
	)
	player.global_position += player_velocity * delta

	var ground_route_tangent := track_tangents[int(nearest["index"])]
	var ground_target_y := curve.sample_baked(
		fposmod(player_track_t, 1.0) * track_length,
		true
	).y + 0.055
	var ground_snap_rate := 24.0
	player_in_shortcut = _is_in_shortcut(player.global_position)
	if player_in_shortcut:
		var shortcut_info := _nearest_shortcut_sample(player.global_position)
		var target_shortcut_y: float = shortcut_info["center"].y + 0.15
		ground_target_y = target_shortcut_y
		ground_route_tangent = shortcut_info["tangent"]
		ground_snap_rate = 22.0
	var proposed_y := lerpf(
		player.global_position.y,
		ground_target_y,
		1.0 - exp(-ground_snap_rate * delta)
	)
	var maximum_vertical_step := (
		0.018
		+ absf(player_forward_speed)
		* absf(ground_route_tangent.y)
		* delta
		* 1.45
	)
	if absf(proposed_y - player.global_position.y) > maximum_vertical_step:
		proposed_y = move_toward(
			player.global_position.y,
			proposed_y,
			maximum_vertical_step
		)
	player.global_position.y = proposed_y

	_resolve_player_boundary(nearest)

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
	var visual_roll := (
		-player_steering
		* (
			driving_tuning.body_roll_steering
			+ driving_tuning.body_roll_drift * player_drift_blend
		)
		- player_lateral_speed
		/ driving_tuning.max_forward_speed
		* driving_tuning.body_roll_lateral
	)
	visual_roll = clampf(
		visual_roll,
		-driving_tuning.max_body_roll,
		driving_tuning.max_body_roll
	)
	body.rotation.z = lerpf(body.rotation.z, visual_roll, 1.0 - exp(-7.0 * delta))
	var acceleration_pitch := clampf(
		-player_longitudinal_acceleration * 0.0011,
		-0.028,
		0.038
	)
	var slope_pitch := asin(clampf(ground_route_tangent.y, -0.55, 0.55))
	body.rotation.x = lerpf(
		body.rotation.x,
		acceleration_pitch + slope_pitch,
		1.0 - exp(-5.0 * delta)
	)
	var brake_material: StandardMaterial3D = player.get_meta("brake_material")
	var braking := (
		throttle < 0.0
		or (player_drift_blend > 0.45 and speed_abs > driving_tuning.drift_min_speed)
	)
	var target_brake_energy := 4.2 if braking else 1.15
	brake_material.emission_energy_multiplier = lerpf(
		brake_material.emission_energy_multiplier,
		target_brake_energy,
		1.0 - exp(-9.0 * delta)
		)

	_emit_skid_marks(throttle, speed_abs)
	offroad_label.visible = player_offroad or player_in_shortcut
	if player_in_shortcut:
		offroad_label.text = "捷径路段 · 窄路限速"
	elif player_offroad:
		offroad_label.text = "偏离赛道 · 抓地力下降"


func _make_ai_stats() -> Dictionary:
	return {
		"frames": 0,
		"sim_time": 0.0,
		"speed_sum": 0.0,
		"max_speed": 0.0,
		"max_step": 0.0,
		"offroad_frames": 0,
		"out_of_bounds_frames": 0,
		"shortcut_frames": 0,
		"shortcut_block_frames": 0,
		"zero_speed_frames": 0,
		"stuck_events": 0,
		"recoveries": 0,
		"mistakes": 0,
		"lane_changes": 0,
		"collision_frames": 0,
	}


func _reset_ai_driver_state(ai: Dictionary, start_t: float, lane_offset: float) -> void:
	var profile: Dictionary = ai["profile"]
	var difficulty: Dictionary = DIFFICULTY_PRESETS[difficulty_index]
	var node: Node3D = ai["node"]
	var index := _nearest_track_index(node.global_position)
	ai["lap"] = -1
	ai["velocity"] = Vector3.ZERO
	ai["forward_speed"] = 0.0
	ai["lateral_speed"] = 0.0
	ai["yaw_rate"] = 0.0
	ai["slip_angle"] = 0.0
	ai["steering"] = 0.0
	ai["drift_angle"] = 0.0
	ai["drift_blend"] = 0.0
	ai["drift_charge"] = 18.0
	ai["drifting"] = false
	ai["nitro_time"] = 0.0
	ai["nitro_requested"] = false
	ai["wheel_spin"] = 0.0
	ai["longitudinal_acceleration"] = 0.0
	ai["offroad"] = false
	ai["in_shortcut"] = false
	ai["previous_index"] = index
	ai["progress_index"] = index
	ai["search_tick"] = int(ai["profile_index"])
	ai["lane"] = lane_offset
	ai["target_offset"] = lane_offset
	ai["total"] = -float(track_samples.size()) + float(index)
	ai["rubber_factor"] = 0.0
	var rng: RandomNumberGenerator = ai["rng"]
	ai["launch_timer"] = (
		float(profile["reaction"])
		* float(difficulty["reaction"])
		* rng.randf_range(0.82, 1.18)
	)
	ai["stuck_timer"] = 0.0
	ai["recovery_timer"] = 0.0
	ai["mistake_timer"] = rng.randf_range(7.0, 17.0)
	ai["mistake_time"] = 0.0
	ai["mistake_kind"] = ""
	ai["mistake_sign"] = 1.0
	ai["finished"] = false
	ai["finish_time"] = -1.0
	ai["stats"] = _make_ai_stats()
	ai["start_t"] = start_t
	var body := node.get_child(0)
	body.rotation = Vector3.ZERO
	var boost_flames: Array = node.get_meta("boost_flames")
	for flame in boost_flames:
		flame.visible = false


func _build_ai_track_profile() -> void:
	var count := track_samples.size()
	if count == 0:
		return
	var sample_distance := track_length / float(count)
	ai_corner_offsets.resize(count)
	ai_speed_limits.resize(count)
	ai_shortcut_guard_offsets.resize(count)
	ai_track_curvature.resize(count)
	ai_shortcut_entry_indices.clear()
	for i in count:
		ai_corner_offsets[i] = 0.0
		ai_shortcut_guard_offsets[i] = 0.0
	var raw_curvature := PackedFloat32Array()
	raw_curvature.resize(count)
	var tangent_window := maxi(4, int(16.0 / maxf(sample_distance, 0.1)))
	for i in count:
		var behind := track_tangents[posmod(i - tangent_window, count)]
		var ahead := track_tangents[posmod(i + tangent_window, count)]
		raw_curvature[i] = (
			behind.signed_angle_to(ahead, Vector3.UP)
			/ maxf(sample_distance * float(tangent_window * 2), 0.1)
		)
	for i in count:
		var total := 0.0
		for offset in range(-3, 4):
			total += raw_curvature[posmod(i + offset, count)]
		ai_track_curvature[i] = total / 7.0

	var peak_indices: Array[int] = []
	var peak_window := maxi(7, int(38.0 / maxf(sample_distance, 0.1)))
	for i in count:
		var strength := absf(ai_track_curvature[i])
		if strength < 0.0045:
			continue
		var is_peak := true
		for offset in range(-peak_window, peak_window + 1):
			if absf(ai_track_curvature[posmod(i + offset, count)]) > strength * 1.015:
				is_peak = false
				break
		if is_peak:
			peak_indices.append(i)

	var usable_width := maxf(road_half_width - 1.65, 2.5)
	for peak_index in peak_indices:
		var curvature := ai_track_curvature[peak_index]
		var direction := signf(curvature)
		if absf(direction) < 0.01:
			continue
		var strength := clampf(absf(curvature) / 0.026, 0.28, 1.0)
		var entry_length := maxi(8, int((18.0 + 30.0 * strength) / maxf(sample_distance, 0.1)))
		var exit_length := maxi(7, int(float(entry_length) * 0.78))
		var inside_offset := usable_width * (0.56 + strength * 0.34)
		var outside_offset := usable_width * (0.38 + strength * 0.12)
		for step in range(-entry_length, exit_length + 1):
			var normalized := (
				float(step) / float(entry_length)
				if step < 0
				else float(step) / float(exit_length)
			)
			var apex_blend := sin(PI * 0.5 * (1.0 - absf(normalized)))
			var offset := (
				direction * outside_offset * (1.0 - apex_blend)
				- direction * inside_offset * apex_blend
			)
			var sample_index := posmod(peak_index + step, count)
			ai_corner_offsets[sample_index] = clampf(
				ai_corner_offsets[sample_index] + offset,
				-usable_width,
				usable_width
			)

	for shortcut_index in shortcut_samples.size():
		var points := shortcut_samples[shortcut_index]
		if points.is_empty():
			continue
		var entry_index := _nearest_track_index(points[0])
		var entry_tangent := track_tangents[entry_index]
		var entry_side := Vector3.UP.cross(entry_tangent).normalized()
		var outward_sign := signf((points[0] - track_samples[entry_index]).dot(entry_side))
		if absf(outward_sign) < 0.01:
			outward_sign = 1.0
		ai_shortcut_entry_indices.append(entry_index)
		var guard_samples := maxi(6, int(22.0 / maxf(sample_distance, 0.1)))
		for offset in range(-guard_samples, guard_samples + 1):
			var weight := 1.0 - float(abs(offset)) / float(guard_samples + 1)
			var guard_index := posmod(entry_index + offset, count)
			var guard_offset := -outward_sign * usable_width * 0.72 * weight
			if absf(guard_offset) > absf(ai_shortcut_guard_offsets[guard_index]):
				ai_shortcut_guard_offsets[guard_index] = guard_offset

	var raw_limits := PackedFloat32Array()
	raw_limits.resize(count)
	for i in count:
		var curvature := absf(ai_track_curvature[i])
		if curvature < 0.0032:
			raw_limits[i] = driving_tuning.max_forward_speed
		else:
			var radius := 1.0 / curvature
			raw_limits[i] = clampf(sqrt(7.2 * radius), 11.5, driving_tuning.max_forward_speed)
	for i in count:
		var speed_limit := raw_limits[i]
		for ahead in range(1, 31):
			var next_index := posmod(i + ahead, count)
			var braking_distance := float(ahead) * sample_distance
			var approach_limit := sqrt(
				raw_limits[next_index] * raw_limits[next_index]
				+ 2.0 * AI_BRAKE_DECEL * braking_distance
			)
			speed_limit = minf(speed_limit, approach_limit)
		ai_speed_limits[i] = clampf(
			speed_limit,
			10.5,
			driving_tuning.max_forward_speed
		)


func _ai_total_progress(ai: Dictionary) -> float:
	return float(ai["lap"]) * float(track_samples.size()) + float(ai["progress_index"])


func _update_ai(delta: float, countdown: bool) -> void:
	if countdown:
		for ai in ai_cars:
			ai["velocity"] = Vector3.ZERO
			ai["forward_speed"] = 0.0
			ai["lateral_speed"] = 0.0
			ai["nitro_requested"] = false
		return

	var difficulty: Dictionary = DIFFICULTY_PRESETS[difficulty_index]
	var player_total := (
		float(player_lap) * float(track_samples.size())
		+ float(player_progress_index)
	)
	var sample_distance := track_length / float(maxi(track_samples.size(), 1))
	var usable_width := maxf(road_half_width - 1.65, 2.5)
	for ai_index in ai_cars.size():
		var ai: Dictionary = ai_cars[ai_index]
		var node: Node3D = ai["node"]
		var profile: Dictionary = ai["profile"]
		var stats: Dictionary = ai["stats"]
		var old_position := node.global_position

		ai["search_tick"] = int(ai["search_tick"]) + 1
		var full_search := (
			int(ai["search_tick"]) % 30 == 0
			or bool(ai["offroad"])
		)
		var nearest := _nearest_track_point(
			node.global_position,
			int(ai["progress_index"]),
			full_search
		)
		var track_index: int = int(nearest["index"])
		var track_center: Vector3 = nearest["center"]
		var track_side: Vector3 = nearest["side"]
		var speed := float(ai["forward_speed"])
		var speed_abs := absf(speed)
		var distance_from_center: float = float(nearest["distance"])
		ai["in_shortcut"] = _is_in_shortcut(node.global_position)
		ai["offroad"] = (
			not bool(ai["in_shortcut"])
			and distance_from_center > road_half_width + 0.7
		)
		if bool(ai["offroad"]):
			stats["offroad_frames"] = int(stats["offroad_frames"]) + 1
		if distance_from_center > offroad_limit + 0.35:
			stats["out_of_bounds_frames"] = int(stats["out_of_bounds_frames"]) + 1
		if bool(ai["in_shortcut"]):
			stats["shortcut_frames"] = int(stats["shortcut_frames"]) + 1

		var forward := -node.global_transform.basis.z
		var right := node.global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()

		var corner_limit := ai_speed_limits[track_index]
		var corner_weight := 1.0 - clampf(
			(corner_limit - 12.0)
			/ maxf(driving_tuning.max_forward_speed - 12.0, 1.0),
			0.0,
			1.0
		)
		var profile_speed_mix := lerpf(
			float(profile["speed"]),
			float(profile["corner"]),
			corner_weight
		)
		var difficulty_speed_mix := lerpf(
			float(difficulty["speed"]),
			float(difficulty["corner"]),
			corner_weight
		)
		var target_speed := corner_limit * profile_speed_mix * difficulty_speed_mix
		var target_offset := float(ai_corner_offsets[track_index])
		var guard_offset := float(ai_shortcut_guard_offsets[track_index])
		if absf(guard_offset) > 0.08:
			target_offset = lerpf(target_offset, guard_offset, 0.82)
		target_offset += float(profile["line_bias"]) * 0.34
		target_offset += (
			sin(race_elapsed_time * 0.42 + float(ai["lane_phase"]))
			* 0.30
			* (1.0 - corner_weight)
		)

		var progress_gap := player_total - _ai_total_progress(ai)
		var rubber_target := clampf(
			(progress_gap * sample_distance - 24.0)
			/ 360.0
			* RUBBER_BAND_LIMIT,
			-RUBBER_BAND_LIMIT,
			RUBBER_BAND_LIMIT
		)
		ai["rubber_factor"] = _smooth_value(
			float(ai["rubber_factor"]),
			rubber_target,
			0.85,
			delta
		)
		target_speed *= 1.0 + float(ai["rubber_factor"])
		if float(ai["nitro_time"]) > 0.0:
			target_speed += 7.0
		if bool(ai["finished"]):
			target_speed = minf(target_speed, 26.0)

		var traffic_brake := 0.0
		var pass_side := float(ai["pass_side"])
		for other_index in ai_cars.size():
			if other_index == ai_index:
				continue
			var other: Dictionary = ai_cars[other_index]
			var other_node: Node3D = other["node"]
			var relative := other_node.global_position - node.global_position
			relative.y = 0.0
			var ahead_distance := relative.dot(forward)
			var lateral_distance := relative.dot(track_side)
			if ahead_distance <= 0.8 or ahead_distance >= 18.0:
				continue
			if absf(lateral_distance) >= 3.2:
				continue
			var closing_speed := speed - float(other["forward_speed"])
			if ahead_distance < 7.2 and closing_speed > 0.0:
				traffic_brake = maxf(
					traffic_brake,
					clampf((7.2 - ahead_distance) / 4.8, 0.0, 1.0)
				)
			var room_left := road_half_width - 1.25 - lateral_distance
			var room_right := road_half_width - 1.25 + lateral_distance
			var chosen_side := pass_side
			if room_left < 1.9 and room_right > room_left:
				chosen_side = -1.0
			elif room_right < 1.9 and room_left > room_right:
				chosen_side = 1.0
			var pass_commit := (
				clampf((18.0 - ahead_distance) / 14.0, 0.0, 1.0)
				* float(difficulty["racecraft"])
			)
			var pass_offset := clampf(
				lateral_distance + chosen_side * 2.45,
				-usable_width,
				usable_width
			)
			target_offset = lerpf(target_offset, pass_offset, pass_commit * 0.72)
			ai["pass_side"] = chosen_side
		if traffic_brake > 0.0:
			target_speed *= 1.0 - traffic_brake * 0.38

		if player and player.visible:
			var player_relative := player.global_position - node.global_position
			player_relative.y = 0.0
			var player_ahead := player_relative.dot(forward)
			var player_lateral := player_relative.dot(track_side)
			if player_ahead > 0.8 and player_ahead < 16.0 and absf(player_lateral) < 3.0:
				var player_speed := maxf(player_velocity.dot(forward), 0.0)
				var player_closing := speed - player_speed
				if player_ahead < 7.0 and player_closing > 0.0:
					traffic_brake = maxf(
						traffic_brake,
						clampf((7.0 - player_ahead) / 4.6, 0.0, 1.0)
					)
				var avoid_side := -1.0 if player_lateral > 0.0 else 1.0
				target_offset = lerpf(
					target_offset,
					clampf(player_lateral + avoid_side * 2.4, -usable_width, usable_width),
					0.46 * float(difficulty["racecraft"])
				)
			elif (
				player_ahead < -1.0
				and player_ahead > -13.0
				and absf(player_lateral) < 1.5
				and float(profile["aggression"]) > 0.42
			):
				target_offset = lerpf(target_offset, player_lateral, 0.38)

		ai["mistake_timer"] = float(ai["mistake_timer"]) - delta
		if float(ai["mistake_timer"]) <= 0.0 and not bool(ai["offroad"]):
			var mistake_roll := float(ai["rng"].randf())
			if mistake_roll < 0.34:
				ai["mistake_kind"] = "late_brake"
			elif mistake_roll < 0.68:
				ai["mistake_kind"] = "wide"
			else:
				ai["mistake_kind"] = "lift"
			ai["mistake_time"] = ai["rng"].randf_range(0.55, 1.35)
			ai["mistake_sign"] = -1.0 if ai["rng"].randf() < 0.5 else 1.0
			stats["mistakes"] = int(stats["mistakes"]) + 1
			ai["mistake_timer"] = (
				ai["rng"].randf_range(8.0, 21.0)
				/ maxf(
					float(profile["mistake"]) * float(difficulty["mistake"]),
					0.15
				)
			)
		if float(ai["mistake_time"]) > 0.0:
			ai["mistake_time"] = maxf(0.0, float(ai["mistake_time"]) - delta)
			match String(ai["mistake_kind"]):
				"late_brake":
					target_speed *= 1.075
				"wide":
					target_offset += float(ai["mistake_sign"]) * 2.15
				"lift":
					target_speed = minf(target_speed, 15.5)

		var center_offset := (node.global_position - track_center).dot(track_side)
		if bool(ai["offroad"]) or bool(ai["in_shortcut"]):
			target_offset = clampf(-center_offset * 0.72, -usable_width, usable_width)
			target_speed = minf(target_speed, 14.0)
		if speed_abs < 1.8 and race_elapsed_time > 3.0:
			ai["stuck_timer"] = float(ai["stuck_timer"]) + delta
		else:
			ai["stuck_timer"] = maxf(0.0, float(ai["stuck_timer"]) - delta * 1.8)
		if float(ai["stuck_timer"]) > 1.55 and float(ai["recovery_timer"]) <= 0.0:
			ai["recovery_timer"] = 1.05
			ai["stuck_timer"] = 0.0
			stats["stuck_events"] = int(stats["stuck_events"]) + 1
			stats["recoveries"] = int(stats["recoveries"]) + 1
		if float(ai["recovery_timer"]) > 0.0:
			ai["recovery_timer"] = maxf(0.0, float(ai["recovery_timer"]) - delta)
			target_speed = minf(target_speed, 10.0)
			target_offset = clampf(-center_offset * 0.68, -usable_width, usable_width)
		var edge_start := road_half_width - 0.45
		if absf(center_offset) > edge_start:
			var edge_pressure := clampf(
				(absf(center_offset) - edge_start)
				/ maxf(offroad_limit - edge_start, 0.1),
				0.0,
				1.0
			)
			target_offset = lerpf(
				target_offset,
				-center_offset * 0.90,
				edge_pressure * 0.78
			)
			target_speed *= 1.0 - edge_pressure * 0.22
		target_offset = clampf(target_offset, -usable_width, usable_width)

		var sample_step := maxf(sample_distance, 0.1)
		var look_distance := clampf(5.0 + speed_abs * 0.52, 7.0, 23.0)
		var look_index := track_index + int(round(look_distance / sample_step))
		var look_point := track_samples[posmod(look_index, track_samples.size())]
		var look_tangent := track_tangents[posmod(look_index, track_tangents.size())]
		var look_side := Vector3.UP.cross(look_tangent).normalized()
		var look_offset := float(ai_corner_offsets[posmod(look_index, track_samples.size())])
		var look_guard := float(ai_shortcut_guard_offsets[posmod(look_index, track_samples.size())])
		if absf(look_guard) > 0.08:
			look_offset = lerpf(look_offset, look_guard, 0.82)
		var desired_point := look_point + look_side * target_offset
		var desired_direction := desired_point - node.global_position
		desired_direction.y = 0.0
		if desired_direction.length_squared() < 0.01:
			desired_direction = forward
		var heading_error := forward.signed_angle_to(desired_direction.normalized(), Vector3.UP)
		var steering_target := clampf(
			heading_error * 2.55 - float(ai["lateral_speed"]) * 0.045,
			-1.0,
			1.0
		)
		var steering_rate := (
			driving_tuning.steering_input_attack
			if absf(steering_target) >= absf(float(ai["steering"]))
			else driving_tuning.steering_input_release
		)
		ai["steering"] = _smooth_value(
			float(ai["steering"]),
			steering_target,
			steering_rate,
			delta
		)

		var throttle := 0.0
		if float(ai["launch_timer"]) > 0.0:
			ai["launch_timer"] = maxf(0.0, float(ai["launch_timer"]) - delta)
		elif float(ai["recovery_timer"]) > 0.0 and speed > -3.0:
			throttle = -1.0
		elif speed < target_speed - 0.7:
			throttle = 1.0
		elif speed > target_speed + 1.5:
			throttle = -1.0
		else:
			throttle = 0.22
		if traffic_brake > 0.22 and speed > 6.0:
			throttle = -1.0

		var drift_requested := (
			float(profile["drift"]) > 0.62
			and speed_abs > driving_tuning.drift_min_speed
			and corner_weight > 0.38
			and absf(center_offset) < usable_width * 0.58
			and (
				absf(float(ai["steering"])) > 0.25
				or corner_limit < 21.0
			)
		)
		var nitro_requested := (
			float(ai["drift_charge"]) >= 12.0
			and float(ai["nitro_time"]) <= 0.0
			and throttle > 0.4
			and corner_limit > driving_tuning.max_forward_speed * 0.92
			and speed_abs > 18.0
			and traffic_brake < 0.08
			and not bool(ai["offroad"])
		)
		if nitro_requested:
			ai["nitro_time"] = clampf(0.75 + float(ai["drift_charge"]) / 72.0, 0.75, 1.8)
			ai["drift_charge"] = maxf(
				0.0,
				float(ai["drift_charge"]) - driving_tuning.nitro_activation_cost
			)
		var boost_active := float(ai["nitro_time"]) > 0.0
		var maximum_speed := (
			driving_tuning.nitro_max_speed
			if boost_active
			else driving_tuning.max_forward_speed
		)
		var previous_forward_speed := speed
		var traction_multiplier := (
			driving_tuning.offroad_traction_multiplier
			if bool(ai["offroad"])
			else 1.0
		)
		if throttle > 0.0:
			if speed < -1.0:
				speed = move_toward(
					speed,
					0.0,
					driving_tuning.brake_deceleration * 0.82 * delta
				)
			else:
				var speed_ratio := clampf(
					maxf(speed, 0.0) / maximum_speed,
					0.0,
					1.0
				)
				var engine_force := lerpf(
					driving_tuning.high_speed_acceleration,
					driving_tuning.launch_acceleration,
					pow(1.0 - speed_ratio, driving_tuning.acceleration_curve_power)
				)
				if boost_active:
					engine_force += driving_tuning.nitro_acceleration_bonus * (
						0.72 + 0.28 * (1.0 - speed_ratio)
					)
				speed += engine_force * traction_multiplier * delta
		elif throttle < 0.0:
			if speed > 1.0:
				var brake_force := driving_tuning.brake_deceleration * (
					1.0
					+ driving_tuning.brake_high_speed_bonus
					* clampf(speed / driving_tuning.max_forward_speed, 0.0, 1.0)
				)
				speed = move_toward(
					speed,
					0.0,
					brake_force * traction_multiplier * delta
				)
			else:
				speed -= driving_tuning.reverse_acceleration * traction_multiplier * delta
		else:
			var coast_drag := driving_tuning.rolling_drag + (
				driving_tuning.aero_drag * speed * absf(speed)
			)
			speed = move_toward(speed, 0.0, maxf(coast_drag, 0.0) * delta)
		if boost_active and throttle <= 0.0:
			speed += driving_tuning.nitro_acceleration_bonus * 0.72 * delta
		if bool(ai["offroad"]):
			var offroad_limit_speed := maximum_speed * driving_tuning.offroad_speed_factor
			if speed > offroad_limit_speed:
				speed = lerpf(
					speed,
					offroad_limit_speed,
					1.0 - exp(-driving_tuning.offroad_overspeed_recovery * delta)
				)
			speed = move_toward(
				speed,
				0.0,
				driving_tuning.offroad_extra_drag * delta
			)

		speed_abs = absf(speed)
		var slip_seed := absf(atan2(float(ai["lateral_speed"]), maxf(speed_abs, 1.0)))
		drift_requested = (
			drift_requested
			and speed_abs > driving_tuning.drift_min_speed
			and (absf(float(ai["steering"])) > 0.18 or slip_seed > 0.07)
		)
		var countersteer := 0.0
		if absf(float(ai["lateral_speed"])) > 0.15:
			countersteer = clampf(
				-signf(float(ai["lateral_speed"])) * float(ai["steering"]),
				0.0,
				1.0
			)
		var target_drift_blend := 1.0 if drift_requested else 0.0
		if drift_requested and countersteer > 0.02:
			target_drift_blend = maxf(0.0, 1.0 - countersteer * 0.55)
		var drift_blend_rate := (
			driving_tuning.drift_entry_rate
			if target_drift_blend > float(ai["drift_blend"])
			else driving_tuning.drift_exit_rate
		)
		if countersteer > 0.02:
			drift_blend_rate = maxf(
				drift_blend_rate,
				driving_tuning.drift_exit_rate * 0.72
			)
		ai["drift_blend"] = _smooth_value(
			float(ai["drift_blend"]),
			target_drift_blend,
			drift_blend_rate,
			delta
		)
		ai["drifting"] = (
			float(ai["drift_blend"]) > 0.26
			and speed_abs > driving_tuning.drift_min_speed
		)

		var speed_ratio := clampf(
			speed_abs / driving_tuning.max_forward_speed,
			0.0,
			1.0
		)
		var yaw_authority := lerpf(
			driving_tuning.low_speed_yaw_rate,
			driving_tuning.high_speed_yaw_rate,
			pow(speed_ratio, 1.05)
		)
		if speed_abs < driving_tuning.steering_min_speed:
			yaw_authority *= smoothstep(
				0.0,
				driving_tuning.steering_min_speed,
				speed_abs
			)
		yaw_authority *= lerpf(
			1.0,
			driving_tuning.drift_yaw_multiplier,
			float(ai["drift_blend"])
		)
		if bool(ai["offroad"]):
			yaw_authority *= 0.78
		var reverse_sign := -1.0 if speed < 0.0 else 1.0
		var target_yaw_rate := float(ai["steering"]) * yaw_authority * reverse_sign
		target_yaw_rate = clampf(
			target_yaw_rate,
			-driving_tuning.max_yaw_rate,
			driving_tuning.max_yaw_rate
		)
		ai["yaw_rate"] = _smooth_value(
			float(ai["yaw_rate"]),
			target_yaw_rate,
			12.0,
			delta
		)
		node.rotate_y(float(ai["yaw_rate"]) * delta)

		forward = -node.global_transform.basis.z
		right = node.global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		forward = forward.normalized()
		right = right.normalized()
		var slip_generation := driving_tuning.slip_generation + (
			driving_tuning.drift_slip_generation_bonus * float(ai["drift_blend"])
		)
		ai["lateral_speed"] = float(ai["lateral_speed"]) + (
			float(ai["yaw_rate"]) * speed_abs * slip_generation * delta
		)
		var lateral_grip := lerpf(
			driving_tuning.normal_lateral_grip,
			driving_tuning.drift_lateral_grip,
			float(ai["drift_blend"])
		)
		lateral_grip += driving_tuning.countersteer_grip_bonus * countersteer
		if bool(ai["offroad"]):
			lateral_grip *= driving_tuning.offroad_grip_multiplier
		ai["lateral_speed"] = float(ai["lateral_speed"]) * exp(
			-maxf(lateral_grip, 0.1) * delta
		)
		var slip_limit_degrees := lerpf(
			driving_tuning.max_normal_slip_angle_degrees,
			driving_tuning.max_slip_angle_degrees,
			float(ai["drift_blend"])
		)
		var slip_limit := tan(deg_to_rad(slip_limit_degrees)) * maxf(speed_abs, 1.0)
		if absf(float(ai["lateral_speed"])) > slip_limit:
			ai["lateral_speed"] = signf(float(ai["lateral_speed"])) * slip_limit
			ai["yaw_rate"] = float(ai["yaw_rate"]) * 0.82
		ai["slip_angle"] = atan2(
			float(ai["lateral_speed"]),
			maxf(speed_abs, 1.0)
		)
		ai["drift_angle"] = absf(float(ai["slip_angle"]))
		if bool(ai["drifting"]):
			speed *= exp(-driving_tuning.drift_drag * delta)

		var charge_speed_ratio := clampf(
			speed_abs / driving_tuning.max_forward_speed,
			0.0,
			1.0
		)
		if speed_abs > 5.0 and float(ai["nitro_time"]) <= 0.0:
			var charge_rate := driving_tuning.nitro_passive_charge * pow(
				charge_speed_ratio,
				0.82
			)
			charge_rate += (
				absf(float(ai["steering"]))
				* driving_tuning.nitro_steering_charge
				* charge_speed_ratio
			)
			if float(ai["drift_blend"]) > 0.08:
				charge_rate += (
					driving_tuning.nitro_drift_charge
					+ minf(float(ai["drift_angle"]), 0.76)
					* driving_tuning.nitro_drift_angle_charge
				) * float(ai["drift_blend"])
			ai["drift_charge"] = minf(
				100.0,
				float(ai["drift_charge"]) + charge_rate * delta
			)
		else:
			ai["drift_charge"] = maxf(
				0.0,
				float(ai["drift_charge"]) - delta * 1.8
			)
		if float(ai["nitro_time"]) > 0.0:
			ai["nitro_time"] = maxf(0.0, float(ai["nitro_time"]) - delta)
		ai["nitro_requested"] = float(ai["nitro_time"]) > 0.0

		speed = clampf(
			speed,
			-driving_tuning.reverse_max_speed,
			maximum_speed + 2.0
		)
		if bool(ai["in_shortcut"]):
			speed = minf(speed, maximum_speed * 0.90)
		ai["forward_speed"] = speed
		ai["velocity"] = forward * speed + right * float(ai["lateral_speed"])
		ai["longitudinal_acceleration"] = _smooth_value(
			float(ai["longitudinal_acceleration"]),
			(speed - previous_forward_speed) / maxf(delta, 0.0001),
			9.0,
			delta
		)
		node.global_position += ai["velocity"] * delta

		var ground_tangent := track_tangents[track_index]
		var ground_target_y := curve.sample_baked(
			float(track_index) / float(track_samples.size()) * track_length,
			true
		).y + 0.055
		ai["in_shortcut"] = _is_in_shortcut(node.global_position)
		if bool(ai["in_shortcut"]):
			var shortcut_info := _nearest_shortcut_sample(node.global_position)
			ground_target_y = float(shortcut_info["center"].y) + 0.15
			ground_tangent = shortcut_info["tangent"]
		node.global_position.y = lerpf(
			node.global_position.y,
			ground_target_y,
			1.0 - exp(-24.0 * delta)
		)
		_resolve_ai_boundary(ai, nearest)

		ai["previous_index"] = int(ai["progress_index"])
		ai["search_tick"] = int(ai["search_tick"]) + 1
		var refreshed := _nearest_track_point(
			node.global_position,
			int(ai["progress_index"]),
			false
		)
		var progress_index := int(refreshed["index"])
		var previous_index := int(ai["previous_index"])
		if previous_index > int(track_samples.size() * 0.8) and progress_index < int(track_samples.size() * 0.2):
			ai["lap"] = int(ai["lap"]) + 1
			if int(ai["lap"]) >= total_laps and not bool(ai["finished"]):
				ai["finished"] = true
				ai["finish_time"] = race_elapsed_time
		elif previous_index < int(track_samples.size() * 0.2) and progress_index > int(track_samples.size() * 0.8):
			ai["lap"] = maxi(-1, int(ai["lap"]) - 1)
		ai["progress_index"] = progress_index
		ai["total"] = _ai_total_progress(ai)

		if _ai_is_at_shortcut_entry(progress_index):
			var entry_direction := track_tangents[progress_index]
			if ai["velocity"].dot(entry_direction) < 5.0:
				stats["shortcut_block_frames"] = int(stats["shortcut_block_frames"]) + 1

		var step_distance := old_position.distance_to(node.global_position)
		stats["frames"] = int(stats["frames"]) + 1
		stats["sim_time"] = float(stats["sim_time"]) + delta
		stats["speed_sum"] = float(stats["speed_sum"]) + absf(speed)
		stats["max_speed"] = maxf(float(stats["max_speed"]), absf(speed))
		stats["max_step"] = maxf(float(stats["max_step"]), step_distance)
		if speed_abs < 0.8 and float(ai["launch_timer"]) <= 0.0:
			stats["zero_speed_frames"] = int(stats["zero_speed_frames"]) + 1
		_update_ai_visuals(ai, throttle, ground_tangent, delta)
	_resolve_ai_contact()


func _ai_is_at_shortcut_entry(track_index: int) -> bool:
	for entry_index in ai_shortcut_entry_indices:
		var difference := absi(track_index - entry_index)
		difference = mini(difference, track_samples.size() - difference)
		if difference <= 4:
			return true
	return false


func _resolve_ai_boundary(ai: Dictionary, nearest: Dictionary) -> void:
	if bool(ai["in_shortcut"]):
		return
	if float(nearest["distance"]) <= offroad_limit:
		return
	var node: Node3D = ai["node"]
	var center: Vector3 = nearest["center"]
	var side: Vector3 = nearest["side"]
	var signed_distance := (node.global_position - center).dot(side)
	var direction := signf(signed_distance)
	if absf(direction) < 0.01:
		direction = 1.0
	var velocity: Vector3 = ai["velocity"]
	var outward_speed := maxf(velocity.dot(side * direction), 0.0)
	var target_position := center + side * direction * (offroad_limit - 0.08)
	var correction := target_position - node.global_position
	if correction.length_squared() > 0.0001:
		node.global_position += correction.normalized() * minf(correction.length(), 0.32)
	velocity -= side * direction * outward_speed * 1.18
	velocity *= driving_tuning.collision_speed_retention
	ai["velocity"] = velocity
	ai["forward_speed"] = float(ai["forward_speed"]) * (
		driving_tuning.collision_speed_retention
		+ (1.0 - driving_tuning.collision_speed_retention) * 0.35
	)
	ai["lateral_speed"] = float(ai["lateral_speed"]) * driving_tuning.collision_lateral_retention


func _update_ai_visuals(
	ai: Dictionary,
	throttle: float,
	ground_tangent: Vector3,
	delta: float
) -> void:
	var node: Node3D = ai["node"]
	var speed := float(ai["forward_speed"])
	ai["wheel_spin"] = float(ai["wheel_spin"]) + speed * delta * 2.8
	var all_wheels: Array = node.get_meta("all_wheels")
	for wheel in all_wheels:
		wheel.rotation = Vector3(
			float(ai["wheel_spin"]),
			float(ai["steering"]) * 0.42 if wheel.position.z < 0.0 else 0.0,
			0.0
		)
	var body := node.get_child(0)
	var visual_roll := (
		-float(ai["steering"])
		* (
			driving_tuning.body_roll_steering
			+ driving_tuning.body_roll_drift * float(ai["drift_blend"])
		)
		- float(ai["lateral_speed"])
		/ driving_tuning.max_forward_speed
		* driving_tuning.body_roll_lateral
	)
	visual_roll = clampf(
		visual_roll,
		-driving_tuning.max_body_roll,
		driving_tuning.max_body_roll
	)
	body.rotation.z = lerpf(body.rotation.z, visual_roll, 1.0 - exp(-7.0 * delta))
	var acceleration_pitch := clampf(
		-float(ai["longitudinal_acceleration"]) * 0.0011,
		-0.028,
		0.038
	)
	var slope_pitch := asin(clampf(ground_tangent.y, -0.55, 0.55))
	body.rotation.x = lerpf(
		body.rotation.x,
		acceleration_pitch + slope_pitch,
		1.0 - exp(-5.0 * delta)
	)
	var brake_material: StandardMaterial3D = node.get_meta("brake_material")
	var braking := (
		throttle < 0.0
		or (
			float(ai["drift_blend"]) > 0.45
			and absf(speed) > driving_tuning.drift_min_speed
		)
	)
	var target_brake_energy := 4.2 if braking else 1.15
	brake_material.emission_energy_multiplier = lerpf(
		brake_material.emission_energy_multiplier,
		target_brake_energy,
		1.0 - exp(-9.0 * delta)
	)
	var boost_flames: Array = node.get_meta("boost_flames")
	for flame in boost_flames:
		flame.visible = bool(ai["nitro_requested"])
		if flame.visible:
			flame.scale = Vector3(
				0.75,
				0.42,
				2.0 + sin(race_time * 35.0 + float(ai["lane_phase"])) * 0.45
			)


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
	var surface_normal := -side * direction
	var corrected_position := center + side * direction * (offroad_limit - 0.08)
	corrected_position.y = player.global_position.y
	player.global_position = corrected_position
	var outward_speed := maxf(player_velocity.dot(side * direction), 0.0)
	var severity := clampf(
		outward_speed / maxf(driving_tuning.max_forward_speed, 1.0),
		0.0,
		1.0
	)
	player_velocity -= side * direction * outward_speed * 1.18
	player_velocity *= driving_tuning.collision_speed_retention
	player_lateral_speed *= driving_tuning.collision_lateral_retention
	player_forward_speed *= (
		driving_tuning.collision_speed_retention
		+ (1.0 - driving_tuning.collision_speed_retention) * 0.35
	)
	if severity > 0.08:
		_register_collision(surface_normal, severity)


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
	for left_index in ai_cars.size():
		for right_index in range(left_index + 1, ai_cars.size()):
			var left: Dictionary = ai_cars[left_index]
			var right_ai: Dictionary = ai_cars[right_index]
			var left_node: Node3D = left["node"]
			var right_node: Node3D = right_ai["node"]
			var offset := right_node.global_position - left_node.global_position
			offset.y = 0.0
			var distance := offset.length()
			if distance >= CAR_CONTACT_RADIUS:
				continue
			var direction := offset.normalized() if distance > 0.04 else Vector3.RIGHT
			var overlap := minf(CAR_CONTACT_RADIUS - distance, 0.24)
			left_node.global_position -= direction * overlap * 0.5
			right_node.global_position += direction * overlap * 0.5
			var left_velocity: Vector3 = left["velocity"]
			var right_velocity: Vector3 = right_ai["velocity"]
			var relative_velocity := right_velocity - left_velocity
			var closing_speed := maxf(-relative_velocity.dot(direction), 0.0)
			left_velocity -= direction * closing_speed * 0.24
			right_velocity += direction * closing_speed * 0.24
			left["velocity"] = left_velocity
			right_ai["velocity"] = right_velocity
			left["forward_speed"] = float(left["forward_speed"]) * 0.992
			right_ai["forward_speed"] = float(right_ai["forward_speed"]) * 0.992
			var left_stats: Dictionary = left["stats"]
			var right_stats: Dictionary = right_ai["stats"]
			left_stats["collision_frames"] = int(left_stats["collision_frames"]) + 1
			right_stats["collision_frames"] = int(right_stats["collision_frames"]) + 1
	if not player or not player.visible:
		return
	for ai in ai_cars:
		var ai_node: Node3D = ai["node"]
		var offset := player.global_position - ai_node.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance >= CAR_CONTACT_RADIUS:
			continue
		var push_direction := offset.normalized() if distance > 0.04 else Vector3.RIGHT
		var overlap := minf(CAR_CONTACT_RADIUS - distance, 0.24)
		player.global_position += push_direction * overlap * 0.58
		ai_node.global_position -= push_direction * overlap * 0.42
		var current_ai_velocity: Vector3 = ai["velocity"]
		var relative_velocity := player_velocity - current_ai_velocity
		var closing_speed := maxf(-relative_velocity.dot(push_direction), 0.0)
		player_velocity += push_direction * closing_speed * 0.23
		var ai_velocity: Vector3 = ai["velocity"]
		ai_velocity -= push_direction * closing_speed * 0.19
		ai["velocity"] = ai_velocity
		player_forward_speed *= 0.988
		ai["forward_speed"] = float(ai["forward_speed"]) * 0.988
		player_lateral_speed += player.global_transform.basis.x.dot(push_direction) * 0.40
		var stats: Dictionary = ai["stats"]
		stats["collision_frames"] = int(stats["collision_frames"]) + 1
		if impact_cooldown <= 0.0 and absf(player_forward_speed) > 8.0:
			_register_collision(
				-push_direction,
				clampf(
					absf(player_forward_speed) / driving_tuning.max_forward_speed,
					0.2,
					0.7
				)
			)


func _register_collision(surface_normal: Vector3, severity: float) -> void:
	var safe_severity := clampf(severity, 0.0, 1.0)
	if safe_severity <= 0.02:
		return
	if impact_cooldown <= 0.0:
		race_audio.play_impact(safe_severity)
		impact_cooldown = driving_tuning.collision_cooldown
	camera_collision_trauma = maxf(
		camera_collision_trauma,
		driving_tuning.collision_camera_trauma * safe_severity
	)
	var local_normal := player.global_transform.basis.inverse() * surface_normal
	camera_collision_kick += (
		local_normal
		* driving_tuning.collision_camera_kick
		* safe_severity
	)


func _nearest_track_index(position: Vector3) -> int:
	return int(_nearest_track_point(position, -1)["index"])


func _nearest_track_point(
	position: Vector3,
	guess: int,
	full_search: bool = true
) -> Dictionary:
	var best_index := 0
	var best_distance := INF
	var start_index := 0
	var end_index := track_samples.size()
	if guess >= 0 and full_search:
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
		ai["total"] = _ai_total_progress(ai)
		if float(ai["total"]) > player_total:
			place += 1
	player_place = place


func _update_camera(delta: float) -> void:
	if not player_camera:
		return
	var speed_ratio := clampf(
		absf(player_forward_speed) / driving_tuning.max_forward_speed,
		0.0,
		1.0
	)
	var target_fov := driving_tuning.base_fov + (
		driving_tuning.speed_fov_gain
		* pow(speed_ratio, 0.78)
	)
	if nitro_requested:
		target_fov += driving_tuning.nitro_fov_boost
	target_fov += camera_collision_trauma * 2.5
	var fov_rate := (
		driving_tuning.fov_attack_rate
		if target_fov > player_camera.fov
		else driving_tuning.fov_release_rate
	)
	player_camera.fov = _smooth_value(
		player_camera.fov,
		target_fov,
		fov_rate,
		delta
	)

	var acceleration_ratio := clampf(
		player_longitudinal_acceleration / driving_tuning.launch_acceleration,
		-0.35,
		1.0
	)
	camera_acceleration_stretch = _smooth_value(
		camera_acceleration_stretch,
		maxf(acceleration_ratio, 0.0),
		8.0 if acceleration_ratio > 0.0 else 3.5,
		delta
	)
	var shake_strength := driving_tuning.base_camera_shake
	if player_drifting:
		shake_strength += (
			driving_tuning.drift_camera_shake
			* clampf(player_drift_angle / 0.75, 0.0, 1.0)
		)
	if nitro_requested:
		shake_strength += driving_tuning.nitro_camera_shake
	shake_strength += (
		driving_tuning.collision_camera_kick
		* camera_collision_trauma
	)
	shake_strength = minf(shake_strength, 0.12)
	var shake := Vector3(
		sin(race_time * 53.0) * shake_strength,
		sin(race_time * 67.0) * shake_strength * 0.62,
		sin(race_time * 41.0) * shake_strength * 0.24
	)
	var target_position := camera_base_position
	target_position.z += (
		driving_tuning.acceleration_camera_stretch
		* camera_acceleration_stretch
		* (1.0 + 0.35 * float(nitro_requested))
	)
	target_position += camera_collision_kick
	target_position += shake
	player_camera.position = player_camera.position.lerp(
		target_position,
		1.0 - exp(-18.0 * delta)
	)
	var camera_roll := (
		-player_steering * 0.012
		- player_lateral_speed / driving_tuning.max_forward_speed * 0.018
		+ sin(race_time * 37.0) * camera_collision_trauma * 0.035
	)
	var target_rotation := camera_base_rotation + Vector3(
		clampf(-player_longitudinal_acceleration * 0.0012, -0.018, 0.024),
		sin(race_time * 31.0) * camera_collision_trauma * 0.022,
		camera_roll
	)
	player_camera.rotation = player_camera.rotation.lerp(
		target_rotation,
		1.0 - exp(-14.0 * delta)
	)
	camera_collision_kick *= exp(-10.5 * delta)
	camera_collision_trauma = maxf(0.0, camera_collision_trauma - delta * 1.55)


func _update_camera_idle(delta: float) -> void:
	if not player_camera:
		return
	player_camera.position = player_camera.position.lerp(camera_base_position, 1.0 - exp(-8.0 * delta))
	player_camera.rotation = player_camera.rotation.lerp(
		camera_base_rotation,
		1.0 - exp(-8.0 * delta)
	)
	player_camera.fov = _smooth_value(
		player_camera.fov,
		driving_tuning.base_fov,
		3.0,
		delta
	)
	camera_collision_kick = camera_collision_kick.lerp(
		Vector3.ZERO,
		1.0 - exp(-8.0 * delta)
	)
	camera_collision_trauma = maxf(0.0, camera_collision_trauma - delta * 1.55)
	camera_acceleration_stretch = _smooth_value(
		camera_acceleration_stretch,
		0.0,
		4.0,
		delta
	)


func _update_menu_camera() -> void:
	if not menu_camera or not player:
		return
	var angle := -1.66
	var focus := player.global_position + Vector3.UP * 0.78
	menu_camera.global_position = focus + Vector3(cos(angle) * 5.15, 2.02, sin(angle) * 5.15)
	var portrait_center := focus - player.global_transform.basis.x * 1.28
	menu_camera.look_at(portrait_center, Vector3.UP)


func _process(delta: float) -> void:
	impact_cooldown = maxf(0.0, impact_cooldown - delta)
	var speed_ratio := clampf(
		absf(player_forward_speed) / driving_tuning.max_forward_speed,
		0.0,
		1.0
	)
	if speed_particles:
		speed_particles.emitting = race_state == "racing" and (
			speed_ratio > 0.48 or player_nitro_time > 0.0
		)
		speed_particles.amount_ratio = clampf(
			0.28 + speed_ratio * 0.72 + (0.24 if player_nitro_time > 0.0 else 0.0),
			0.0,
			1.0
		)
		speed_particles.scale.z = 0.85 + speed_ratio * 0.75 + (
			0.55 if player_nitro_time > 0.0 else 0.0
		)
	if speed_overlay:
		speed_overlay.visible = race_state == "racing" and speed_ratio > 0.38
		speed_overlay_material.set_shader_parameter(
			"intensity",
			clampf((speed_ratio - 0.38) * 0.34, 0.0, 0.24)
		)
	if nitro_overlay:
		nitro_overlay.visible = race_state == "racing" and player_nitro_time > 0.0
		nitro_overlay_material.set_shader_parameter(
			"intensity",
			0.28 if player_nitro_time > 0.0 else 0.0
		)
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
	var speed_kph := int(round(absf(player_forward_speed) * 3.6))
	top_speed_kph = maxi(top_speed_kph, speed_kph)
	var nitro_ratio := clampf(player_drift_charge / 100.0, 0.0, 1.0)
	var drift_ratio := clampf(player_drift_angle / 0.72, 0.0, 1.0)
	var boost_ratio := clampf(player_nitro_time / 1.8, 0.0, 1.0)
	var pulse := 0.5 + sin(race_elapsed_time * 8.5) * 0.5
	if speed_gauge:
		speed_gauge.set_metrics(
			speed_ratio,
			boost_ratio,
			player_drifting,
			player_offroad,
			pulse
		)
	if nitro_gauge:
		nitro_gauge.set_metrics(
			nitro_ratio,
			player_nitro_time > 0.0,
			player_drift_charge >= 10.0,
			pulse
		)
	if drift_gauge:
		drift_gauge.set_metrics(drift_ratio, player_drifting)
	if countdown_lights:
		var lights_lit := 0
		if race_state == "countdown" and last_countdown_value in [1, 2, 3]:
			lights_lit = 4 - last_countdown_value
		countdown_lights.visible = race_state == "countdown"
		countdown_lights.set_state(
			lights_lit,
			race_state == "racing" and race_time < 0.65,
			pulse
		)
	if speed_label:
		speed_label.text = "%03d" % speed_kph
		gear_label.text = "km/h  ·  R" if player_forward_speed < -0.8 else "km/h  ·  D"
	if lap_label:
		lap_label.text = "第 %d / %d 圈" % [mini(player_lap + 1, total_laps), total_laps]
	if place_label:
		place_label.text = "P%d" % player_place
		place_suffix_label.text = "/ %d CARS" % (ai_cars.size() + 1)
	if timer_label:
		timer_label.text = _format_time(race_time if not player_finished else player_finish_time)
	if race_status_label:
		if race_state == "countdown":
			race_status_label.text = "发车程序"
		elif player_lap >= total_laps - 1:
			race_status_label.text = "FINAL LAP · 目标 %.0f 秒" % float(track_catalog[current_track_index]["lap_time"])
		else:
			race_status_label.text = "AI %s · 目标 %.0f 秒" % [
				String(DIFFICULTY_PRESETS[difficulty_index]["name"]),
				float(track_catalog[current_track_index]["lap_time"]),
			]
	if nitro_bar:
		nitro_bar.value = player_drift_charge
	if drift_bar:
		drift_bar.value = drift_ratio * 100.0
	if nitro_state_label and drift_state_label:
		if player_nitro_time > 0.0:
			nitro_state_label.text = "NITRO  BOOST  %d%%" % int(round(nitro_ratio * 100.0))
			nitro_state_label.add_theme_color_override("font_color", Color("#ff9c35"))
		elif player_drift_charge >= 10.0:
			nitro_state_label.text = "NITRO  READY  %d%%" % int(round(nitro_ratio * 100.0))
			nitro_state_label.add_theme_color_override("font_color", Color("#ffe47b"))
		else:
			nitro_state_label.text = "NITRO  巡航 / 漂移充能  %d%%" % int(round(nitro_ratio * 100.0))
			nitro_state_label.add_theme_color_override("font_color", Color("#a9c4ca"))
		var drift_degrees := int(round(rad_to_deg(player_drift_angle)))
		if player_drifting:
			drift_state_label.text = "DRIFT  %d°   CHARGE +" % drift_degrees
			drift_state_label.add_theme_color_override("font_color", Color("#ffb04a"))
		else:
			drift_state_label.text = "DRIFT  %d°" % drift_degrees
			drift_state_label.add_theme_color_override("font_color", Color("#d9e8ec"))
	_update_boost_visuals()
	_update_particle_effects()
	_update_engine_audio(delta)


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
	var speed_abs := absf(player_forward_speed)
	var smoke_intensity := 0.0
	if race_state == "racing":
		if player_drifting:
			smoke_intensity = clampf(
				0.32
				+ player_drift_angle * 1.15
				+ speed_abs / driving_tuning.max_forward_speed * 0.24,
				0.0,
				1.0
			)
		elif player_offroad and speed_abs > 6.0:
			smoke_intensity = clampf(
				0.18 + speed_abs / driving_tuning.max_forward_speed * 0.52,
				0.0,
				0.68
			)
	player_smoke_intensity = smoke_intensity
	var emitting := smoke_intensity > 0.02
	for emitter in smoke_emitters:
		emitter.emitting = emitting
		emitter.amount_ratio = smoke_intensity


func _update_engine_audio(delta: float) -> void:
	if not race_audio:
		return
	var speed_ratio := clampf(
		absf(player_forward_speed) / driving_tuning.max_forward_speed,
		0.0,
		1.0
	)
	var slip_ratio := clampf(player_slip_angle / 0.62, 0.0, 1.0)
	var drift_ratio := clampf(
		maxf(player_drift_blend * 0.72, player_drift_angle / 0.78),
		0.0,
		1.0
	)
	var boost_ratio := clampf(player_nitro_time / 1.8, 0.0, 1.0)
	var throttle := 0.0
	if race_state == "racing":
		if _drive_key_pressed(KEY_W, "throttle"):
			throttle += 1.0
		if _drive_key_pressed(KEY_S, "brake"):
			throttle -= 1.0
	race_audio.update(
		delta,
		race_state,
		speed_ratio,
		drift_ratio,
		slip_ratio,
		boost_ratio,
		player_offroad,
		throttle
	)


func _finish_race() -> void:
	player_finished = true
	race_state = "finished"
	player_finish_time = race_time
	_update_race_place()
	finish_place_label.text = "P%d" % player_place
	finish_time_label.text = _format_time(player_finish_time)
	finish_summary_label.text = "%s · %d 圈 · AI %s" % [
		current_track_name,
		total_laps,
		String(DIFFICULTY_PRESETS[difficulty_index]["name"]),
	]
	finish_stats_label.text = "最高时速 %d km/h   ·   R 重赛   ·   T 返回展厅" % top_speed_kph
	finish_overlay.visible = true
	race_audio.play_ui("confirm")


func _format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var remaining := fmod(seconds, 60.0)
	return "%02d:%06.3f" % [minutes, remaining]


func _reset_race_state() -> void:
	race_state = "waiting"
	race_time = 0.0
	race_elapsed_time = 0.0
	countdown_time = 3.6
	last_countdown_value = 4
	player_lap = 0
	player_finished = false
	player_finish_time = 0.0
	player_velocity = Vector3.ZERO
	player_forward_speed = 0.0
	player_lateral_speed = 0.0
	player_steering = 0.0
	player_yaw_rate = 0.0
	player_slip_angle = 0.0
	player_longitudinal_acceleration = 0.0
	player_drift_angle = 0.0
	player_drift_blend = 0.0
	player_drifting = false
	player_drift_charge = 20.0
	player_nitro_time = 0.0
	player_place = 1
	player_track_t = 0.002
	top_speed_kph = 0
	impact_cooldown = 0.0
	camera_collision_kick = Vector3.ZERO
	camera_collision_trauma = 0.0
	camera_acceleration_stretch = 0.0
	player_smoke_intensity = 0.0
	_reset_skid_emitters()
	if menu_camera:
		menu_camera.current = true
	if player_camera:
		player_camera.current = false


func _reset_race() -> void:
	_return_to_showroom()


func _restart_race() -> void:
	_reset_race_state()
	_prepare_race_grid()
	race_state = "countdown"
	countdown_time = 3.55
	last_countdown_value = 4
	top_speed_kph = 0
	start_overlay.visible = false
	pause_overlay.visible = false
	finish_overlay.visible = false
	center_message.text = "3"
	center_message.modulate.a = 1.0
	race_audio.reset_events()
	race_audio.play_countdown(3)
	_update_race_place()


func _return_to_showroom() -> void:
	_reset_race_state()
	if race_audio:
		race_audio.set_race_active(false)
		race_audio.reset_events()
	_enter_showroom()
	start_overlay.visible = true
	pause_overlay.visible = false
	finish_overlay.visible = false
	center_message.text = ""
	_refresh_track_menu()
	_update_race_place()


func _update_pause_summary() -> void:
	if not pause_summary_label:
		return
	pause_summary_label.text = "P%d / %d   ·   第 %d / %d 圈   ·   %s" % [
		player_place,
		ai_cars.size() + 1,
		mini(player_lap + 1, total_laps),
		total_laps,
		_format_time(race_time),
	]
	if pause_controls_label:
		pause_controls_label.text = "ESC 返回赛道   ·   R 重赛   ·   T 选择赛道"
