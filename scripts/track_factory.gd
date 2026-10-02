class_name TrackFactory
extends RefCounted

const ROAD_WIDTH := 15.0
const HALF_WIDTH := ROAD_WIDTH * 0.5
static var active_half_width := HALF_WIDTH

const QUALITY_BUDGETS := {
	"neon": {
		"max_lights": 48,
		"texture_limit": 1024,
		"camera_far": 420.0,
		"shadow_distance": 190.0,
		"near_cover": 95.0,
		"mid_cover": 185.0,
	},
	"snow": {
		"max_lights": 20,
		"texture_limit": 1024,
		"camera_far": 520.0,
		"shadow_distance": 300.0,
		"near_cover": 150.0,
		"mid_cover": 330.0,
	},
	"loop": {
		"max_lights": 18,
		"texture_limit": 1024,
		"camera_far": 460.0,
		"shadow_distance": 235.0,
		"near_cover": 150.0,
		"mid_cover": 290.0,
	},
}


static func get_track_catalog() -> Array[Dictionary]:
	return [
		{
			"id": "neon",
			"name": "霓虹夜街",
			"subtitle": "小图 · 约 40 秒/圈",
			"laps": 3,
			"lap_time": 40.0,
			"theme_color": Color("#16d9e8"),
		},
		{
			"id": "snow",
			"name": "雪山竞速",
			"subtitle": "大图 · 约 85 秒/圈",
			"laps": 2,
			"lap_time": 85.0,
			"theme_color": Color("#bfe8ff"),
		},
		{
			"id": "loop",
			"name": "环城极速",
			"subtitle": "大图 · 约 90 秒/圈",
			"laps": 2,
			"lap_time": 90.0,
			"theme_color": Color("#ffd256"),
		},
	]


static func get_quality_budget(track_id: String) -> Dictionary:
	return QUALITY_BUDGETS.get(track_id, QUALITY_BUDGETS["loop"])


static func create_curve(track_id: String) -> Curve3D:
	var curve := Curve3D.new()
	var points: Array[Vector3]
	match track_id:
		"snow":
			points = [
				Vector3(0.0, 0.0, 0.0),
				Vector3(210.0, 8.0, -48.0),
				Vector3(405.0, 30.0, -175.0),
				Vector3(455.0, 62.0, -365.0),
				Vector3(375.0, 94.0, -555.0),
				Vector3(205.0, 118.0, -690.0),
				Vector3(15.0, 132.0, -742.0),
				Vector3(-170.0, 126.0, -690.0),
				Vector3(-285.0, 112.0, -585.0),
				Vector3(-205.0, 101.0, -495.0),
				Vector3(-330.0, 86.0, -405.0),
				Vector3(-405.0, 58.0, -245.0),
				Vector3(-310.0, 28.0, -78.0),
				Vector3(-150.0, 8.0, -4.0),
			]
		"loop":
			points = [
				Vector3(0.0, 0.0, 0.0),
				Vector3(288.0, 2.0, -14.0),
				Vector3(532.0, 10.0, -100.0),
				Vector3(632.0, 22.0, -272.0),
				Vector3(588.0, 28.0, -460.0),
				Vector3(452.0, 25.0, -632.0),
				Vector3(252.0, 18.0, -744.0),
				Vector3(20.0, 12.0, -772.0),
				Vector3(-204.0, 9.0, -696.0),
				Vector3(-360.0, 12.0, -540.0),
				Vector3(-436.0, 20.0, -348.0),
				Vector3(-400.0, 29.0, -164.0),
				Vector3(-312.0, 24.0, -66.0),
				Vector3(-344.0, 17.0, -14.0),
				Vector3(-202.0, 10.0, 14.0),
				Vector3(-66.0, 3.0, 3.0),
			]
		_:
			points = [
				Vector3(0.0, 0.0, 0.0),
				Vector3(96.0, 0.0, -4.0),
				Vector3(155.0, 1.0, -42.0),
				Vector3(164.0, 2.0, -102.0),
				Vector3(118.0, 3.0, -158.0),
				Vector3(50.0, 2.0, -178.0),
				Vector3(16.0, 1.0, -228.0),
				Vector3(62.0, 0.0, -282.0),
				Vector3(26.0, 0.0, -340.0),
				Vector3(-48.0, 0.0, -352.0),
				Vector3(-104.0, 1.0, -306.0),
				Vector3(-82.0, 2.0, -244.0),
				Vector3(-28.0, 1.0, -210.0),
				Vector3(-72.0, 0.0, -150.0),
				Vector3(-154.0, 0.0, -126.0),
				Vector3(-190.0, 1.0, -60.0),
				Vector3(-154.0, 1.0, -14.0),
				Vector3(-78.0, 0.0, 10.0),
			]
	for point in points:
		curve.add_point(point)
	curve.closed = true
	curve.bake_interval = 0.6
	return curve


static func tangent_at(curve: Curve3D, offset: float, length: float) -> Vector3:
	var ahead := curve.sample_baked(fposmod(offset + 0.8, length), true)
	var behind := curve.sample_baked(fposmod(offset - 0.8, length), true)
	var tangent := ahead - behind
	return tangent.normalized()


static func side_at(curve: Curve3D, offset: float, length: float) -> Vector3:
	var tangent := tangent_at(curve, offset, length)
	return Vector3.UP.cross(tangent).normalized()


static func make_road_material(theme_id: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	if theme_id == "snow":
		material.albedo_texture = load("res://assets/textures/asphalt_snow_diffuse.jpg")
		material.albedo_color = Color(0.72, 0.80, 0.86)
		material.normal_texture = load("res://assets/textures/asphalt_snow_normal.jpg")
		material.roughness_texture = load("res://assets/textures/asphalt_snow_roughness.jpg")
		material.roughness = 0.82
		material.metallic = 0.02
	elif theme_id == "neon":
		material.albedo_texture = load("res://assets/textures/asphalt_diffuse.jpg")
		material.albedo_color = Color(0.19, 0.25, 0.34)
		material.normal_texture = load("res://assets/textures/asphalt_normal.jpg")
		material.roughness_texture = load("res://assets/textures/asphalt_roughness.jpg")
		material.roughness = 0.46
		material.metallic = 0.30
		material.emission_enabled = true
		material.emission = Color("#0b1823")
		material.emission_energy_multiplier = 0.42
	else:
		material.albedo_texture = load("res://assets/textures/asphalt_diffuse.jpg")
		material.albedo_color = Color(0.49, 0.53, 0.55)
		material.normal_texture = load("res://assets/textures/asphalt_normal.jpg")
		material.roughness_texture = load("res://assets/textures/asphalt_roughness.jpg")
		material.roughness = 0.76
		material.metallic = 0.06
	material.normal_enabled = true
	material.normal_scale = 1.05 if theme_id != "snow" else 0.72
	material.uv1_scale = Vector3(1.0, 1.0, 1.0)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


static func make_grass_material(theme_id: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	if theme_id == "snow":
		material.albedo_texture = load("res://assets/textures/snow_diffuse.jpg")
		material.albedo_color = Color(0.88, 0.94, 1.0)
	elif theme_id == "neon":
		material.albedo_color = Color("#101725")
	else:
		material.albedo_texture = load("res://assets/textures/grass.jpg")
		material.albedo_color = Color(0.65, 0.82, 0.54)
	material.roughness = 0.96
	material.uv1_scale = Vector3(80.0, 80.0, 1.0)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


static func build_road_mesh(
		curve: Curve3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		theme_id: String
	) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := samples.size()
	var distance := 0.0
	var lane_offsets := [-1.0, -0.58, 0.0, 0.58, 1.0]
	var crown_profile := [0.0, 0.018, 0.046, 0.018, 0.0]
	for i in range(count):
		var next_index := (i + 1) % count
		var p0 := samples[i]
		var p1 := samples[next_index]
		var t0 := tangents[i]
		var t1 := tangents[next_index]
		var r0 := Vector3.UP.cross(t0).normalized()
		var r1 := Vector3.UP.cross(t1).normalized()
		var segment_length := p0.distance_to(p1)
		var normal0 := t0.cross(r0).normalized()
		var normal1 := t1.cross(r1).normalized()
		for section in lane_offsets.size() - 1:
			var offset_a: float = lane_offsets[section]
			var offset_b: float = lane_offsets[section + 1]
			var crown_a: float = crown_profile[section]
			var crown_b: float = crown_profile[section + 1]
			var a0 := p0 + r0 * active_half_width * offset_a + Vector3.UP * crown_a
			var b0 := p0 + r0 * active_half_width * offset_b + Vector3.UP * crown_b
			var a1 := p1 + r1 * active_half_width * offset_a + Vector3.UP * crown_a
			var b1 := p1 + r1 * active_half_width * offset_b + Vector3.UP * crown_b
			var uv_a0 := Vector2((offset_a + 1.0) * 1.3, distance / 7.5)
			var uv_b0 := Vector2((offset_b + 1.0) * 1.3, distance / 7.5)
			var uv_a1 := Vector2((offset_a + 1.0) * 1.3, (distance + segment_length) / 7.5)
			var uv_b1 := Vector2((offset_b + 1.0) * 1.3, (distance + segment_length) / 7.5)
			st.set_normal(normal0)
			st.set_uv(uv_a0)
			st.add_vertex(a0)
			st.set_normal(normal0)
			st.set_uv(uv_b0)
			st.add_vertex(b0)
			st.set_normal(normal1)
			st.set_uv(uv_b1)
			st.add_vertex(b1)
			st.set_normal(normal0)
			st.set_uv(uv_a0)
			st.add_vertex(a0)
			st.set_normal(normal1)
			st.set_uv(uv_b1)
			st.add_vertex(b1)
			st.set_normal(normal1)
			st.set_uv(uv_a1)
			st.add_vertex(a1)
		distance += segment_length
	var mesh := st.commit()
	mesh.surface_set_material(0, make_road_material(theme_id))
	return mesh


static func build_track(parent: Node3D, track_id: String) -> Dictionary:
	match track_id:
		"neon":
			active_half_width = 6.2
		"snow":
			active_half_width = 7.15
		"loop":
			active_half_width = 8.4
		_:
			active_half_width = HALF_WIDTH
	var curve := create_curve(track_id)
	var length := curve.get_baked_length()
	var sample_count := clampi(int(length / 3.2), 520, 1250)
	var samples := PackedVector3Array()
	var tangents := PackedVector3Array()
	for i in range(sample_count):
		var offset := length * float(i) / float(sample_count)
		samples.append(curve.sample_baked(offset, true))
		tangents.append(tangent_at(curve, offset, length))

	var road := MeshInstance3D.new()
	road.name = "Road"
	road.mesh = build_road_mesh(curve, samples, tangents, track_id)
	road.position.y = 0.025
	parent.add_child(road)

	var bounds_min := Vector3(INF, INF, INF)
	var bounds_max := Vector3(-INF, -INF, -INF)
	for point in samples:
		bounds_min = bounds_min.min(point)
		bounds_max = bounds_max.max(point)
	var bounds_center := (bounds_min + bounds_max) * 0.5
	var ground_size := maxf(bounds_max.x - bounds_min.x, bounds_max.z - bounds_min.z) + 900.0
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(ground_size, ground_size)
	ground_mesh.subdivide_width = 1
	ground_mesh.subdivide_depth = 1
	var ground := MeshInstance3D.new()
	ground.name = "TerrainGround"
	ground.mesh = ground_mesh
	ground.position = Vector3(bounds_center.x, -0.12, bounds_center.z)
	ground.material_override = make_grass_material(track_id)
	parent.add_child(ground)

	build_road_markings(parent, samples, tangents, track_id)
	build_road_surface_details(parent, samples, tangents, track_id)
	var shortcuts := build_shortcuts(parent, samples, tangents, track_id)
	build_track_corridor(parent, samples, tangents, track_id)
	build_curbs(parent, samples, tangents, track_id)
	build_guardrails(parent, samples, tangents, track_id)
	build_shortcut_navigation(parent, samples, tangents, shortcuts, track_id)
	build_start_gate(parent, samples, tangents, length)
	if track_id == "neon":
		build_neon_scenery(parent, samples, tangents, shortcuts)
	elif track_id == "snow":
		build_snow_scenery(parent, samples, tangents, shortcuts)
	else:
		build_gravel_traps(parent, samples, tangents)
		build_trackside_props(parent, curve, samples, tangents, length)
		build_stadium_landmarks(parent, samples, tangents, shortcuts)
	optimize_static_props(parent)
	return {
		"curve": curve,
		"length": length,
		"samples": samples,
		"tangents": tangents,
		"track_id": track_id,
		"half_width": active_half_width,
		"shortcuts": shortcuts,
		"quality": validate_quality_clearance(samples, shortcuts),
	}


static func build_road_markings(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		track_id: String
	) -> void:
	if track_id == "neon":
		var cyan := CarFactory.make_material(Color("#c9fbff"), 0.0, 0.12, Color("#43eaff"))
		var pink := CarFactory.make_material(Color("#ffffff"), 0.0, 0.14, Color("#ff4bc8"))
		cyan.emission_energy_multiplier = 3.4
		pink.emission_energy_multiplier = 3.0
		for direction in [-1.0, 1.0]:
			var edge_samples := PackedVector3Array()
			for sample_index in samples.size():
				var side := Vector3.UP.cross(tangents[sample_index]).normalized()
				edge_samples.append(samples[sample_index] + side * direction * (active_half_width - 0.36))
			var edge := MeshInstance3D.new()
			edge.mesh = create_shortcut_surface(edge_samples, tangents, 0.105, cyan if direction < 0.0 else pink)
			edge.position.y += 0.055
			parent.add_child(edge)
		var dash_transforms: Array[Transform3D] = []
		for dash_index in range(4, samples.size(), 18):
			dash_transforms.append(_route_transform(samples[dash_index] + Vector3.UP * 0.066, tangents[dash_index]))
		add_box_multimesh(parent, "CenterReflectors", Vector3(0.17, 0.026, 4.8), cyan, dash_transforms)
	elif track_id == "snow":
		var rut_material := CarFactory.make_material(Color("#52636d"), 0.0, 0.9)
		for lane_offset in [-1.45, 1.45]:
			var rut_samples := PackedVector3Array()
			for sample_index in samples.size():
				var side := Vector3.UP.cross(tangents[sample_index]).normalized()
				rut_samples.append(samples[sample_index] + side * lane_offset)
			var rut := MeshInstance3D.new()
			rut.mesh = create_shortcut_surface(rut_samples, tangents, 0.17, rut_material)
			rut.position.y += 0.045
			parent.add_child(rut)
		var packed_snow := CarFactory.make_material(Color("#d7e3e8"), 0.0, 0.94)
		var center_samples := PackedVector3Array()
		for sample_index in samples.size():
			center_samples.append(samples[sample_index])
		var center_pack := MeshInstance3D.new()
		center_pack.name = "PackedSnowCenter"
		center_pack.mesh = create_shortcut_surface(center_samples, tangents, 0.58, packed_snow)
		center_pack.position.y += 0.035
		parent.add_child(center_pack)
	else:
		var edge_material := CarFactory.make_material(Color("#e9eaeb"), 0.0, 0.34)
		for direction in [-1.0, 1.0]:
			var edge_samples := PackedVector3Array()
			for sample_index in samples.size():
				var side := Vector3.UP.cross(tangents[sample_index]).normalized()
				edge_samples.append(samples[sample_index] + side * direction * (active_half_width - 0.34))
			var edge := MeshInstance3D.new()
			edge.mesh = create_shortcut_surface(edge_samples, tangents, 0.11, edge_material)
			edge.position.y += 0.05
			parent.add_child(edge)
		var lane_material := CarFactory.make_material(Color("#e4e6e6"), 0.0, 0.52)
		for direction in [-1.0, 1.0]:
			var dash_transforms: Array[Transform3D] = []
			for dash_index in range(8, samples.size(), 22):
				var side := Vector3.UP.cross(tangents[dash_index]).normalized()
				var lane_position: Vector3 = samples[dash_index] + side * direction * active_half_width * 0.34
				dash_transforms.append(_route_transform(lane_position + Vector3.UP * 0.06, tangents[dash_index]))
			add_box_multimesh(
				parent,
				"LaneDashesLeft" if direction < 0.0 else "LaneDashesRight",
				Vector3(0.13, 0.025, 4.5),
				lane_material,
				dash_transforms
			)


static func build_road_surface_details(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		track_id: String
	) -> void:
	var budget := get_quality_budget(track_id)
	if track_id == "neon":
		var reflector_cyan := CarFactory.make_material(Color("#b8fbff"), 0.0, 0.12, Color("#36ecff"))
		var reflector_pink := CarFactory.make_material(Color("#ffe8fa"), 0.0, 0.12, Color("#ff3abb"))
		var left_reflectors: Array[Transform3D] = []
		var right_reflectors: Array[Transform3D] = []
		for sample_index in range(0, samples.size(), 8):
			var side := Vector3.UP.cross(tangents[sample_index]).normalized()
			var base := samples[sample_index] + Vector3.UP * 0.072
			left_reflectors.append(_route_transform(base - side * (active_half_width - 0.56), tangents[sample_index]))
			right_reflectors.append(_route_transform(base + side * (active_half_width - 0.56), tangents[sample_index]))
		add_box_multimesh(parent, "NeonReflectorsCyan", Vector3(0.10, 0.025, 0.42), reflector_cyan, left_reflectors)
		add_box_multimesh(parent, "NeonReflectorsPink", Vector3(0.10, 0.025, 0.42), reflector_pink, right_reflectors)
		var puddle := CarFactory.make_material(Color(0.035, 0.075, 0.12, 0.72), 0.36, 0.12)
		puddle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var puddle_transforms: Array[Transform3D] = []
		var detail_rng := RandomNumberGenerator.new()
		detail_rng.seed = 8082
		for sample_index in range(16, samples.size() - 12, 31):
			var side := Vector3.UP.cross(tangents[sample_index]).normalized()
			var offset := detail_rng.randf_range(-active_half_width * 0.56, active_half_width * 0.56)
			var puddle_position := samples[sample_index] + side * offset + Vector3.UP * 0.057
			var transform := _route_transform(puddle_position, tangents[sample_index])
			transform.basis = transform.basis.scaled(Vector3(detail_rng.randf_range(0.7, 2.1), 1.0, detail_rng.randf_range(1.3, 3.2)))
			puddle_transforms.append(transform)
		add_box_multimesh(parent, "WetRoadPatches", Vector3(1.2, 0.018, 1.8), puddle, puddle_transforms)
	elif track_id == "loop":
		var seam := CarFactory.make_material(Color("#30363b"), 0.28, 0.72)
		var joint_transforms: Array[Transform3D] = []
		for sample_index in range(16, samples.size() - 12, 27):
			joint_transforms.append(_route_transform(samples[sample_index] + Vector3.UP * 0.063, tangents[sample_index]))
		add_box_multimesh(
			parent,
			"ExpansionJoints",
			Vector3(active_half_width * 1.78, 0.018, 0.085),
			seam,
			joint_transforms
		)
		var repaired := CarFactory.make_material(Color("#343b40"), 0.06, 0.95)
		var repair_transforms: Array[Transform3D] = []
		var repair_rng := RandomNumberGenerator.new()
		repair_rng.seed = 60317
		for sample_index in range(40, samples.size() - 20, 78):
			var side := Vector3.UP.cross(tangents[sample_index]).normalized()
			var repair_position := samples[sample_index] + side * repair_rng.randf_range(-3.8, 3.8) + Vector3.UP * 0.058
			var transform := _route_transform(repair_position, tangents[sample_index])
			transform.basis = transform.basis.scaled(Vector3(repair_rng.randf_range(0.5, 1.4), 1.0, repair_rng.randf_range(1.8, 4.2)))
			repair_transforms.append(transform)
		add_box_multimesh(parent, "AsphaltRepairs", Vector3(1.0, 0.014, 1.1), repaired, repair_transforms)
	var _unused_budget := budget


static func build_track_corridor(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		track_id: String
	) -> void:
	if track_id == "neon":
		return
	var corridor_material := CarFactory.make_material(Color("#71828a"), 0.0, 0.98)
	if track_id == "snow":
		corridor_material = CarFactory.make_material(Color("#c7dbe3"), 0.0, 0.94)
	corridor_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for direction in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for sample_index in range(samples.size()):
			var next := (sample_index + 1) % samples.size()
			if samples[sample_index].y < 1.35 and samples[next].y < 1.35:
				continue
			var tangent_a := tangents[sample_index]
			var tangent_b := tangents[next]
			var side_a := Vector3.UP.cross(tangent_a).normalized()
			var side_b := Vector3.UP.cross(tangent_b).normalized()
			var edge_a: Vector3 = samples[sample_index] + side_a * direction * (active_half_width + 0.22)
			var edge_b: Vector3 = samples[next] + side_b * direction * (active_half_width + 0.22)
			var drop_a := clampf(edge_a.y * (0.19 if track_id == "snow" else 0.28), 6.0, 25.0)
			var drop_b := clampf(edge_b.y * (0.19 if track_id == "snow" else 0.28), 6.0, 25.0)
			var outer_a: Vector3 = edge_a + side_a * direction * drop_a
			var outer_b: Vector3 = edge_b + side_b * direction * drop_b
			outer_a.y = -0.10
			outer_b.y = -0.10
			st.add_vertex(edge_a)
			st.add_vertex(outer_a)
			st.add_vertex(outer_b)
			st.add_vertex(edge_a)
			st.add_vertex(outer_b)
			st.add_vertex(edge_b)
		var corridor := MeshInstance3D.new()
		corridor.name = "SnowRoadSupport" if track_id == "snow" else "LoopRoadSupport"
		corridor.mesh = st.commit()
		corridor.material_override = corridor_material
		parent.add_child(corridor)
		if track_id == "snow":
			for sample_index in range(22, samples.size() - 18, 44):
				if samples[sample_index].y < 12.0:
					continue
				var tangent := tangents[sample_index]
				var side := Vector3.UP.cross(tangent).normalized()
				for pier_direction in [-1.0, 1.0]:
					var pier_base: Vector3 = samples[sample_index] + side * pier_direction * (active_half_width + 1.2)
					var pier_height := maxf(1.0, pier_base.y + 0.10)
					CarFactory.add_box(
						parent,
						Vector3(1.35, pier_height, 1.55),
						Vector3(pier_base.x, pier_height * 0.5 - 0.10, pier_base.z),
						corridor_material
					)
				var crossbeam := CarFactory.add_box(
					parent,
					Vector3(active_half_width * 2.0 + 3.8, 0.82, 1.75),
					samples[sample_index] + Vector3.UP * 0.25,
					corridor_material
				)
				crossbeam.rotation.y = atan2(tangent.x, tangent.z)


static func build_shortcut_navigation(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array,
		track_id: String
	) -> void:
	if shortcuts.is_empty():
		return
	var orange := CarFactory.make_material(Color("#b75808"), 0.08, 0.24, Color("#ff8a18"))
	orange.emission_energy_multiplier = 1.9
	var dark := CarFactory.make_material(Color("#1c2226"), 0.5, 0.36)
	var index := 0
	for shortcut in shortcuts:
		var entry: Vector3 = shortcut["entry"]
		var exit: Vector3 = shortcut["exit"]
		var entry_tangent: Vector3 = shortcut["entry_tangent"]
		var exit_tangent: Vector3 = shortcut["exit_tangent"]
		build_shortcut_marker(parent, entry, entry_tangent, orange, dark, true)
		build_shortcut_marker(parent, exit, exit_tangent, orange, dark, false)
		var start_index := int(float(shortcut["start_ratio"]) * samples.size())
		var lane_side := float(shortcut["side"])
		for approach_offset in range(7, 1, -1):
			var sample_index := posmod(start_index - approach_offset, samples.size())
			var side := Vector3.UP.cross(tangents[sample_index]).normalized()
			var arrow_position := samples[sample_index] + side * lane_side * (active_half_width - 1.25) + Vector3.UP * 0.074
			var arrow_root := Node3D.new()
			arrow_root.position = arrow_position
			parent.add_child(arrow_root)
			arrow_root.look_at(arrow_root.global_position + tangents[sample_index], Vector3.UP)
			var strength := 0.45 + float(7 - approach_offset) * 0.07
			CarFactory.add_box(arrow_root, Vector3(0.18, 0.022, 1.2 * strength), Vector3(0.0, 0.0, 0.0), orange)
			for branch_direction in [-1.0, 1.0]:
				var branch := CarFactory.add_box(
					arrow_root,
					Vector3(0.16, 0.022, 0.88 * strength),
					Vector3(0.0, 0.0, -0.43 * strength),
					orange,
					Vector3(0.0, branch_direction * 0.55, 0.0)
				)
				branch.position.x = branch_direction * 0.23 * strength
		index += 1
	var _unused_track := track_id


static func build_shortcut_marker(
		parent: Node3D,
		position: Vector3,
		tangent: Vector3,
		orange: Material,
		dark: Material,
		is_entry: bool
	) -> void:
	var side := Vector3.UP.cross(tangent).normalized()
	var root := Node3D.new()
	root.position = position + side * 1.15 + Vector3.UP * 2.2
	parent.add_child(root)
	root.look_at(root.global_position - tangent, Vector3.UP)
	CarFactory.add_box(root, Vector3(3.2, 1.05, 0.16), Vector3.ZERO, dark)
	for chevron in 3:
		var x := -0.85 + float(chevron) * 0.85
		for branch_direction in [-1.0, 1.0]:
			CarFactory.add_box(
				root,
				Vector3(0.18, 0.30, 0.08),
				Vector3(x, -0.04, -0.10),
				orange,
				Vector3(0.0, 0.0, branch_direction * 0.70)
			)
	CarFactory.add_box(
		root,
		Vector3(1.9 if is_entry else 2.2, 0.20, 0.22),
		Vector3(0.0, -1.24, 0.0),
		dark
	)
	for leg_x in [-1.15, 1.15]:
		CarFactory.add_box(root, Vector3(0.12, 1.55, 0.12), Vector3(leg_x, -0.72, 0.0), dark)


static func _route_transform(position: Vector3, tangent: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(tangent, Vector3.UP), position)


static func add_box_multimesh(
		parent: Node3D,
		node_name: String,
		size: Vector3,
		material: Material,
		transforms: Array
	) -> MultiMeshInstance3D:
	if transforms.is_empty():
		return null
	var box := BoxMesh.new()
	box.size = size
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = box
	multimesh.instance_count = transforms.size()
	for transform_index in transforms.size():
		multimesh.set_instance_transform(transform_index, transforms[transform_index])
	var node := MultiMeshInstance3D.new()
	node.name = node_name
	node.multimesh = multimesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


static func optimize_static_props(parent: Node3D) -> void:
	for node in parent.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance or not mesh_instance.mesh:
			continue
		var bounds := mesh_instance.mesh.get_aabb().size
		var dimensions := [absf(bounds.x), absf(bounds.y), absf(bounds.z)]
		dimensions.sort()
		if float(dimensions[0]) < 0.7 or float(dimensions[1]) < 1.6:
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func build_neon_scenery(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array
	) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 911207
	var building_materials := [
		CarFactory.make_material(Color("#111c2d"), 0.42, 0.32),
		CarFactory.make_material(Color("#18243a"), 0.38, 0.28),
		CarFactory.make_material(Color("#202b43"), 0.48, 0.25),
	]
	var building_steel := CarFactory.make_material(Color("#33465a"), 0.72, 0.25)
	var building_chrome := CarFactory.make_material(Color("#c7d7df"), 0.86, 0.15)
	var cyan := CarFactory.make_material(Color("#0f6c7a"), 0.2, 0.16, Color("#16e9ff"))
	var magenta := CarFactory.make_material(Color("#6f174f"), 0.2, 0.16, Color("#ff26b7"))
	var yellow := CarFactory.make_material(Color("#6d4c0c"), 0.2, 0.2, Color("#ffd33d"))
	var neon_materials: Array[Material] = [cyan, magenta, yellow]
	for building_index in 34:
		var building_root := Node3D.new()
		var found := false
		for attempt in 24:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			var tangent := tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			var candidate := samples[sample_index] + side * direction * rng.randf_range(27.0, 58.0)
			if is_position_clear_of_track(candidate, samples, 23.0):
				building_root.position = candidate
				found = true
				break
		if not found:
			building_root.queue_free()
			continue
		parent.add_child(building_root)
		var focus_index := _nearest_sample_index(building_root.position, samples)
		building_root.look_at(samples[focus_index], Vector3.UP)
		var width := rng.randf_range(9.0, 16.0)
		var depth := rng.randf_range(8.0, 14.0)
		var height := rng.randf_range(17.0, 52.0)
		var body := CarFactory.add_box(
			building_root,
			Vector3(width, height, depth),
			Vector3(0.0, height * 0.5, 0.0),
			building_materials[building_index % building_materials.size()]
		)
		CarFactory.add_box(
			building_root,
			Vector3(width * 0.74, height * 0.09, depth * 0.72),
			Vector3(0.0, height + height * 0.045, 0.0),
			building_materials[(building_index + 1) % building_materials.size()]
		)
		CarFactory.add_box(
			building_root,
			Vector3(width * 0.42, height * 0.055, depth * 0.44),
			Vector3(0.0, height + height * 0.118, 0.0),
			building_materials[(building_index + 2) % building_materials.size()]
		)
		CarFactory.add_cylinder(
			building_root,
			0.075,
			height * 0.10,
			Vector3(width * 0.18, height + height * 0.20, 0.0),
			building_steel if building_index % 3 == 0 else building_chrome,
			Vector3.ZERO,
			10
		)
		var neon_material: Material = neon_materials[building_index % neon_materials.size()]
		for edge_x in [-width * 0.42, width * 0.42]:
			CarFactory.add_box(
				building_root,
				Vector3(0.13, height * 0.86, 0.10),
				Vector3(edge_x, height * 0.52, -depth * 0.51),
				neon_material
			)
		var floors := clampi(int(height / 5.2), 3, 9)
		for floor in floors:
			var y := 3.0 + float(floor) * 4.6
			for column in 3:
				var x := -width * 0.28 + float(column) * width * 0.28
				var window_material: Material = neon_materials[(building_index + floor + column) % neon_materials.size()]
				CarFactory.add_box(
					building_root,
					Vector3(width * 0.14, 0.16, 0.08),
					Vector3(x, y, -depth * 0.515),
					window_material
				)
		var roof_sign := CarFactory.add_box(
			building_root,
			Vector3(width * 0.72, 0.42, depth * 0.16),
			Vector3(0.0, height + 0.55, 0.0),
			neon_material
		)
		roof_sign.rotation.y = rng.randf_range(-0.06, 0.06)
		CarFactory.add_box(
			building_root,
			Vector3(width * 0.78, height * 0.08, depth * 0.05),
			Vector3(0.0, height * 0.64, -depth * 0.525),
			cyan if building_index % 2 == 0 else magenta
		)
		body.set_meta("building_height", height)

	var street_metal := CarFactory.make_material(Color("#273244"), 0.72, 0.28)
	for i in range(10, samples.size() - 10, 18):
		var tangent := tangents[i]
		var side := Vector3.UP.cross(tangent).normalized()
		for direction in [-1.0, 1.0]:
			var lamp_root := Node3D.new()
			lamp_root.position = samples[i] + side * direction * 10.4
			parent.add_child(lamp_root)
			lamp_root.look_at(lamp_root.global_position + tangent, Vector3.UP)
			CarFactory.add_cylinder(lamp_root, 0.11, 6.6, Vector3(0.0, 3.3, 0.0), street_metal, Vector3.ZERO, 12)
			CarFactory.add_box(
				lamp_root,
				Vector3(2.6, 0.12, 0.12),
				Vector3(-direction * 1.2, 6.42, 0.0),
				street_metal
			)
			CarFactory.add_box(
				lamp_root,
				Vector3(0.72, 0.10, 0.28),
				Vector3(-direction * 2.42, 6.30, 0.0),
				cyan if (i / 18) % 2 == 0 else magenta
			)
			if (i / 18) % 4 == 0:
				var glow := OmniLight3D.new()
				glow.position = Vector3(-direction * 1.8, 5.95, 0.0)
				glow.light_color = Color("#4defff") if (i / 18) % 8 == 0 else Color("#ff45c9")
				glow.light_energy = 4.4
				glow.omni_range = 18.0
				glow.shadow_enabled = false
				lamp_root.add_child(glow)

	for i in range(36, samples.size() - 36, 72):
		var tangent := tangents[i]
		var side := Vector3.UP.cross(tangent).normalized()
		var arch_root := Node3D.new()
		arch_root.position = samples[i]
		parent.add_child(arch_root)
		arch_root.look_at(arch_root.global_position + tangent, Vector3.UP)
		for direction in [-1.0, 1.0]:
			CarFactory.add_box(
				arch_root,
				Vector3(0.34, 7.1, 0.34),
				Vector3(direction * 10.2, 3.55, 0.0),
				street_metal
			)
		var arch_material: Material = neon_materials[(i / 72) % neon_materials.size()]
		CarFactory.add_box(arch_root, Vector3(20.8, 0.44, 0.44), Vector3(0.0, 7.0, 0.0), arch_material)
		CarFactory.add_box(arch_root, Vector3(18.0, 0.12, 0.50), Vector3(0.0, 6.72, 0.0), cyan)

	build_neon_roadside(parent, samples, tangents, neon_materials, street_metal)
	build_neon_backdrop(parent, samples, tangents, shortcuts, neon_materials, street_metal)


static func build_neon_backdrop(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array,
		neon_materials: Array[Material],
		street_metal: Material
	) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 701992
	var far_facades: Array[Material] = [
		CarFactory.make_material(Color("#0a1222"), 0.32, 0.34),
		CarFactory.make_material(Color("#111a2b"), 0.38, 0.28),
		CarFactory.make_material(Color("#161426"), 0.26, 0.32),
	]
	for building_index in 16:
		var candidate := Vector3.ZERO
		var tangent := Vector3.FORWARD
		var accepted := false
		for attempt in 20:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			tangent = tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			candidate = samples[sample_index] + side * direction * rng.randf_range(74.0, 138.0)
			candidate.y = 0.0
			if is_position_clear_of_routes(candidate, samples, shortcuts, 28.0):
				accepted = true
				break
		if not accepted:
			continue
		var root := Node3D.new()
		root.position = candidate
		parent.add_child(root)
		root.look_at(root.global_position + tangent, Vector3.UP)
		var width := rng.randf_range(13.0, 25.0)
		var depth := rng.randf_range(11.0, 21.0)
		var height := rng.randf_range(38.0, 94.0)
		CarFactory.add_box(
			root,
			Vector3(width, height, depth),
			Vector3.UP * height * 0.5,
			far_facades[building_index % far_facades.size()]
		)
		for floor in range(3, int(height / 7.0), 2):
			var band_material: Material = neon_materials[(building_index + floor) % neon_materials.size()]
			CarFactory.add_box(
				root,
				Vector3(width * 0.74, 0.22, 0.08),
				Vector3(0.0, float(floor) * 6.4, -depth * 0.515),
				band_material
			)
		CarFactory.add_box(
			root,
			Vector3(width * 0.16, height * 0.88, 0.11),
			Vector3(width * 0.38, height * 0.52, -depth * 0.53),
			neon_materials[building_index % neon_materials.size()]
		)
		root.set_meta("quality_prop", true)
	var landmark_index := int(samples.size() * 0.56)
	var landmark_sample := samples[landmark_index]
	var landmark_tangent := tangents[landmark_index]
	var landmark_side := Vector3.UP.cross(landmark_tangent).normalized()
	var landmark := Node3D.new()
	landmark.name = "NeonObservatoryLandmark"
	landmark.position = landmark_sample + landmark_side * 34.0
	parent.add_child(landmark)
	landmark.look_at(landmark_sample, Vector3.UP)
	var landmark_body := CarFactory.make_material(Color("#16273c"), 0.58, 0.22)
	CarFactory.add_cylinder(landmark, 4.4, 72.0, Vector3.UP * 36.0, landmark_body, Vector3.ZERO, 12)
	CarFactory.add_cylinder(landmark, 6.0, 2.2, Vector3.UP * 73.0, street_metal, Vector3.ZERO, 12)
	CarFactory.add_cylinder(landmark, 4.8, 2.0, Vector3.UP * 75.0, neon_materials[0], Vector3.ZERO, 12)
	for level in 7:
		CarFactory.add_box(
			landmark,
			Vector3(8.4, 0.28, 0.30),
			Vector3(0.0, 8.0 + float(level) * 8.8, -4.3),
			neon_materials[(level + 1) % neon_materials.size()]
		)
	landmark.set_meta("quality_prop", true)


static func build_neon_roadside(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		neon_materials: Array[Material],
		street_metal: Material
	) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 271828
	var facade_materials: Array[Material] = [
		CarFactory.make_material(Color("#101728"), 0.34, 0.36),
		CarFactory.make_material(Color("#172033"), 0.42, 0.30),
		CarFactory.make_material(Color("#252138"), 0.28, 0.34),
	]
	var interior := CarFactory.make_material(Color("#714321"), 0.0, 0.36, Color("#ff9e3d"))
	interior.emission_energy_multiplier = 0.72
	var service_door := CarFactory.make_material(Color("#42546a"), 0.64, 0.26)
	var pipe_material := CarFactory.make_material(Color("#647486"), 0.82, 0.22)
	var module_index := 0
	for i in range(18, samples.size() - 18, 27):
		var tangent := tangents[i]
		var side := Vector3.UP.cross(tangent).normalized()
		for direction in [-1.0, 1.0]:
			if (module_index + (1 if direction > 0.0 else 0)) % 4 == 3:
				continue
			var root := Node3D.new()
			root.position = samples[i] + side * direction * rng.randf_range(13.8, 17.2)
			root.position += tangent * rng.randf_range(-7.0, 7.0)
			parent.add_child(root)
			root.look_at(samples[i], Vector3.UP)
			var length := rng.randf_range(12.0, 21.0)
			var height := rng.randf_range(3.6, 7.0)
			var facade: Material = facade_materials[module_index % facade_materials.size()]
			CarFactory.add_box(root, Vector3(length, height, 1.10), Vector3(0.0, height * 0.5, 0.0), facade)
			CarFactory.add_box(
				root,
				Vector3(length * 1.06, 0.32, 2.70),
				Vector3(0.0, height + 0.16, 1.06),
				street_metal
			)
			CarFactory.add_box(
				root,
				Vector3(length * 0.58, 0.10, 0.08),
				Vector3(0.0, height * 0.68, -0.61),
				neon_materials[module_index % neon_materials.size()]
			)
			CarFactory.add_box(
				root,
				Vector3(length * 0.82, 0.22, 1.60),
				Vector3(0.0, height - 0.20, -0.44),
				street_metal
			)
			var door_x := rng.randf_range(-length * 0.30, length * 0.30)
			CarFactory.add_box(root, Vector3(1.05, 1.85, 0.10), Vector3(door_x, 0.93, -0.61), service_door)
			CarFactory.add_box(
				root,
				Vector3(1.55, 0.10, 0.13),
				Vector3(door_x, 1.98, -0.70),
				interior if module_index % 3 == 0 else neon_materials[(module_index + 1) % neon_materials.size()]
			)
			for sign_offset in [-0.36, 0.36]:
				CarFactory.add_box(
					root,
					Vector3(0.12, height * 0.72, 0.13),
					Vector3(length * sign_offset, height * 0.53, -0.64),
					neon_materials[(module_index + (0 if sign_offset < 0.0 else 2)) % neon_materials.size()]
				)
			var unit_x := rng.randf_range(-length * 0.34, length * 0.34)
			CarFactory.add_box(root, Vector3(1.10, 0.65, 0.78), Vector3(unit_x, height + 0.64, 0.36), street_metal)
			CarFactory.add_cylinder(
				root,
				0.10,
				height + 0.65,
				Vector3(-length * 0.43, (height + 0.65) * 0.5, 0.38),
				pipe_material,
				Vector3.ZERO,
				10
			)
			if module_index % 5 == 0:
				CarFactory.add_box(
					root,
					Vector3(length * 0.42, 0.88, 0.16),
					Vector3(0.0, height + 0.92, -0.18),
					neon_materials[module_index % neon_materials.size()]
				)
			if module_index % 6 == 0:
				var facade_glow := OmniLight3D.new()
				facade_glow.position = Vector3(0.0, height * 0.72, -1.40)
				facade_glow.light_color = Color("#48e9ff") if module_index % 12 == 0 else Color("#ff49bd")
				facade_glow.light_energy = 2.8
				facade_glow.omni_range = 13.5
				facade_glow.shadow_enabled = false
				root.add_child(facade_glow)
			module_index += 1


static func build_snow_scenery(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array
	) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 221014
	var trunk := CarFactory.make_material(Color("#513c31"), 0.0, 0.92)
	var snow_leaf := [
		CarFactory.make_material(Color("#2f5c45"), 0.0, 0.82),
		CarFactory.make_material(Color("#3e7154"), 0.0, 0.8),
		CarFactory.make_material(Color("#d6e5dc"), 0.0, 0.82),
	]
	var tree_positions: Array[Vector3] = []
	for tree_index in 92:
		var candidate := Vector3.ZERO
		var accepted := false
		for attempt in 20:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			var tangent := tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			candidate = samples[sample_index] + side * direction * rng.randf_range(16.0, 66.0)
			candidate += tangent * rng.randf_range(-18.0, 18.0)
			if not is_position_clear_of_track(candidate, samples, 7.0):
				continue
			accepted = true
			for existing in tree_positions:
				if candidate.distance_to(existing) < 5.0:
					accepted = false
					break
			if accepted:
				break
		if not accepted:
			continue
		tree_positions.append(candidate)
		build_detailed_tree(parent, candidate, rng.randf_range(0.85, 1.55), true, rng, trunk, snow_leaf)

	build_snow_banks(parent, samples, tangents)
	build_snow_mountains(parent, samples, tangents, rng)
	build_snow_midground(parent, samples, tangents, shortcuts, rng)
	build_snow_facilities(parent, samples, tangents, shortcuts)
	build_flags(parent, samples, tangents, rng)
	build_snow_cableway(parent, samples, tangents, shortcuts, rng)


static func build_snow_banks(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array
	) -> void:
	var snow_material := CarFactory.make_material(Color("#eaf3f7"), 0.0, 0.88)
	snow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var skip_mask := build_shortcut_skip_mask("snow", samples.size())
	for direction in [-1.0, 1.0]:
		var bank := MeshInstance3D.new()
		bank.mesh = create_guardrail_ribbon(
			samples,
			tangents,
			active_half_width + 1.05,
			direction,
			-0.16,
			0.72,
			skip_mask
		)
		bank.material_override = snow_material
		parent.add_child(bank)


static func build_snow_mountains(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		rng: RandomNumberGenerator
	) -> void:
	var rock := CarFactory.make_material(Color("#536a76"), 0.0, 0.95)
	var snow := CarFactory.make_material(Color("#f0f8fb"), 0.0, 0.88, Color("#526b76"))
	snow.emission_energy_multiplier = 0.10
	rock.cull_mode = BaseMaterial3D.CULL_DISABLED
	snow.cull_mode = BaseMaterial3D.CULL_DISABLED
	for mountain_index in 22:
		var base_radius := rng.randf_range(38.0, 70.0)
		var height := rng.randf_range(60.0, 112.0)
		var position := Vector3.ZERO
		var found := false
		for attempt in 30:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			var tangent := tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			var candidate := samples[sample_index] + side * direction * rng.randf_range(105.0, 215.0)
			candidate.y = 0.0
			if is_position_clear_of_track(candidate, samples, base_radius + 55.0):
				position = candidate
				found = true
				break
		if not found:
			continue
		var mountain := MeshInstance3D.new()
		mountain.mesh = create_irregular_cone_mesh(rng.randi(), base_radius, height, 12)
		mountain.position = position
		mountain.rotation.y = rng.randf_range(0.0, TAU)
		mountain.material_override = rock
		parent.add_child(mountain)
		var cap := MeshInstance3D.new()
		cap.mesh = create_irregular_cone_mesh(rng.randi(), base_radius * 0.42, height * 0.42, 11)
		cap.position = position + Vector3.UP * height * 0.58
		cap.rotation.y = mountain.rotation.y + 0.10
		cap.material_override = snow
		parent.add_child(cap)


static func build_snow_midground(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array,
		rng: RandomNumberGenerator
	) -> void:
	var rock := CarFactory.make_material(Color("#6b7e83"), 0.0, 0.97)
	var snow := CarFactory.make_material(Color("#eef7fa"), 0.0, 0.9)
	var tree_trunk := CarFactory.make_material(Color("#47382f"), 0.0, 0.94)
	var distant_leaf := [
		CarFactory.make_material(Color("#335b4a"), 0.0, 0.9),
		CarFactory.make_material(Color("#486f57"), 0.0, 0.88),
	]
	for ridge_index in 14:
		var candidate := Vector3.ZERO
		var accepted := false
		for attempt in 20:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			var tangent := tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			candidate = samples[sample_index] + side * direction * rng.randf_range(72.0, 118.0)
			candidate.y = -0.05
			if is_position_clear_of_routes(candidate, samples, shortcuts, 34.0):
				accepted = true
				break
		if not accepted:
			continue
		var ridge := MeshInstance3D.new()
		var radius := rng.randf_range(24.0, 44.0)
		var height := rng.randf_range(30.0, 64.0)
		ridge.mesh = create_irregular_cone_mesh(rng.randi(), radius, height, 10)
		ridge.position = candidate
		ridge.rotation.y = rng.randf_range(0.0, TAU)
		ridge.material_override = rock
		ridge.set_meta("quality_prop", true)
		parent.add_child(ridge)
		var snow_cap := MeshInstance3D.new()
		snow_cap.mesh = create_irregular_cone_mesh(rng.randi(), radius * 0.40, height * 0.34, 9)
		snow_cap.position = candidate + Vector3.UP * height * 0.66
		snow_cap.rotation.y = ridge.rotation.y + 0.13
		snow_cap.material_override = snow
		parent.add_child(snow_cap)
	for tree_index in 34:
		var candidate := Vector3.ZERO
		var accepted := false
		for attempt in 16:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			var tangent := tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			candidate = samples[sample_index] + side * direction * rng.randf_range(42.0, 86.0)
			if is_position_clear_of_routes(candidate, samples, shortcuts, 16.0):
				accepted = true
				break
		if accepted:
			build_detailed_tree(
				parent,
				candidate,
				rng.randf_range(1.25, 2.05),
				true,
				rng,
				tree_trunk,
				distant_leaf
			)


static func build_snow_facilities(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array
	) -> void:
	var timber := CarFactory.make_material(Color("#553e31"), 0.0, 0.82)
	var roof := CarFactory.make_material(Color("#263943"), 0.62, 0.25)
	var stone := CarFactory.make_material(Color("#6d7472"), 0.08, 0.82)
	var warm_glass := CarFactory.make_material(Color("#b77f38"), 0.08, 0.18, Color("#ffd37a"))
	warm_glass.emission_energy_multiplier = 0.85
	var red := CarFactory.make_material(Color("#bf3434"), 0.06, 0.4)
	var white := CarFactory.make_material(Color("#eff5f5"), 0.04, 0.5)
	var placements := [0.31, 0.62]
	for placement_index in placements.size():
		var sample_index := int(float(placements[placement_index]) * samples.size()) % samples.size()
		var sample := samples[sample_index]
		var tangent := tangents[sample_index]
		var side := Vector3.UP.cross(tangent).normalized()
		var direction := -1.0 if placement_index == 0 else 1.0
		var candidate := sample + side * direction * 38.0
		candidate.y = -0.05
		if not is_position_clear_of_routes(candidate, samples, shortcuts, 20.0):
			candidate = sample - side * direction * 42.0
			candidate.y = -0.05
		var lodge := Node3D.new()
		lodge.name = "SnowLodge"
		lodge.position = candidate
		parent.add_child(lodge)
		lodge.look_at(sample, Vector3.UP)
		CarFactory.add_box(lodge, Vector3(17.0, 5.2, 9.0), Vector3.UP * 2.6, timber)
		CarFactory.add_box(lodge, Vector3(18.4, 1.0, 10.2), Vector3.UP * 5.4, roof, Vector3(-0.10, 0.0, 0.0))
		CarFactory.add_box(lodge, Vector3(6.2, 3.6, 5.8), Vector3(0.0, 7.2, 0.0), stone)
		CarFactory.add_box(lodge, Vector3(6.9, 1.0, 6.5), Vector3(0.0, 9.45, 0.0), roof)
		for window_x in [-5.8, -2.3, 2.3, 5.8]:
			CarFactory.add_box(lodge, Vector3(2.5, 2.0, 0.10), Vector3(window_x, 2.65, -4.56), warm_glass)
		CarFactory.add_box(lodge, Vector3(3.4, 2.7, 0.12), Vector3(0.0, 1.55, -4.58), roof)
		for pole_x in [-7.3, 7.3]:
			CarFactory.add_cylinder(lodge, 0.10, 3.4, Vector3(pole_x, 1.7, -4.1), white, Vector3.ZERO, 8)
			var flag := CarFactory.add_box(lodge, Vector3(2.1, 1.05, 0.06), Vector3(pole_x + 0.9, 3.1, -4.1), red)
			flag.rotation.y = 0.12 * pole_x
		var lodge_light := OmniLight3D.new()
		lodge_light.position = Vector3(0.0, 3.2, -5.0)
		lodge_light.light_color = Color("#ffd78f")
		lodge_light.light_energy = 2.7
		lodge_light.omni_range = 18.0
		lodge_light.shadow_enabled = false
		lodge.add_child(lodge_light)
		lodge.set_meta("quality_prop", true)
		build_spectator_platform(parent, sample, tangent, direction)


static func build_spectator_platform(
		parent: Node3D,
		track_position: Vector3,
		tangent: Vector3,
		direction: float
	) -> void:
	var side := Vector3.UP.cross(tangent).normalized()
	var root := Node3D.new()
	root.name = "SnowSpectatorPlatform"
	root.position = track_position + side * direction * 19.5
	parent.add_child(root)
	root.look_at(track_position, Vector3.UP)
	var concrete := CarFactory.make_material(Color("#7d878b"), 0.08, 0.82)
	var rail := CarFactory.make_material(Color("#d8e1e2"), 0.64, 0.28)
	var orange := CarFactory.make_material(Color("#e87822"), 0.05, 0.45, Color("#ff9d32"))
	for tier in 3:
		CarFactory.add_box(
			root,
			Vector3(9.5, 0.55, 1.65),
			Vector3(0.0, 0.55 + float(tier) * 0.92, float(tier) * 1.15),
			concrete
		)
		CarFactory.add_box(
			root,
			Vector3(9.7, 0.12, 0.12),
			Vector3(0.0, 1.48 + float(tier) * 0.92, -0.62 + float(tier) * 1.15),
			orange
		)
	for x in [-4.6, 4.6]:
		CarFactory.add_box(root, Vector3(0.14, 3.5, 0.14), Vector3(x, 1.75, 2.2), rail)
	root.set_meta("quality_prop", true)


static func build_flags(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		rng: RandomNumberGenerator
	) -> void:
	var pole_material := CarFactory.make_material(Color("#314653"), 0.68, 0.28)
	var red := CarFactory.make_material(Color("#e53935"), 0.08, 0.5)
	var blue := CarFactory.make_material(Color("#2475bd"), 0.08, 0.5)
	var white := CarFactory.make_material(Color("#f4f7f4"), 0.08, 0.5)
	var flag_materials: Array[Material] = [red, blue, white]
	for i in range(30, samples.size() - 30, 42):
		var sample_index := i % samples.size()
		var tangent := tangents[sample_index]
		var side := Vector3.UP.cross(tangent).normalized()
		var direction := -1.0 if (i / 42) % 2 == 0 else 1.0
		var root := Node3D.new()
		root.position = samples[sample_index] + side * direction * 10.4
		parent.add_child(root)
		root.look_at(root.global_position + tangent, Vector3.UP)
		CarFactory.add_cylinder(root, 0.055, 3.4, Vector3(0.0, 1.7, 0.0), pole_material, Vector3.ZERO, 10)
		var flag := CarFactory.add_box(
			root,
			Vector3(1.05, 0.54, 0.04),
			Vector3(0.50, 2.95, 0.0),
			flag_materials[(i / 42) % flag_materials.size()]
		)
		flag.rotation.y = rng.randf_range(-0.16, 0.16)


static func build_snow_cableway(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array,
		rng: RandomNumberGenerator
	) -> void:
	var steel := CarFactory.make_material(Color("#3f5563"), 0.72, 0.26)
	var cable_mat := CarFactory.make_material(Color("#10171d"), 0.86, 0.18)
	var cabin_body := CarFactory.make_material(Color("#c9383f"), 0.35, 0.3)
	var cabin_glass := CarFactory.make_material(Color("#a8d8e8"), 0.28, 0.08)
	var cabin_glow := CarFactory.make_material(Color("#fff2bd"), 0.05, 0.18, Color("#ffd56b"))
	cabin_glow.emission_energy_multiplier = 1.35
	var marker := CarFactory.make_material(Color("#8d1120"), 0.2, 0.24, Color("#ff354d"))
	marker.emission_energy_multiplier = 1.1
	cabin_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabin_glass.albedo_color.a = 0.62
	var tower_tops: Array[Vector3] = []
	for tower_index in 5:
		var sample_index := int((0.08 + float(tower_index) * 0.21) * samples.size()) % samples.size()
		var sample := samples[sample_index]
		var tangent := tangents[sample_index]
		var side := Vector3.UP.cross(tangent).normalized()
		var candidate := sample - side * rng.randf_range(31.0, 36.0)
		if not is_position_clear_of_routes(candidate, samples, shortcuts, 16.0):
			candidate = sample + side * rng.randf_range(32.0, 38.0)
			if not is_position_clear_of_routes(candidate, samples, shortcuts, 16.0):
				continue
		var tower_top_y := candidate.y + 26.6
		var member_height := maxf(28.0, tower_top_y + 0.8)
		var tower := Node3D.new()
		tower.position = Vector3(candidate.x, -0.10, candidate.z)
		parent.add_child(tower)
		tower.look_at(tower.global_position + Vector3(tangent.x, 0.0, tangent.z).normalized(), Vector3.UP)
		for local_x in [-3.1, 3.1]:
			CarFactory.add_box(
				tower,
				Vector3(0.46, member_height, 0.46),
				Vector3(local_x, member_height * 0.5 - 0.10, 0.0),
				steel
			)
			CarFactory.add_box(
				tower,
				Vector3(0.20, member_height * 0.94, 0.20),
				Vector3(local_x * 0.68, member_height * 0.47 - 0.10, 0.0),
				steel,
				Vector3(0.0, 0.0, 0.12 * signf(local_x))
			)
		CarFactory.add_box(tower, Vector3(7.5, 0.50, 0.52), Vector3(0.0, candidate.y + 25.6, 0.0), steel)
		CarFactory.add_box(tower, Vector3(6.0, 0.34, 0.34), Vector3(0.0, candidate.y + 23.6, 0.0), steel)
		CarFactory.add_box(tower, Vector3(1.65, 0.42, 0.42), Vector3(0.0, candidate.y + 26.12, 0.0), steel)
		CarFactory.add_box(tower, Vector3(0.28, 0.28, 0.28), Vector3(0.0, candidate.y + 27.10, 0.0), marker)
		tower_tops.append(candidate + Vector3.UP * 26.6)
	for span_index in range(tower_tops.size() - 1):
		var start := tower_tops[span_index]
		var finish := tower_tops[span_index + 1]
		var span_direction := (finish - start).normalized()
		var lateral := Vector3.UP.cross(span_direction).normalized()
		for cable_side in [-1.0, 1.0]:
			_add_beam_between(
				parent,
				start + lateral * cable_side * 1.10,
				finish + lateral * cable_side * 1.10,
				0.085,
				cable_mat
			)
		for cabin_index in 3:
			var t := 0.20 + float(cabin_index) * 0.30
			var cabin_position := start.lerp(finish, t) + Vector3.DOWN * 1.55
			var cabin := Node3D.new()
			cabin.position = cabin_position
			parent.add_child(cabin)
			cabin.look_at(cabin.global_position + span_direction, Vector3.UP)
			CarFactory.add_box(cabin, Vector3(2.55, 2.12, 2.05), Vector3.ZERO, cabin_body)
			CarFactory.add_box(cabin, Vector3(0.12, 1.10, 0.12), Vector3(0.0, 1.52, 0.0), steel)
			CarFactory.add_box(cabin, Vector3(0.95, 0.18, 0.24), Vector3(0.0, 0.94, 0.0), steel)
			for side_sign in [-1.0, 1.0]:
				CarFactory.add_box(cabin, Vector3(0.05, 1.02, 1.45), Vector3(side_sign * 1.29, 0.16, 0.0), cabin_glass)
				CarFactory.add_box(cabin, Vector3(1.60, 1.02, 0.05), Vector3(0.0, 0.16, side_sign * 1.04), cabin_glass)
			CarFactory.add_box(cabin, Vector3(2.72, 0.18, 2.22), Vector3(0.0, 1.13, 0.0), steel)
			CarFactory.add_box(cabin, Vector3(1.55, 0.10, 0.16), Vector3(0.0, -1.08, 0.0), cabin_glow)


static func build_loop_skyline(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array,
		steel: Material,
		white: Material,
		yellow: Material
	) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 403127
	var facade_materials: Array[Material] = [
		CarFactory.make_material(Color("#172635"), 0.44, 0.28),
		CarFactory.make_material(Color("#23364a"), 0.38, 0.24),
		CarFactory.make_material(Color("#111e2c"), 0.48, 0.22),
	]
	var window_cyan := CarFactory.make_material(Color("#267a89"), 0.2, 0.16, Color("#27d9e8"))
	window_cyan.emission_energy_multiplier = 1.15
	var window_warm := CarFactory.make_material(Color("#80692d"), 0.2, 0.18, Color("#ffd35b"))
	window_warm.emission_energy_multiplier = 0.95
	var beacon := CarFactory.make_material(Color("#9f1722"), 0.18, 0.24, Color("#ff3148"))
	beacon.emission_energy_multiplier = 1.0
	for building_index in 24:
		var candidate := Vector3.ZERO
		var tangent := Vector3.FORWARD
		var found := false
		for attempt in 24:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			tangent = tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			candidate = samples[sample_index] + side * direction * rng.randf_range(62.0, 105.0)
			candidate.y = 0.0
			if is_position_clear_of_routes(candidate, samples, shortcuts, 30.0):
				found = true
				break
		if not found:
			continue
		var root := Node3D.new()
		root.position = candidate
		parent.add_child(root)
		root.look_at(root.global_position + tangent, Vector3.UP)
		var style := building_index % 5
		var width := rng.randf_range(10.0, 17.0)
		var depth := rng.randf_range(9.0, 16.0)
		var height := rng.randf_range(22.0, 58.0)
		var material: Material = facade_materials[building_index % facade_materials.size()]
		var visual_width := width
		var visual_depth := depth
		var window_bottom := 3.4
		var window_top := height - 2.2
		var floor_count := clampi(int(height / 7.0), 3, 7)
		match style:
			0:
				CarFactory.add_box(root, Vector3(width, height, depth), Vector3(0.0, height * 0.5, 0.0), material)
				CarFactory.add_box(
					root,
					Vector3(width * 0.78, height * 0.10, depth * 0.80),
					Vector3(0.0, height * 0.96, 0.0),
					facade_materials[(building_index + 1) % facade_materials.size()]
				)
			1:
				height = maxf(height, 38.0)
				CarFactory.add_box(root, Vector3(width, height * 0.60, depth), Vector3(0.0, height * 0.30, 0.0), material)
				CarFactory.add_box(
					root,
					Vector3(width * 0.78, height * 0.27, depth * 0.82),
					Vector3(0.0, height * 0.735, 0.0),
					facade_materials[(building_index + 1) % facade_materials.size()]
				)
				CarFactory.add_box(
					root,
					Vector3(width * 0.54, height * 0.17, depth * 0.62),
					Vector3(0.0, height * 0.955, 0.0),
					material
				)
				visual_width = width * 0.78
				visual_depth = depth * 0.82
				window_top = height * 0.89
			2:
				var tower_width := width * 0.42
				var tower_offset := width * 0.28
				for tower_side in [-1.0, 1.0]:
					CarFactory.add_box(
						root,
						Vector3(tower_width, height, depth),
						Vector3(tower_side * tower_offset, height * 0.5, 0.0),
						material
					)
					_add_loop_window_bands(
						root,
						Vector3(tower_side * tower_offset, 0.0, 0.0),
						Vector2(tower_width, depth),
						3.2,
						height - 2.0,
						floor_count,
						window_cyan,
						window_warm,
						building_index + (1 if tower_side > 0.0 else 0)
					)
				for bridge_y in [height * 0.34, height * 0.67]:
					CarFactory.add_box(
						root,
						Vector3(width * 0.62, 0.72, depth * 0.42),
						Vector3(0.0, bridge_y, 0.0),
						steel
					)
				floor_count = 0
			3:
				var radius := minf(width, depth) * 0.47
				CarFactory.add_cylinder(root, radius, height, Vector3(0.0, height * 0.5, 0.0), material, Vector3.ZERO, 18)
				CarFactory.add_cylinder(
					root,
					radius * 1.08,
					1.0,
					Vector3(0.0, height + 0.50, 0.0),
					steel,
					Vector3.ZERO,
					18
				)
				visual_width = radius * 1.72
				visual_depth = radius * 1.72
				window_bottom = 3.8
				window_top = height - 2.5
			4:
				CarFactory.add_box(root, Vector3(width, height * 0.38, depth), Vector3(0.0, height * 0.19, 0.0), material)
				CarFactory.add_box(
					root,
					Vector3(width * 0.78, height * 0.34, depth * 0.82),
					Vector3(0.0, height * 0.55, 0.0),
					facade_materials[(building_index + 2) % facade_materials.size()]
				)
				CarFactory.add_box(
					root,
					Vector3(width * 0.54, height * 0.30, depth * 0.62),
					Vector3(0.0, height * 0.87, 0.0),
					material
				)
				visual_width = width * 0.78
				visual_depth = depth * 0.82
				window_top = height * 0.90
		if floor_count > 0:
			_add_loop_window_bands(
				root,
				Vector3.ZERO,
				Vector2(visual_width, visual_depth),
				window_bottom,
				window_top,
				floor_count,
				window_cyan,
				window_warm,
				building_index
			)
		for corner_x in [-visual_width * 0.49, visual_width * 0.49]:
			for corner_z in [-visual_depth * 0.49, visual_depth * 0.49]:
				CarFactory.add_box(
					root,
					Vector3(0.10, height * 0.88, 0.10),
					Vector3(corner_x, height * 0.48, corner_z),
					steel
				)
		CarFactory.add_box(
			root,
			Vector3(visual_width * 0.68, 0.34, 0.12),
			Vector3(0.0, height + 0.75, 0.0),
			yellow if building_index % 4 == 0 else white
		)
		if height > 34.0:
			CarFactory.add_box(
				root,
				Vector3(0.12, 5.2, 0.12),
				Vector3(0.0, height + 3.1, 0.0),
				steel
			)
			CarFactory.add_box(
				root,
				Vector3(0.30, 0.30, 0.30),
				Vector3(0.0, height + 5.8, 0.0),
				beacon
			)
		if building_index % 5 == 0:
			CarFactory.add_box(
				root,
				Vector3(width * 0.56, 1.20, 0.10),
				Vector3(0.0, height * 0.72, -depth * 0.515),
				yellow
			)


static func _add_loop_window_bands(
		parent: Node3D,
		center: Vector3,
		size: Vector2,
		base_y: float,
		top_y: float,
		floor_count: int,
		window_cyan: Material,
		window_warm: Material,
		tint_offset: int
	) -> void:
	if floor_count <= 0:
		return
	for floor in floor_count:
		var y := base_y + (top_y - base_y) * float(floor + 1) / float(floor_count + 1)
		var band_material: Material = window_warm if (tint_offset + floor) % 4 == 0 else window_cyan
		var band_height := 0.48 + 0.08 * float(floor % 3)
		var band_width := size.x * (0.66 + 0.05 * float(floor % 2))
		var band_depth := size.y * (0.64 + 0.06 * float((floor + 1) % 2))
		CarFactory.add_box(
			parent,
			Vector3(band_width, band_height, 0.07),
			center + Vector3(0.0, y, -size.y * 0.515),
			band_material
		)
		CarFactory.add_box(
			parent,
			Vector3(band_width, band_height, 0.07),
			center + Vector3(0.0, y, size.y * 0.515),
			band_material
		)
		CarFactory.add_box(
			parent,
			Vector3(0.07, band_height, band_depth),
			center + Vector3(-size.x * 0.515, y, 0.0),
			band_material
		)
		CarFactory.add_box(
			parent,
			Vector3(0.07, band_height, band_depth),
			center + Vector3(size.x * 0.515, y, 0.0),
			band_material
		)


static func _add_beam_between(
		parent: Node3D,
		start: Vector3,
		finish: Vector3,
		thickness: float,
		material: Material
	) -> void:
	var distance := start.distance_to(finish)
	var beam := CarFactory.add_box(
		parent,
		Vector3(thickness, thickness, distance),
		(start + finish) * 0.5,
		material
	)
	beam.look_at(finish, Vector3.UP)


static func build_stadium_landmarks(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array
	) -> void:
	var steel := CarFactory.make_material(Color("#303b43"), 0.72, 0.26)
	var white := CarFactory.make_material(Color("#e7eff0"), 0.1, 0.35)
	var yellow := CarFactory.make_material(Color("#f0c52b"), 0.1, 0.26)
	var lens := CarFactory.make_material(Color("#fff6cb"), 0.0, 0.15, Color("#fff099"))
	for i in range(80, samples.size() - 40, 155):
		var sample_index := i % samples.size()
		var tangent := tangents[sample_index]
		var side := Vector3.UP.cross(tangent).normalized()
		var direction := -1.0 if (i / 155) % 2 == 0 else 1.0
		var root := Node3D.new()
		root.position = samples[sample_index] + side * direction * 27.0
		parent.add_child(root)
		root.look_at(samples[sample_index], Vector3.UP)
		for x in [-3.4, 3.4]:
			CarFactory.add_box(root, Vector3(0.32, 9.0, 0.32), Vector3(x, 4.5, 0.0), steel)
		CarFactory.add_box(root, Vector3(7.6, 0.45, 0.55), Vector3(0.0, 8.8, 0.0), steel)
		for lamp_index in 5:
			CarFactory.add_box(
				root,
				Vector3(1.10, 0.22, 0.42),
				Vector3(-2.8 + float(lamp_index) * 1.4, 8.95, 0.0),
				lens
			)
		CarFactory.add_box(root, Vector3(4.8, 3.0, 0.26), Vector3(0.0, 5.2, -0.35), white)
		CarFactory.add_box(root, Vector3(4.2, 0.28, 0.34), Vector3(0.0, 6.1, -0.48), yellow)
	for i in range(120, samples.size() - 100, 225):
		build_grandstand(parent, samples[i], tangents[i])
	build_loop_skyline(parent, samples, tangents, shortcuts, steel, white, yellow)
	build_loop_inner_district(parent, samples, tangents, shortcuts)
	build_city_observation_tower(parent, samples, tangents, shortcuts)


static func build_loop_inner_district(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array
	) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 770219
	var facades: Array[Material] = [
		CarFactory.make_material(Color("#25343d"), 0.46, 0.28),
		CarFactory.make_material(Color("#2c3d44"), 0.38, 0.3),
		CarFactory.make_material(Color("#202c37"), 0.5, 0.25),
	]
	var glass_cyan := CarFactory.make_material(Color("#355c62"), 0.28, 0.18, Color("#35c7d4"))
	var glass_warm := CarFactory.make_material(Color("#6d5c31"), 0.2, 0.22, Color("#ffd76a"))
	var roof_vent := CarFactory.make_material(Color("#5d686e"), 0.7, 0.32)
	for building_index in 14:
		var candidate := Vector3.ZERO
		var tangent := Vector3.FORWARD
		var accepted := false
		for attempt in 22:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			tangent = tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			candidate = samples[sample_index] + side * direction * rng.randf_range(35.0, 58.0)
			candidate.y = -0.05
			if is_position_clear_of_routes(candidate, samples, shortcuts, 19.0):
				accepted = true
				break
		if not accepted:
			continue
		var root := Node3D.new()
		root.name = "CityInnerBuilding"
		root.position = candidate
		parent.add_child(root)
		root.look_at(root.global_position + tangent, Vector3.UP)
		var width := rng.randf_range(8.0, 14.0)
		var depth := rng.randf_range(7.5, 13.0)
		var height := rng.randf_range(14.0, 34.0)
		var facade: Material = facades[building_index % facades.size()]
		CarFactory.add_box(root, Vector3(width, height, depth), Vector3.UP * height * 0.5, facade)
		CarFactory.add_box(root, Vector3(width * 0.72, 0.5, depth * 0.70), Vector3.UP * (height + 0.25), roof_vent)
		for floor in range(1, int(height / 4.4)):
			var window_material: Material = glass_warm if (building_index + floor) % 5 == 0 else glass_cyan
			CarFactory.add_box(
				root,
				Vector3(width * 0.72, 0.23, 0.07),
				Vector3(0.0, 2.2 + float(floor) * 3.3, -depth * 0.515),
				window_material
			)
		CarFactory.add_box(
			root,
			Vector3(2.1, 2.9, 0.12),
			Vector3(0.0, 1.45, -depth * 0.53),
			roof_vent
		)
		CarFactory.add_box(
			root,
			Vector3(2.5, 0.20, 0.22),
			Vector3(0.0, 2.8, -depth * 0.58),
			glass_warm
		)
		root.set_meta("quality_prop", true)


static func build_city_observation_tower(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		shortcuts: Array
	) -> void:
	var sample_index := int(samples.size() * 0.47)
	var sample := samples[sample_index]
	var tangent := tangents[sample_index]
	var side := Vector3.UP.cross(tangent).normalized()
	var candidate := sample + side * 53.0
	if not is_position_clear_of_routes(candidate, samples, shortcuts, 30.0):
		candidate = sample - side * 57.0
	candidate.y = -0.05
	var root := Node3D.new()
	root.name = "CityObservationTower"
	root.position = candidate
	parent.add_child(root)
	var concrete := CarFactory.make_material(Color("#737b7d"), 0.08, 0.82)
	var steel := CarFactory.make_material(Color("#29363d"), 0.68, 0.26)
	var amber := CarFactory.make_material(Color("#a77622"), 0.12, 0.22, Color("#ffc44d"))
	amber.emission_energy_multiplier = 1.25
	CarFactory.add_cylinder(root, 3.1, 62.0, Vector3.UP * 31.0, concrete, Vector3.ZERO, 16)
	CarFactory.add_cylinder(root, 9.2, 3.4, Vector3.UP * 59.0, steel, Vector3.ZERO, 20)
	CarFactory.add_cylinder(root, 8.4, 1.1, Vector3.UP * 62.0, amber, Vector3.ZERO, 20)
	for level in 6:
		CarFactory.add_box(
			root,
			Vector3(14.0, 0.13, 0.16),
			Vector3(0.0, 54.0 + float(level) * 1.6, -7.5),
			amber
		)
	root.set_meta("quality_prop", true)


static func _nearest_sample_index(position: Vector3, samples: PackedVector3Array) -> int:
	var nearest := 0
	var best_distance := INF
	for index in range(0, samples.size(), 4):
		var distance := position.distance_squared_to(samples[index])
		if distance < best_distance:
			best_distance = distance
			nearest = index
	return nearest


static func build_curbs(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		track_id: String
	) -> void:
	var red := CarFactory.make_material(Color("#d83932"), 0.05, 0.68)
	var white := CarFactory.make_material(Color("#eeeae0"), 0.03, 0.74)
	var neon_a := CarFactory.make_material(Color("#9ffaff"), 0.0, 0.18, Color("#28e9f4"))
	var neon_b := CarFactory.make_material(Color("#ffc7ec"), 0.0, 0.18, Color("#ff2eb5"))
	var snow_orange := CarFactory.make_material(Color("#d8681e"), 0.08, 0.44, Color("#ff9a34"))
	if track_id == "neon":
		neon_a.emission_energy_multiplier = 2.2
		neon_b.emission_energy_multiplier = 2.0
	for direction in [-1.0, 1.0]:
		var curb_a := MeshInstance3D.new()
		curb_a.name = "CurbAlternateA"
		curb_a.mesh = create_open_guardrail_ribbon(
			samples,
			tangents,
			active_half_width + 0.30,
			direction,
			0.03,
			0.13
		)
		curb_a.material_override = (
			neon_a if track_id == "neon"
			else (snow_orange if track_id == "snow" else red)
		)
		parent.add_child(curb_a)
		var curb_b := MeshInstance3D.new()
		curb_b.name = "CurbAlternateB"
		curb_b.mesh = create_open_guardrail_ribbon(
			samples,
			tangents,
			active_half_width + 0.34,
			direction,
			0.035,
			0.145
		)
		curb_b.material_override = (
			neon_b if track_id == "neon"
			else (white if track_id == "snow" else white)
		)
		parent.add_child(curb_b)
	if track_id == "loop":
		var reflector := CarFactory.make_material(Color("#fff6b8"), 0.0, 0.16, Color("#ffd949"))
		var transforms: Array[Transform3D] = []
		for sample_index in range(8, samples.size(), 16):
			var side := Vector3.UP.cross(tangents[sample_index]).normalized()
			for direction in [-1.0, 1.0]:
				transforms.append(_route_transform(
					samples[sample_index] + side * direction * (active_half_width + 0.56) + Vector3.UP * 0.62,
					tangents[sample_index]
				))
		add_box_multimesh(parent, "CurbReflectors", Vector3(0.11, 0.42, 0.12), reflector, transforms)


static func build_guardrails(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		track_id: String
	) -> void:
	var metal_color := Color("#dce4e7")
	var post_color := Color("#59646b")
	var accent_color := Color("#f5c33b")
	if track_id == "neon":
		metal_color = Color("#243849")
		post_color = Color("#101927")
		accent_color = Color("#16dce8")
	elif track_id == "snow":
		metal_color = Color("#d9e9f2")
		post_color = Color("#69879c")
		accent_color = Color("#f0a73c")
	elif track_id == "loop":
		metal_color = Color("#eef3f3")
		post_color = Color("#39444b")
		accent_color = Color("#ffbf24")
	var metal := CarFactory.make_material(metal_color, 0.72, 0.25)
	var post_mat := CarFactory.make_material(post_color, 0.54, 0.4)
	var accent := CarFactory.make_material(accent_color, 0.18, 0.35)
	var skip_mask := build_shortcut_skip_mask(track_id, samples.size())
	metal.cull_mode = BaseMaterial3D.CULL_DISABLED
	accent.cull_mode = BaseMaterial3D.CULL_DISABLED
	for direction in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.name = "ContinuousGuardrailLeft" if direction < 0.0 else "ContinuousGuardrailRight"
		rail.mesh = create_guardrail_ribbon(
			samples,
			tangents,
			active_half_width + 1.85,
			direction,
			0.47,
			0.76,
			skip_mask
		)
		rail.material_override = metal
		parent.add_child(rail)
		var stripe := MeshInstance3D.new()
		stripe.name = "GuardrailStripe"
		stripe.mesh = create_guardrail_ribbon(
			samples,
			tangents,
			active_half_width + 1.79,
			direction,
			0.36,
			0.44,
			skip_mask
		)
		stripe.material_override = accent
		parent.add_child(stripe)
	var step := 12
	for i in range(0, samples.size() - step, step):
		if skip_mask[i]:
			continue
		var j := i + step
		if j >= samples.size():
			j = 0
		var a := samples[i]
		var tangent := tangents[i]
		var side := Vector3.UP.cross(tangent).normalized()
		for direction in [-1.0, 1.0]:
			var post := CarFactory.add_box(
				parent,
				Vector3(0.13, 0.74, 0.13),
				a + side * direction * (active_half_width + 1.94) + Vector3.UP * 0.30,
				post_mat
			)
			post.rotation.y = atan2(tangent.x, tangent.z)


static func create_guardrail_ribbon(
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		offset: float,
		direction: float,
		bottom_height: float,
		top_height: float,
		skip_mask: Array = []
	) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(samples.size()):
		var next := (i + 1) % samples.size()
		if not skip_mask.is_empty() and (skip_mask[i] or skip_mask[next]):
			continue
		var side_a := Vector3.UP.cross(tangents[i]).normalized()
		var side_b := Vector3.UP.cross(tangents[next]).normalized()
		var base_a := samples[i] + side_a * offset * direction
		var base_b := samples[next] + side_b * offset * direction
		var bottom_a := base_a + Vector3.UP * bottom_height
		var top_a := base_a + Vector3.UP * top_height
		var bottom_b := base_b + Vector3.UP * bottom_height
		var top_b := base_b + Vector3.UP * top_height
		st.add_vertex(bottom_a)
		st.add_vertex(top_a)
		st.add_vertex(top_b)
		st.add_vertex(bottom_a)
		st.add_vertex(top_b)
		st.add_vertex(bottom_b)
	st.generate_normals()
	return st.commit()


static func get_shortcut_specs(track_id: String) -> Array[Dictionary]:
	match track_id:
		"neon":
			return [
				{
					"start": 0.17,
					"end": 0.31,
					"side": -1.0,
					"span": 82.0,
					"width": 4.8,
				},
			]
		"snow":
			return [
				{
					"start": 0.22,
					"end": 0.39,
					"side": 1.0,
					"span": 148.0,
					"width": 5.4,
				},
			]
		_:
			return [
				{
					"start": 0.39,
					"end": 0.53,
					"side": -1.0,
					"span": 168.0,
					"width": 6.2,
				},
				{
					"start": 0.72,
					"end": 0.84,
					"side": 1.0,
					"span": 138.0,
					"width": 5.8,
				},
			]


static func build_shortcuts(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		track_id: String
	) -> Array[Dictionary]:
	var shortcuts: Array[Dictionary] = []
	for spec in get_shortcut_specs(track_id):
		var shortcut := build_shortcut(parent, samples, tangents, track_id, spec)
		if not shortcut.is_empty():
			shortcuts.append(shortcut)
	return shortcuts


static func build_shortcut(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		track_id: String,
		spec: Dictionary
	) -> Dictionary:
	var start_index := clampi(int(float(spec["start"]) * samples.size()), 0, samples.size() - 1)
	var end_index := clampi(int(float(spec["end"]) * samples.size()), 0, samples.size() - 1)
	var start := samples[start_index]
	var finish := samples[end_index]
	var start_tangent := tangents[start_index]
	var finish_tangent := tangents[end_index]
	var side_direction: float = spec["side"]
	var start_side := Vector3.UP.cross(start_tangent).normalized()
	var finish_side := Vector3.UP.cross(finish_tangent).normalized()
	var track_center := Vector3.ZERO
	for sample in samples:
		track_center += sample
	track_center /= float(samples.size())
	track_center.y = 0.0
	var segment_midpoint := (start + finish) * 0.5
	var outward := Vector3(
		segment_midpoint.x - track_center.x,
		0.0,
		segment_midpoint.z - track_center.z
	)
	if outward.length_squared() < 0.01:
		outward = start_side * side_direction
	outward = outward.normalized()
	var start_outward := Vector3(start.x - track_center.x, 0.0, start.z - track_center.z)
	var finish_outward := Vector3(finish.x - track_center.x, 0.0, finish.z - track_center.z)
	if start_outward.length_squared() < 0.01:
		start_outward = start_side * side_direction
	if finish_outward.length_squared() < 0.01:
		finish_outward = finish_side * side_direction
	start_outward = start_outward.normalized()
	finish_outward = finish_outward.normalized()
	var entry_offset := active_half_width + 0.36
	var p0 := start + start_outward * entry_offset
	var p3 := finish + finish_outward * entry_offset
	p0.y += 0.16
	p3.y += 0.16
	var width: float = spec["width"]
	var span: float = spec["span"]
	var p1 := Vector3.ZERO
	var p2 := Vector3.ZERO
	var curve := Curve3D.new()
	var shortcut_samples := PackedVector3Array()
	var shortcut_tangents := PackedVector3Array()
	var surface_samples := 72
	for attempt in 6:
		var expansion := 1.0 + float(attempt) * 0.18
		p1 = start.lerp(finish, 0.26) + outward * span * 0.82 * expansion + start_tangent * 10.0
		p2 = start.lerp(finish, 0.74) + outward * span * expansion - finish_tangent * 10.0
		p1.y = maxf(p0.y, start.lerp(finish, 0.26).y) + 2.5
		p2.y = maxf(finish.y, start.lerp(finish, 0.74).y) + 2.1
		curve = Curve3D.new()
		for point in [p0, p1, p2, p3]:
			curve.add_point(point)
		curve.bake_interval = 0.5
		shortcut_samples.clear()
		shortcut_tangents.clear()
		var shortcut_length := curve.get_baked_length()
		for sample_index in surface_samples:
			var offset_distance := shortcut_length * float(sample_index) / float(surface_samples - 1)
			shortcut_samples.append(curve.sample_baked(offset_distance, true))
			var ahead := curve.sample_baked(minf(offset_distance + 0.8, shortcut_length), true)
			var behind := curve.sample_baked(maxf(offset_distance - 0.8, 0.0), true)
			shortcut_tangents.append((ahead - behind).normalized())
		if _shortcut_has_clearance(shortcut_samples, samples, active_half_width + width + 7.0):
			break
	var material := make_shortcut_material(track_id)
	var foundation_material := CarFactory.make_material(Color("#151a20"), 0.55, 0.32)
	var foundation := MeshInstance3D.new()
	foundation.name = "ShortcutFoundation"
	foundation.mesh = create_shortcut_surface(shortcut_samples, shortcut_tangents, width + 0.65, foundation_material)
	foundation.position.y += 0.04
	parent.add_child(foundation)
	var ribbon := create_shortcut_surface(shortcut_samples, shortcut_tangents, width, material)
	var ribbon_node := MeshInstance3D.new()
	ribbon_node.name = "Shortcut"
	ribbon_node.mesh = ribbon
	ribbon_node.position.y += 0.15
	parent.add_child(ribbon_node)
	var rail_material := CarFactory.make_material(Color("#ffb72b"), 0.34, 0.3)
	rail_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for direction in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		rail.name = "ShortcutRail"
		rail.mesh = create_open_guardrail_ribbon(
			shortcut_samples,
			shortcut_tangents,
			width + 0.34,
			direction,
			0.16,
			0.62
		)
		rail.material_override = rail_material
		parent.add_child(rail)
	for support_index in range(12, shortcut_samples.size() - 10, 10):
		var support_position := shortcut_samples[support_index]
		var support_height := maxf(1.0, support_position.y)
		CarFactory.add_box(
			parent,
			Vector3(0.34, support_height, 0.34),
			Vector3(support_position.x, support_height * 0.5 - 0.1, support_position.z),
			foundation_material
		)
	var marker_material := CarFactory.make_material(
		Color("#ffbc2e"),
		0.1,
		0.3,
		Color("#ff8a00")
	)
	for marker_position in [p0, p3]:
		var marker := CarFactory.add_box(
			parent,
			Vector3(1.5, 0.65, 0.16),
			marker_position + Vector3.UP * 1.2,
			marker_material
		)
		marker.rotation.y = atan2((p3 - p0).x, (p3 - p0).z)
	return {
		"samples": shortcut_samples,
		"tangents": shortcut_tangents,
		"width": width,
		"length": curve.get_baked_length(),
		"entry": p0,
		"exit": p3,
		"entry_tangent": shortcut_tangents[0] if not shortcut_tangents.is_empty() else start_tangent,
		"exit_tangent": shortcut_tangents[shortcut_tangents.size() - 1] if not shortcut_tangents.is_empty() else finish_tangent,
		"start_ratio": float(spec["start"]),
		"end_ratio": float(spec["end"]),
		"side": float(spec["side"]),
	}


static func _shortcut_has_clearance(
		shortcut_samples: PackedVector3Array,
		track_samples: PackedVector3Array,
		minimum_distance: float
	) -> bool:
	var threshold_squared := minimum_distance * minimum_distance
	for shortcut_index in range(4, shortcut_samples.size() - 4):
		var shortcut_point := shortcut_samples[shortcut_index]
		for track_index in range(0, track_samples.size(), 3):
			var track_point := track_samples[track_index]
			var horizontal_distance := Vector2(
				shortcut_point.x - track_point.x,
				shortcut_point.z - track_point.z
			).length_squared()
			if horizontal_distance < threshold_squared and absf(shortcut_point.y - track_point.y) < 4.5:
				return false
	return true


static func validate_quality_clearance(
		samples: PackedVector3Array,
		shortcuts: Array
	) -> Dictionary:
	var nearest_horizontal := INF
	var nearest_vertical := INF
	var violations := 0
	for shortcut in shortcuts:
		var shortcut_samples: PackedVector3Array = shortcut["samples"]
		var shortcut_width := float(shortcut["width"])
		for shortcut_index in range(4, shortcut_samples.size() - 4):
			var shortcut_point := shortcut_samples[shortcut_index]
			for track_index in range(0, samples.size(), 3):
				var track_point := samples[track_index]
				var horizontal := Vector2(
					shortcut_point.x - track_point.x,
					shortcut_point.z - track_point.z
				).length()
				var vertical := absf(shortcut_point.y - track_point.y)
				nearest_horizontal = minf(nearest_horizontal, horizontal)
				nearest_vertical = minf(nearest_vertical, vertical)
				if horizontal < shortcut_width + 4.0 and vertical < 2.6:
					violations += 1
	return {
		"shortcut_count": shortcuts.size(),
		"nearest_horizontal": nearest_horizontal,
		"nearest_vertical": nearest_vertical,
		"violations": violations,
	}


static func create_open_guardrail_ribbon(
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		offset: float,
		direction: float,
		bottom_height: float,
		top_height: float
	) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(samples.size() - 1):
		var next := index + 1
		var side_a := Vector3.UP.cross(tangents[index]).normalized()
		var side_b := Vector3.UP.cross(tangents[next]).normalized()
		var base_a := samples[index] + side_a * offset * direction
		var base_b := samples[next] + side_b * offset * direction
		var bottom_a := base_a + Vector3.UP * bottom_height
		var top_a := base_a + Vector3.UP * top_height
		var bottom_b := base_b + Vector3.UP * bottom_height
		var top_b := base_b + Vector3.UP * top_height
		st.add_vertex(bottom_a)
		st.add_vertex(top_a)
		st.add_vertex(top_b)
		st.add_vertex(bottom_a)
		st.add_vertex(top_b)
		st.add_vertex(bottom_b)
	st.generate_normals()
	return st.commit()


static func create_shortcut_surface(
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		width: float,
		material: Material
	) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var distance_travelled := 0.0
	for index in range(samples.size() - 1):
		var p0 := samples[index]
		var p1 := samples[index + 1]
		var tangent0 := tangents[index]
		var tangent1 := tangents[index + 1]
		var side0 := Vector3.UP.cross(tangent0).normalized()
		var side1 := Vector3.UP.cross(tangent1).normalized()
		var normal0 := tangent0.cross(side0).normalized()
		var normal1 := tangent1.cross(side1).normalized()
		var segment_length := p0.distance_to(p1)
		var left0 := p0 - side0 * width
		var right0 := p0 + side0 * width
		var left1 := p1 - side1 * width
		var right1 := p1 + side1 * width
		st.set_normal(normal0)
		st.set_uv(Vector2(0.0, distance_travelled / 7.0))
		st.add_vertex(left0)
		st.set_normal(normal0)
		st.set_uv(Vector2(1.0, distance_travelled / 7.0))
		st.add_vertex(right0)
		st.set_normal(normal1)
		st.set_uv(Vector2(1.0, (distance_travelled + segment_length) / 7.0))
		st.add_vertex(right1)
		st.set_normal(normal0)
		st.set_uv(Vector2(0.0, distance_travelled / 7.0))
		st.add_vertex(left0)
		st.set_normal(normal1)
		st.set_uv(Vector2(1.0, (distance_travelled + segment_length) / 7.0))
		st.add_vertex(right1)
		st.set_normal(normal1)
		st.set_uv(Vector2(0.0, (distance_travelled + segment_length) / 7.0))
		st.add_vertex(left1)
		distance_travelled += segment_length
	var mesh := st.commit()
	mesh.surface_set_material(0, material)
	return mesh


static func make_shortcut_material(track_id: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	if track_id == "snow":
		material.albedo_color = Color("#a9c8d5")
		material.roughness = 0.46
		material.metallic = 0.18
	elif track_id == "neon":
		material.albedo_color = Color("#37414c")
		material.roughness = 0.72
		material.metallic = 0.34
	else:
		material.albedo_color = Color("#464b50")
		material.roughness = 0.82
		material.metallic = 0.12
	return material


static func build_shortcut_skip_mask(track_id: String, sample_count: int) -> Array[bool]:
	var mask: Array[bool] = []
	mask.resize(sample_count)
	mask.fill(false)
	for spec in get_shortcut_specs(track_id):
		var start_index := clampi(int(float(spec["start"]) * sample_count), 0, sample_count - 1)
		var end_index := clampi(int(float(spec["end"]) * sample_count), 0, sample_count - 1)
		for index_offset in range(-5, 7):
			mask[posmod(start_index + index_offset, sample_count)] = true
			mask[posmod(end_index + index_offset, sample_count)] = true
	return mask


static func build_start_gate(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		length: float
	) -> void:
	var start := samples[0]
	var tangent := tangents[0]
	var side := Vector3.UP.cross(tangent).normalized()
	var dark := CarFactory.make_material(Color("#172637"), 0.42, 0.3)
	var white := CarFactory.make_material(Color("#f8fbff"), 0.05, 0.5)
	var cyan := CarFactory.make_material(Color("#16c7dd"), 0.2, 0.25, Color("#0d7e91"))
	for direction in [-1.0, 1.0]:
		CarFactory.add_box(
			parent,
			Vector3(0.42, 5.2, 0.42),
			start + side * direction * 10.1 + Vector3.UP * 2.6,
			dark
		)
	var beam := CarFactory.add_box(parent, Vector3(20.6, 0.72, 0.65), start + Vector3.UP * 5.0, dark)
	beam.rotation.y = atan2(tangent.x, tangent.z)
	CarFactory.add_box(parent, Vector3(7.4, 0.38, 0.18), start + Vector3.UP * 5.0 - tangent * 0.38, cyan, Vector3(0.0, atan2(tangent.x, tangent.z), 0.0))
	for stripe in 7:
		var x := -6.0 + float(stripe) * 2.0
		var stripe_node := CarFactory.add_box(
			parent,
			Vector3(1.0, 0.025, 0.34),
			start + side * x + Vector3.UP * 0.095 + tangent * 0.15,
			white if stripe % 2 == 0 else cyan
		)
		stripe_node.rotation.y = atan2(tangent.x, tangent.z)
	var start_arc := CarFactory.add_box(
		parent,
		Vector3(0.8, 4.7, 0.18),
		start + side * 6.9 + Vector3.UP * 2.35,
		white
	)
	start_arc.rotation.y = atan2(tangent.x, tangent.z)


static func build_trackside_props(
		parent: Node3D,
		curve: Curve3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		length: float
	) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260917
	build_grandstand(parent, samples[0], tangents[0])
	build_billboards(parent, samples, tangents)
	build_pit_lane(parent, samples, tangents)
	build_distance_markers(parent, samples, tangents)

	var trunk_mat := CarFactory.make_material(Color("#6f472d"), 0.0, 0.9)
	var leaf_materials := [
		CarFactory.make_material(Color("#2d7d46"), 0.0, 0.82),
		CarFactory.make_material(Color("#409653"), 0.0, 0.78),
		CarFactory.make_material(Color("#276b3c"), 0.0, 0.86),
	]
	var rock_mat := CarFactory.make_material(Color("#818b86"), 0.0, 0.92)
	var tree_positions: Array[Vector3] = []
	for tree_index in 104:
		var placed := false
		var candidate := Vector3.ZERO
		for attempt in 12:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			var tangent := tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			var distance := rng.randf_range(18.0, 72.0)
			candidate = samples[sample_index] + side * direction * distance
			candidate += tangent * rng.randf_range(-12.0, 12.0)
			placed = is_position_clear_of_track(candidate, samples, 8.0)
			for tree_position in tree_positions:
				if candidate.distance_to(tree_position) < 5.2:
					placed = false
					break
			if placed:
				break
		if not placed:
			continue
		tree_positions.append(candidate)
		build_detailed_tree(
			parent,
			candidate,
			rng.randf_range(0.72, 1.34),
			rng.randf() < 0.38,
			rng,
			trunk_mat,
			leaf_materials
		)

	for rock_index in 64:
		var sample_index := rng.randi_range(0, samples.size() - 1)
		var tangent := tangents[sample_index]
		var side := Vector3.UP.cross(tangent).normalized()
		var direction := -1.0 if rng.randf() < 0.5 else 1.0
		var position := samples[sample_index] + side * direction * rng.randf_range(13.0, 32.0)
		if not is_position_clear_of_track(position, samples, 4.0):
			continue
		build_detailed_rock(parent, position, rng, rock_mat)

	build_tire_walls(parent, samples, tangents, rng)
	build_clouds(parent, rng)
	build_mountains(parent, samples, tangents, rng)


static func build_detailed_tree(
		parent: Node3D,
		position: Vector3,
		scale_factor: float,
		conifer: bool,
		rng: RandomNumberGenerator,
		trunk_material: Material,
		leaf_materials: Array
	) -> void:
	var trunk_height := 4.7 * scale_factor if conifer else 3.15 * scale_factor
	CarFactory.add_cylinder(
		parent,
		0.25 * scale_factor,
		trunk_height,
		position + Vector3.UP * trunk_height * 0.5,
		trunk_material,
		Vector3.ZERO,
		10
	)
	if conifer:
		for layer in 3:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.08 * scale_factor
			cone.bottom_radius = (1.72 - float(layer) * 0.27) * scale_factor
			cone.height = (2.35 - float(layer) * 0.16) * scale_factor
			cone.radial_segments = 10
			var crown := MeshInstance3D.new()
			crown.mesh = cone
			crown.position = position + Vector3.UP * (3.05 + float(layer) * 0.78) * scale_factor
			crown.rotation.y = rng.randf_range(0.0, TAU)
			crown.material_override = leaf_materials[(layer + rng.randi_range(0, 2)) % leaf_materials.size()]
			parent.add_child(crown)
	else:
		var offsets := [
			Vector3.ZERO,
			Vector3(0.92, 0.18, 0.10),
			Vector3(-0.82, 0.30, -0.18),
			Vector3(0.10, 0.16, 0.92),
			Vector3(-0.15, 0.72, -0.22),
		]
		for crown_index in offsets.size():
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = (1.35 - float(crown_index) * 0.055) * scale_factor
			crown_mesh.height = crown_mesh.radius * 1.65
			crown_mesh.radial_segments = 12
			crown_mesh.rings = 6
			var crown := MeshInstance3D.new()
			crown.mesh = crown_mesh
			crown.position = position + Vector3.UP * 3.55 * scale_factor + offsets[crown_index] * scale_factor
			crown.scale = Vector3(
				rng.randf_range(0.88, 1.12),
				rng.randf_range(0.78, 1.08),
				rng.randf_range(0.88, 1.12)
			)
			crown.rotation.y = rng.randf_range(0.0, TAU)
			crown.material_override = leaf_materials[rng.randi_range(0, leaf_materials.size() - 1)]
			parent.add_child(crown)
		var branch_material := trunk_material
		CarFactory.add_cylinder(
			parent,
			0.08 * scale_factor,
			1.6 * scale_factor,
			position + Vector3(-0.48, 2.78, 0.0) * scale_factor,
			branch_material,
			Vector3(0.0, 0.0, 0.72),
			8
		)
		CarFactory.add_cylinder(
			parent,
			0.07 * scale_factor,
			1.45 * scale_factor,
			position + Vector3(0.42, 2.62, 0.14) * scale_factor,
			branch_material,
			Vector3(0.0, 0.0, -0.68),
			8
		)


static func build_detailed_rock(
		parent: Node3D,
		position: Vector3,
		rng: RandomNumberGenerator,
		rock_material: Material
	) -> void:
	var moss_material := CarFactory.make_material(Color("#6f8c55"), 0.0, 0.95)
	var rock_group := Node3D.new()
	rock_group.position = position
	rock_group.rotation.y = rng.randf_range(0.0, TAU)
	parent.add_child(rock_group)
	var main_radius := rng.randf_range(0.55, 1.28)
	var main_rock := CarFactory.add_sphere(
		rock_group,
		main_radius,
		Vector3.UP * main_radius * 0.28,
		rock_material,
		Vector3(rng.randf_range(0.75, 1.42), rng.randf_range(0.42, 0.72), rng.randf_range(0.78, 1.48))
	)
	main_rock.rotation = Vector3(rng.randf_range(-0.22, 0.22), 0.0, rng.randf_range(-0.18, 0.18))
	if rng.randf() < 0.58:
		var moss := CarFactory.add_sphere(
			rock_group,
			main_radius * 0.72,
			Vector3(-0.12, main_radius * 0.82, 0.05),
			moss_material,
			Vector3(0.92, 0.20, 0.78)
		)
		moss.rotation.z = rng.randf_range(-0.18, 0.18)
	if rng.randf() < 0.65:
		CarFactory.add_sphere(
			rock_group,
			main_radius * rng.randf_range(0.30, 0.52),
			Vector3(rng.randf_range(0.7, 1.1), 0.12, rng.randf_range(-0.7, 0.7)),
			rock_material,
			Vector3(1.3, 0.55, 1.0)
		)


static func build_gravel_traps(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array
	) -> void:
	var gravel := CarFactory.make_material(Color("#9a8564"), 0.0, 0.98)
	var gravel_dark := CarFactory.make_material(Color("#756348"), 0.0, 0.99)
	var stone_a := CarFactory.make_material(Color("#a48e70"), 0.0, 0.94)
	var stone_b := CarFactory.make_material(Color("#c1a67f"), 0.0, 0.94)
	var rng := RandomNumberGenerator.new()
	rng.seed = 74819
	for i in range(18, samples.size() - 18, 20):
		var tangent := tangents[i]
		var future := tangents[(i + 9) % tangents.size()]
		var turn_factor := 1.0 - clampf(tangent.dot(future), -1.0, 1.0)
		if turn_factor < 0.10:
			continue
		var side := Vector3.UP.cross(tangent).normalized()
		var direction := signf(tangent.cross(future).y)
		if absf(direction) < 0.1:
			direction = -1.0 if i % 2 == 0 else 1.0
		for segment in 5:
			var sample_index := (i + segment * 2) % samples.size()
			var sample_tangent := tangents[sample_index]
			var sample_side := Vector3.UP.cross(sample_tangent).normalized()
			var patch := PlaneMesh.new()
			patch.size = Vector2(5.2, 4.2)
			var patch_node := MeshInstance3D.new()
			patch_node.mesh = patch
			patch_node.position = samples[sample_index] + sample_side * direction * (active_half_width + 2.55) + Vector3.UP * 0.015
			patch_node.rotation.y = atan2(sample_tangent.x, sample_tangent.z)
			patch_node.material_override = gravel if (segment + i) % 3 != 0 else gravel_dark
			parent.add_child(patch_node)
			for pebble in 3:
				var pebble_position := (
					samples[sample_index]
					+ sample_side * direction * rng.randf_range(active_half_width + 0.8, active_half_width + 4.5)
					+ sample_tangent * rng.randf_range(-1.8, 1.8)
				)
				var pebble_node := CarFactory.add_sphere(
					parent,
					rng.randf_range(0.08, 0.20),
					pebble_position + Vector3.UP * 0.09,
					stone_a if pebble % 2 == 0 else stone_b,
					Vector3(rng.randf_range(0.8, 1.5), rng.randf_range(0.35, 0.65), rng.randf_range(0.8, 1.45))
				)
				pebble_node.rotation.y = rng.randf_range(0.0, TAU)


static func build_distance_markers(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array
	) -> void:
	var post_mat := CarFactory.make_material(Color("#384c5a"), 0.52, 0.34)
	var white := CarFactory.make_material(Color("#eef4ef"), 0.08, 0.52)
	var red := CarFactory.make_material(Color("#e24b3f"), 0.08, 0.48)
	var blue := CarFactory.make_material(Color("#218ed0"), 0.08, 0.48)
	var colors := [red, blue, white]
	for marker_index in range(28, samples.size() - 12, 48):
		var tangent := tangents[marker_index]
		var side := Vector3.UP.cross(tangent).normalized()
		var direction := -1.0 if marker_index % 96 == 28 else 1.0
		var marker_root := Node3D.new()
		marker_root.position = samples[marker_index] + side * direction * 12.0
		parent.add_child(marker_root)
		marker_root.look_at(marker_root.global_position - tangent, Vector3.UP)
		for leg_x in [-0.52, 0.52]:
			CarFactory.add_box(marker_root, Vector3(0.10, 2.0, 0.10), Vector3(leg_x, 1.0, 0.0), post_mat)
		CarFactory.add_box(marker_root, Vector3(1.52, 0.78, 0.10), Vector3(0.0, 1.76, -0.08), post_mat)
		CarFactory.add_box(
			marker_root,
			Vector3(1.30, 0.56, 0.05),
			Vector3(0.0, 1.76, -0.145),
			colors[(marker_index / 48) % colors.size()]
		)


static func build_clouds(parent: Node3D, rng: RandomNumberGenerator) -> void:
	var cloud_material := CarFactory.make_material(Color(0.94, 0.98, 1.0), 0.0, 0.78)
	cloud_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_material.albedo_color.a = 0.78
	for cluster_index in 10:
		var angle := TAU * float(cluster_index) / 10.0 + rng.randf_range(-0.24, 0.24)
		var distance := rng.randf_range(125.0, 205.0)
		var cluster := Node3D.new()
		cluster.position = Vector3(cos(angle) * distance, rng.randf_range(54.0, 78.0), -90.0 + sin(angle) * distance)
		parent.add_child(cluster)
		for puff in 4:
			var mesh := SphereMesh.new()
			mesh.radius = 3.8
			mesh.height = 5.2
			mesh.radial_segments = 10
			mesh.rings = 5
			var puff_node := MeshInstance3D.new()
			puff_node.mesh = mesh
			puff_node.position = Vector3(float(puff) * 4.1 - 6.0, rng.randf_range(-0.5, 1.4), rng.randf_range(-1.4, 1.4))
			puff_node.scale = Vector3(rng.randf_range(0.85, 1.35), rng.randf_range(0.52, 0.82), rng.randf_range(0.85, 1.35))
			puff_node.material_override = cloud_material
			cluster.add_child(puff_node)


static func build_grandstand(parent: Node3D, start: Vector3, tangent: Vector3) -> void:
	var side := Vector3.UP.cross(tangent).normalized()
	var stand := Node3D.new()
	stand.name = "MainGrandstand"
	stand.position = start - side * 15.5 + Vector3.UP * 0.4
	stand.rotation.y = atan2(tangent.x, tangent.z)
	parent.add_child(stand)
	var concrete := CarFactory.make_material(Color("#d4d6d2"), 0.08, 0.76)
	var steel := CarFactory.make_material(Color("#344653"), 0.62, 0.32)
	var blue := CarFactory.make_material(Color("#1f72b9"), 0.08, 0.55)
	var yellow := CarFactory.make_material(Color("#f1bf32"), 0.08, 0.55)
	var red := CarFactory.make_material(Color("#d84b44"), 0.08, 0.55)
	var skin := CarFactory.make_material(Color("#d8a07b"), 0.0, 0.72)
	var shirt_colors := [
		CarFactory.make_material(Color("#2478bd"), 0.04, 0.6),
		CarFactory.make_material(Color("#f0bd32"), 0.04, 0.6),
		CarFactory.make_material(Color("#d84b44"), 0.04, 0.6),
		CarFactory.make_material(Color("#f0f1e8"), 0.04, 0.6),
	]
	var paints := [blue, yellow, red]
	var row_transforms: Array[Transform3D] = []
	var seat_transforms: Array = [[], [], []]
	var shirt_transforms: Array = [[], [], [], []]
	var head_transforms: Array[Transform3D] = []
	for row in 8:
		var y := 0.55 + row * 0.46
		row_transforms.append(Transform3D(Basis.IDENTITY, Vector3(0.0, y, row * 0.72)))
		for seat in 25:
			var x := -7.1 + seat * 0.59
			seat_transforms[(seat + row) % paints.size()].append(
				Transform3D(Basis.IDENTITY, Vector3(x, y + 0.31, row * 0.72 - 0.16))
			)
			if seat % 2 == 0 and row > 1:
				var shirt_index := (seat + row * 2) % shirt_colors.size()
				shirt_transforms[shirt_index].append(
					Transform3D(Basis.IDENTITY, Vector3(x, y + 0.72, row * 0.72 - 0.16))
				)
				head_transforms.append(
					Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 1.05, 1.0)), Vector3(x, y + 1.12, row * 0.72 - 0.16))
				)
	add_box_multimesh(stand, "GrandstandRows", Vector3(15.8, 0.40, 0.74), concrete, row_transforms)
	for seat_color in 3:
		add_box_multimesh(
			stand,
			"GrandstandSeats%d" % seat_color,
			Vector3(0.34, 0.26, 0.34),
			paints[seat_color],
			seat_transforms[seat_color]
		)
	for shirt_index in 4:
		var shirt_mesh := CapsuleMesh.new()
		shirt_mesh.radius = 0.17
		shirt_mesh.height = 0.58
		shirt_mesh.radial_segments = 12
		shirt_mesh.rings = 5
		var shirt_multimesh := MultiMesh.new()
		shirt_multimesh.transform_format = MultiMesh.TRANSFORM_3D
		shirt_multimesh.mesh = shirt_mesh
		shirt_multimesh.instance_count = shirt_transforms[shirt_index].size()
		for instance_index in shirt_transforms[shirt_index].size():
			shirt_multimesh.set_instance_transform(instance_index, shirt_transforms[shirt_index][instance_index])
		var shirt_node := MultiMeshInstance3D.new()
		shirt_node.name = "GrandstandFans%d" % shirt_index
		shirt_node.multimesh = shirt_multimesh
		shirt_node.material_override = shirt_colors[shirt_index]
		stand.add_child(shirt_node)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.14
	head_mesh.height = 0.28
	head_mesh.radial_segments = 12
	head_mesh.rings = 6
	var head_multimesh := MultiMesh.new()
	head_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	head_multimesh.mesh = head_mesh
	head_multimesh.instance_count = head_transforms.size()
	for instance_index in head_transforms.size():
		head_multimesh.set_instance_transform(instance_index, head_transforms[instance_index])
	var head_node := MultiMeshInstance3D.new()
	head_node.name = "GrandstandHeads"
	head_node.multimesh = head_multimesh
	head_node.material_override = skin
	stand.add_child(head_node)
	CarFactory.add_box(stand, Vector3(15.9, 0.36, 0.38), Vector3(0.0, 4.10, 5.45), steel)
	CarFactory.add_box(stand, Vector3(17.0, 0.20, 6.9), Vector3(0.0, 4.42, 2.65), steel, Vector3(-0.17, 0.0, 0.0))
	CarFactory.add_box(stand, Vector3(17.1, 0.12, 0.20), Vector3(0.0, 4.72, -0.62), blue, Vector3(-0.17, 0.0, 0.0))
	for x in [-7.7, 7.7]:
		CarFactory.add_box(stand, Vector3(0.42, 4.2, 0.42), Vector3(x, 2.0, 0.2), steel)
		CarFactory.add_box(stand, Vector3(0.42, 4.2, 0.42), Vector3(x, 2.0, 5.2), steel)
	for stair in 7:
		CarFactory.add_box(
			stand,
			Vector3(2.3, 0.22, 0.62),
			Vector3(-8.95, 0.25 + float(stair) * 0.52, 0.1 + float(stair) * 0.70),
			concrete
		)
		CarFactory.add_box(
			stand,
			Vector3(2.3, 0.22, 0.62),
			Vector3(8.95, 0.25 + float(stair) * 0.52, 0.1 + float(stair) * 0.70),
			concrete
		)


static func build_billboards(parent: Node3D, samples: PackedVector3Array, tangents: PackedVector3Array) -> void:
	var colors := [
		CarFactory.make_material(Color("#e74b3c"), 0.08, 0.45, Color("#5b160f")),
		CarFactory.make_material(Color("#1ebdcf"), 0.08, 0.45, Color("#0a5962")),
		CarFactory.make_material(Color("#f1bd2e"), 0.08, 0.45, Color("#614908")),
	]
	var dark := CarFactory.make_material(Color("#172636"), 0.42, 0.38)
	for i in [34, 96, 172, 244, 326, 388]:
		var sample_index: int = i % samples.size()
		var position := samples[sample_index]
		var tangent := tangents[sample_index]
		var side := Vector3.UP.cross(tangent).normalized()
		var direction := -1.0 if i % 2 == 0 else 1.0
		var billboard := Node3D.new()
		billboard.position = position + side * direction * 12.5 + Vector3.UP * 2.4
		parent.add_child(billboard)
		billboard.look_at(position, Vector3.UP)
		CarFactory.add_box(billboard, Vector3(6.2, 2.55, 0.18), Vector3.ZERO, dark)
		CarFactory.add_box(billboard, Vector3(5.75, 2.10, 0.08), Vector3(0.0, 0.0, -0.13), colors[i % colors.size()])
		for leg_x in [-2.2, 2.2]:
			CarFactory.add_box(billboard, Vector3(0.18, 2.2, 0.18), Vector3(leg_x, -2.25, 0.0), dark)


static func build_pit_lane(parent: Node3D, samples: PackedVector3Array, tangents: PackedVector3Array) -> void:
	var compound := CarFactory.make_material(Color("#555d62"), 0.04, 0.8)
	var white := CarFactory.make_material(Color("#f8f4df"), 0.03, 0.66)
	for i in range(0, 46):
		var sample_index := i % samples.size()
		var tangent := tangents[sample_index]
		var side := Vector3.UP.cross(tangent).normalized()
		var position := samples[sample_index] - side * 10.7
		var slab := CarFactory.add_box(
			parent,
			Vector3(3.7, 0.035, 4.0),
			position + Vector3.UP * 0.01,
			compound
		)
		slab.rotation.y = atan2(tangent.x, tangent.z)
		if i % 5 == 0:
			var line := CarFactory.add_box(
				parent,
				Vector3(0.12, 0.025, 4.0),
				position + Vector3.UP * 0.04,
				white
			)
			line.rotation.y = atan2(tangent.x, tangent.z)


static func build_tire_walls(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		rng: RandomNumberGenerator
	) -> void:
	var tire_mat := CarFactory.make_material(Color("#17191c"), 0.0, 0.9)
	var red := CarFactory.make_material(Color("#e13c38"), 0.0, 0.62)
	var white := CarFactory.make_material(Color("#f3eee2"), 0.0, 0.62)
	var tire_transforms: Array[Transform3D] = []
	var red_transforms: Array[Transform3D] = []
	var white_transforms: Array[Transform3D] = []
	var tire_rotation := Basis.from_euler(Vector3(PI * 0.5, 0.0, 0.0))
	for cluster in 12:
		var sample_index := rng.randi_range(40, samples.size() - 1)
		var tangent := tangents[sample_index]
		var side := Vector3.UP.cross(tangent).normalized()
		var direction := -1.0 if cluster % 2 == 0 else 1.0
		var base := samples[sample_index] + side * direction * (active_half_width + 3.0)
		for row in 3:
			for column in 5:
				var position := base + tangent * (column - 2) * 0.72 + side * direction * row * 0.72
				var transformed_position := position + Vector3.UP * (0.22 + row * 0.42)
				tire_transforms.append(Transform3D(tire_rotation, transformed_position))
				var accent_transform := Transform3D(tire_rotation, transformed_position)
				if (column + row) % 2 == 0:
					red_transforms.append(accent_transform)
				else:
					white_transforms.append(accent_transform)
	_add_cylinder_multimesh(parent, "TireWallRubber", 0.34, 0.31, tire_mat, tire_transforms)
	_add_cylinder_multimesh(parent, "TireWallRed", 0.20, 0.325, red, red_transforms)
	_add_cylinder_multimesh(parent, "TireWallWhite", 0.20, 0.325, white, white_transforms)


static func _add_cylinder_multimesh(
		parent: Node3D,
		node_name: String,
		radius: float,
		height: float,
		material: Material,
		transforms: Array
	) -> void:
	if transforms.is_empty():
		return
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 18
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = cylinder
	multimesh.instance_count = transforms.size()
	for transform_index in transforms.size():
		multimesh.set_instance_transform(transform_index, transforms[transform_index])
	var node := MultiMeshInstance3D.new()
	node.name = node_name
	node.multimesh = multimesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


static func build_mountains(
		parent: Node3D,
		samples: PackedVector3Array,
		tangents: PackedVector3Array,
		rng: RandomNumberGenerator
	) -> void:
	var materials := [
		CarFactory.make_material(Color("#53685e"), 0.0, 0.98),
		CarFactory.make_material(Color("#657b69"), 0.0, 0.98),
		CarFactory.make_material(Color("#485c54"), 0.0, 0.98),
	]
	for material in materials:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var snow := CarFactory.make_material(Color("#dae4dd"), 0.0, 0.9)
	snow.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 18:
		var base_radius := rng.randf_range(24.0, 42.0)
		var mountain_height := rng.randf_range(30.0, 52.0)
		var position := Vector3.ZERO
		var found_position := false
		for attempt in 28:
			var sample_index := rng.randi_range(0, samples.size() - 1)
			var tangent := tangents[sample_index]
			var side := Vector3.UP.cross(tangent).normalized()
			var direction := -1.0 if rng.randf() < 0.5 else 1.0
			var distance := rng.randf_range(145.0, 225.0)
			var candidate := (
				samples[sample_index]
				+ side * direction * distance
				+ tangent * rng.randf_range(-35.0, 35.0)
			)
			candidate.y = 0.0
			if is_position_clear_of_track(candidate, samples, base_radius + 52.0):
				position = candidate
				found_position = true
				break
		if not found_position:
			continue
		position.y = 0.0
		var mountain_mesh := create_irregular_cone_mesh(
			rng.randi(),
			base_radius,
			mountain_height,
			11
		)
		var mountain := MeshInstance3D.new()
		mountain.mesh = mountain_mesh
		mountain.position = position
		mountain.rotation.y = rng.randf_range(0.0, TAU)
		mountain.material_override = materials[i % materials.size()]
		parent.add_child(mountain)
		if mountain_height > 43.0:
			var cap_mesh := create_irregular_cone_mesh(
				rng.randi(),
				base_radius * 0.30,
				mountain_height * 0.28,
				9
			)
			var cap := MeshInstance3D.new()
			cap.mesh = cap_mesh
			cap.position = position + Vector3.UP * mountain_height * 0.68
			cap.rotation.y = mountain.rotation.y + 0.12
			cap.material_override = snow
			parent.add_child(cap)


static func create_irregular_cone_mesh(
		seed_value: int,
		base_radius: float,
		height: float,
		segments: int
	) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	var ring_count := 4
	for ring_index in ring_count:
		var points := PackedVector3Array()
		var t := float(ring_index) / float(ring_count - 1)
		var radius_factor := lerpf(1.0, 0.07, pow(t, 0.72))
		for segment in segments:
			var angle := TAU * float(segment) / float(segments)
			var jitter := rng.randf_range(0.84, 1.15) if ring_index < ring_count - 1 else rng.randf_range(0.92, 1.08)
			var radius := base_radius * radius_factor * jitter
			var ring_height := height * t + rng.randf_range(-0.035, 0.035) * height
			points.append(Vector3(cos(angle) * radius, ring_height, sin(angle) * radius))
		rings.append(points)
	for ring_index in ring_count - 1:
		var lower := rings[ring_index]
		var upper := rings[ring_index + 1]
		for segment in segments:
			var next := (segment + 1) % segments
			var a := lower[segment]
			var b := lower[next]
			var c := upper[next]
			var d := upper[segment]
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(d)
	st.generate_normals()
	return st.commit()


static func is_position_clear_of_track(
		position: Vector3,
		samples: PackedVector3Array,
		minimum_distance: float
	) -> bool:
	var minimum_distance_squared := minimum_distance * minimum_distance
	for sample_index in range(0, samples.size(), 2):
		if position.distance_squared_to(samples[sample_index]) < minimum_distance_squared:
			return false
	return true


static func is_position_clear_of_routes(
		position: Vector3,
		samples: PackedVector3Array,
		shortcuts: Array,
		minimum_distance: float
	) -> bool:
	if not is_position_clear_of_track(position, samples, minimum_distance):
		return false
	for shortcut in shortcuts:
		var shortcut_samples: PackedVector3Array = shortcut["samples"]
		var shortcut_clearance: float = maxf(minimum_distance, float(shortcut["width"]) + 10.0)
		var threshold_squared := shortcut_clearance * shortcut_clearance
		for point_index in range(0, shortcut_samples.size(), 2):
			var distance := Vector2(
				position.x - shortcut_samples[point_index].x,
				position.z - shortcut_samples[point_index].z
			).length_squared()
			if distance < threshold_squared:
				return false
	return true
