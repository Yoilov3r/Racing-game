class_name CarFactory
extends RefCounted


static func make_material(
		color: Color,
		metallic: float = 0.45,
		roughness: float = 0.3,
		emission: Color = Color.BLACK
	) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if metallic > 0.32:
		material.clearcoat_enabled = true
		material.clearcoat = 0.72
		material.clearcoat_roughness = 0.12
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 2.2
	return material


static func add_box(
		parent: Node3D,
		size: Vector3,
		position: Vector3,
		material: Material,
		rotation: Vector3 = Vector3.ZERO
	) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position
	node.rotation = rotation
	node.material_override = material
	parent.add_child(node)
	return node


static func add_cylinder(
		parent: Node3D,
		radius: float,
		height: float,
		position: Vector3,
		material: Material,
		rotation: Vector3 = Vector3.ZERO,
		segments: int = 20
	) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position
	node.rotation = rotation
	node.material_override = material
	parent.add_child(node)
	return node


static func add_sphere(
		parent: Node3D,
		radius: float,
		position: Vector3,
		material: Material,
		scale: Vector3 = Vector3.ONE
	) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position
	node.scale = scale
	node.material_override = material
	parent.add_child(node)
	return node


static func add_capsule(
		parent: Node3D,
		radius: float,
		height: float,
		position: Vector3,
		material: Material,
		rotation: Vector3 = Vector3.ZERO
	) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.01)
	mesh.radial_segments = 20
	mesh.rings = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position
	node.rotation = rotation
	node.material_override = material
	parent.add_child(node)
	return node


static func add_streamlined_shell(parent: Node3D, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# z, half width, lower shoulder, upper shoulder, center crown.
	var sections := [
		[-2.35, 0.50, 0.26, 0.34, 0.41],
		[-2.06, 0.70, 0.15, 0.33, 0.49],
		[-1.58, 0.82, 0.11, 0.34, 0.56],
		[-0.88, 0.90, 0.11, 0.35, 0.61],
		[0.00, 0.94, 0.13, 0.37, 0.66],
		[0.86, 0.96, 0.14, 0.38, 0.70],
		[1.46, 0.95, 0.16, 0.39, 0.73],
		[1.91, 0.86, 0.19, 0.36, 0.64],
		[2.21, 0.69, 0.25, 0.35, 0.51],
	]
	var rings: Array[PackedVector3Array] = []
	for section in sections:
		var z: float = section[0]
		var half_width: float = section[1]
		var lower: float = section[2]
		var shoulder: float = section[3]
		var crown: float = section[4]
		var ring := PackedVector3Array([
			Vector3(-half_width, lower, z),
			Vector3(half_width, lower, z),
			Vector3(half_width, shoulder, z),
			Vector3(half_width * 0.70, crown, z),
			Vector3(half_width * 0.24, crown + 0.014, z),
			Vector3(-half_width * 0.24, crown + 0.014, z),
			Vector3(-half_width * 0.70, crown, z),
			Vector3(-half_width, shoulder, z),
		])
		rings.append(ring)
	for ring_index in rings.size() - 1:
		var front := rings[ring_index]
		var rear := rings[ring_index + 1]
		for side in 8:
			var next := (side + 1) % 8
			var a := front[side]
			var b := front[next]
			var c := rear[next]
			var d := rear[side]
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(d)
	for cap_index in 8:
		var next_cap := (cap_index + 1) % 8
		var rear_ring := rings[rings.size() - 1]
		st.add_vertex(rings[0][0])
		st.add_vertex(rings[0][cap_index])
		st.add_vertex(rings[0][next_cap])
		st.add_vertex(rear_ring[0])
		st.add_vertex(rear_ring[next_cap])
		st.add_vertex(rear_ring[cap_index])
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, material)
	var node := MeshInstance3D.new()
	node.name = "StreamlinedShell"
	node.mesh = mesh
	parent.add_child(node)


static func add_aero_canopy(parent: Node3D, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections := [
		[-1.12, 0.43, 0.70, 0.76],
		[-0.62, 0.57, 0.70, 1.00],
		[-0.10, 0.61, 0.72, 1.12],
		[0.46, 0.56, 0.73, 1.00],
		[0.82, 0.48, 0.74, 0.84],
	]
	var rings: Array[PackedVector3Array] = []
	for section in sections:
		var z: float = section[0]
		var width: float = section[1]
		var base: float = section[2]
		var top: float = section[3]
		rings.append(PackedVector3Array([
			Vector3(-width, base, z),
			Vector3(width, base, z),
			Vector3(width * 0.74, top, z),
			Vector3(0.0, top + 0.025, z),
			Vector3(-width * 0.74, top, z),
		]))
	for ring_index in rings.size() - 1:
		var front := rings[ring_index]
		var rear := rings[ring_index + 1]
		for side in 4:
			var next := (side + 1) % 5
			st.add_vertex(front[side])
			st.add_vertex(front[next])
			st.add_vertex(rear[next])
			st.add_vertex(front[side])
			st.add_vertex(rear[next])
			st.add_vertex(rear[side])
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, material)
	var canopy := MeshInstance3D.new()
	canopy.name = "AeroCanopy"
	canopy.mesh = mesh
	parent.add_child(canopy)


static func create_car(color: Color, is_player: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "PlayerCar" if is_player else "AICar"
	var body := Node3D.new()
	body.name = "OpenTopBody"
	root.add_child(body)

	var paint := make_material(color, 0.68, 0.22)
	var paint_dark := make_material(color.darkened(0.28), 0.48, 0.3)
	var carbon := make_material(Color("#171b22"), 0.12, 0.58)
	var tire := make_material(Color("#111319"), 0.0, 0.88)
	var rim := make_material(Color("#d8e1e8"), 0.92, 0.16)
	var chrome := make_material(Color("#f2f7fa"), 1.0, 0.08)
	var yellow := make_material(Color("#ffd43b"), 0.28, 0.28)
	var silver := make_material(Color("#d8e0e3"), 0.72, 0.18)
	var leather := make_material(Color("#27292e"), 0.0, 0.72)
	var skin := make_material(Color("#e5a66f"), 0.0, 0.65)
	var visor := make_material(Color("#162b42"), 0.42, 0.08)
	visor.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visor.albedo_color.a = 0.88
	var glass := make_material(Color("#9ed8ee"), 0.05, 0.05)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color.a = 0.34
	var red_light := make_material(Color("#7f0c14"), 0.4, 0.2, Color("#ff1838"))
	var brake_light := make_material(Color("#7f0c14"), 0.4, 0.2, Color("#ff1838"))
	brake_light.emission_energy_multiplier = 1.15
	var head_light := make_material(Color("#fff9d7"), 0.15, 0.18, Color("#fff3a0"))
	head_light.emission_energy_multiplier = 1.15
	var boost_mat := make_material(Color("#ff8a1c"), 0.0, 0.15, Color("#ff6f00"))

	add_streamlined_shell(body, paint)
	add_box(body, Vector3(0.17, 0.028, 1.92), Vector3(-0.36, 0.625, -0.20), silver, Vector3(0.0, -0.055, 0.0))
	add_box(body, Vector3(0.17, 0.028, 1.92), Vector3(0.36, 0.625, -0.20), silver, Vector3(0.0, 0.055, 0.0))
	add_box(body, Vector3(0.50, 0.035, 0.75), Vector3(0.0, 0.646, 0.96), carbon, Vector3(-0.035, 0.0, 0.0))
	add_box(body, Vector3(0.035, 0.10, 1.78), Vector3(-0.952, 0.49, -0.05), silver)
	add_box(body, Vector3(0.035, 0.10, 1.78), Vector3(0.952, 0.49, -0.05), silver)
	add_box(body, Vector3(1.72, 0.19, 2.18), Vector3(0.0, 0.34, 0.15), paint_dark)
	add_box(body, Vector3(1.46, 0.22, 0.58), Vector3(0.0, 0.72, 0.42), carbon)
	add_box(body, Vector3(1.78, 0.10, 0.48), Vector3(0.0, 0.68, -1.28), paint)
	add_box(body, Vector3(1.47, 0.11, 0.66), Vector3(0.0, 0.29, -2.08), carbon)
	add_box(body, Vector3(1.92, 0.09, 0.54), Vector3(0.0, 0.67, 1.66), carbon)
	add_box(body, Vector3(0.08, 0.47, 0.10), Vector3(-0.66, 0.88, 1.66), carbon, Vector3(0.0, 0.0, -0.12))
	add_box(body, Vector3(0.08, 0.47, 0.10), Vector3(0.66, 0.88, 1.66), carbon, Vector3(0.0, 0.0, 0.12))
	add_box(body, Vector3(0.52, 0.13, 0.58), Vector3(0.0, 0.72, 0.38), leather)
	add_box(body, Vector3(0.60, 0.58, 0.18), Vector3(0.0, 1.00, 0.60), leather, Vector3(-0.12, 0.0, 0.0))
	add_box(body, Vector3(0.68, 0.22, 0.32), Vector3(0.0, 0.82, 0.48), leather)

	# Cockpit, steering wheel, instruments, mirrors and open cockpit details.
	add_box(body, Vector3(1.18, 0.05, 0.28), Vector3(0.0, 0.99, -0.06), carbon, Vector3(-0.14, 0.0, 0.0))
	add_cylinder(body, 0.145, 0.045, Vector3(0.0, 1.14, -0.12), carbon, Vector3(PI * 0.5, 0.0, 0.0), 24)
	add_cylinder(body, 0.035, 0.52, Vector3(0.0, 1.10, 0.10), chrome, Vector3(PI * 0.52, 0.0, 0.0), 16)
	add_box(body, Vector3(0.28, 0.17, 0.04), Vector3(0.0, 1.08, -0.34), visor, Vector3(-0.22, 0.0, 0.0))
	add_box(body, Vector3(0.46, 0.34, 0.20), Vector3(-0.63, 1.01, 0.06), paint_dark, Vector3(0.0, 0.0, 0.18))
	add_box(body, Vector3(0.46, 0.34, 0.20), Vector3(0.63, 1.01, 0.06), paint_dark, Vector3(0.0, 0.0, -0.18))
	# Fully articulated open-cockpit driver.
	add_capsule(body, 0.19, 0.58, Vector3(0.0, 1.10, 0.45), paint_dark, Vector3(-0.17, 0.0, 0.0))
	add_sphere(body, 0.21, Vector3(0.0, 1.20, 0.34), paint_dark, Vector3(1.18, 0.76, 0.94))
	add_capsule(body, 0.075, 0.50, Vector3(-0.26, 1.15, 0.20), skin, Vector3(-0.95, 0.0, 0.22))
	add_capsule(body, 0.075, 0.50, Vector3(0.26, 1.15, 0.20), skin, Vector3(-0.95, 0.0, -0.22))
	add_capsule(body, 0.065, 0.36, Vector3(-0.17, 1.12, -0.04), skin, Vector3(-1.06, 0.0, 0.18))
	add_capsule(body, 0.065, 0.36, Vector3(0.17, 1.12, -0.04), skin, Vector3(-1.06, 0.0, -0.18))
	add_sphere(body, 0.09, Vector3(-0.13, 1.11, -0.21), leather, Vector3(1.0, 0.78, 1.15))
	add_sphere(body, 0.09, Vector3(0.13, 1.11, -0.21), leather, Vector3(1.0, 0.78, 1.15))
	add_capsule(body, 0.10, 0.48, Vector3(-0.22, 0.77, 0.18), paint, Vector3(1.30, 0.0, 0.08))
	add_capsule(body, 0.10, 0.48, Vector3(0.22, 0.77, 0.18), paint, Vector3(1.30, 0.0, -0.08))
	add_box(body, Vector3(0.17, 0.12, 0.29), Vector3(-0.23, 0.70, -0.10), leather, Vector3(0.18, 0.0, 0.0))
	add_box(body, Vector3(0.17, 0.12, 0.29), Vector3(0.23, 0.70, -0.10), leather, Vector3(0.18, 0.0, 0.0))
	add_cylinder(body, 0.075, 0.13, Vector3(0.0, 1.36, 0.37), skin, Vector3.ZERO, 12)
	add_sphere(body, 0.285, Vector3(0.0, 1.50, 0.35), make_material(Color("#f7f4e8"), 0.12, 0.24), Vector3(1.0, 1.03, 1.02))
	add_box(body, Vector3(0.45, 0.15, 0.06), Vector3(0.0, 1.51, 0.10), visor, Vector3(-0.11, 0.0, 0.0))
	add_box(body, Vector3(0.34, 0.08, 0.09), Vector3(0.0, 1.37, 0.18), carbon)
	add_box(body, Vector3(0.06, 0.23, 0.06), Vector3(-0.28, 1.47, 0.48), paint, Vector3(0.0, 0.0, 0.18))
	add_box(body, Vector3(0.06, 0.23, 0.06), Vector3(0.28, 1.47, 0.48), paint, Vector3(0.0, 0.0, -0.18))
	add_box(body, Vector3(0.045, 0.50, 0.05), Vector3(-0.15, 1.09, 0.33), yellow, Vector3(-0.18, 0.0, 0.24))
	add_box(body, Vector3(0.045, 0.50, 0.05), Vector3(0.15, 1.09, 0.33), yellow, Vector3(-0.18, 0.0, -0.24))
	add_box(body, Vector3(0.54, 0.07, 0.16), Vector3(0.0, 1.39, 0.58), carbon, Vector3(0.12, 0.0, 0.0))
	add_box(body, Vector3(0.035, 0.22, 0.035), Vector3(-0.18, 1.30, 0.59), chrome, Vector3(0.0, 0.0, -0.18))
	add_box(body, Vector3(0.035, 0.22, 0.035), Vector3(0.18, 1.30, 0.59), chrome, Vector3(0.0, 0.0, 0.18))
	add_aero_canopy(body, glass)
	add_box(body, Vector3(0.26, 0.18, 0.08), Vector3(-0.78, 1.11, -0.42), carbon, Vector3(0.0, 0.0, 0.14))
	add_box(body, Vector3(0.20, 0.13, 0.05), Vector3(-0.78, 1.13, -0.47), glass)
	add_box(body, Vector3(0.26, 0.18, 0.08), Vector3(0.78, 1.11, -0.42), carbon, Vector3(0.0, 0.0, -0.14))
	add_box(body, Vector3(0.20, 0.13, 0.05), Vector3(0.78, 1.13, -0.47), glass)

	# Front aero, splitter, lights, intake and rear diffuser.
	add_box(body, Vector3(2.02, 0.08, 0.52), Vector3(0.0, 0.20, -1.94), carbon)
	add_box(body, Vector3(1.05, 0.08, 0.26), Vector3(0.0, 0.39, -2.22), paint)
	add_box(body, Vector3(0.36, 0.16, 0.08), Vector3(-0.54, 0.58, -2.15), head_light)
	add_box(body, Vector3(0.36, 0.16, 0.08), Vector3(0.54, 0.58, -2.15), head_light)
	add_box(body, Vector3(0.82, 0.035, 0.14), Vector3(0.0, 0.585, -2.20), head_light)
	add_box(body, Vector3(0.62, 0.24, 0.08), Vector3(0.0, 0.44, -2.18), carbon)
	add_box(body, Vector3(0.065, 0.22, 0.62), Vector3(-0.955, 0.47, 0.42), carbon, Vector3(0.0, 0.0, -0.12))
	add_box(body, Vector3(0.065, 0.22, 0.62), Vector3(0.955, 0.47, 0.42), carbon, Vector3(0.0, 0.0, 0.12))
	add_box(body, Vector3(0.05, 0.16, 0.46), Vector3(-0.965, 0.43, 1.16), carbon, Vector3(0.0, 0.0, -0.09))
	add_box(body, Vector3(0.05, 0.16, 0.46), Vector3(0.965, 0.43, 1.16), carbon, Vector3(0.0, 0.0, 0.09))
	var brake_lights: Array[MeshInstance3D] = []
	brake_lights.append(add_box(body, Vector3(0.30, 0.14, 0.06), Vector3(-0.62, 0.59, 1.83), brake_light))
	brake_lights.append(add_box(body, Vector3(0.30, 0.14, 0.06), Vector3(0.62, 0.59, 1.83), brake_light))
	root.set_meta("brake_lights", brake_lights)
	root.set_meta("brake_material", brake_light)
	for x in [-0.42, 0.0, 0.42]:
		add_box(body, Vector3(0.08, 0.28, 0.56), Vector3(x, 0.19, 1.82), carbon)
	add_box(body, Vector3(0.54, 0.14, 0.12), Vector3(-0.48, 0.62, 1.87), carbon)
	add_box(body, Vector3(0.54, 0.14, 0.12), Vector3(0.48, 0.62, 1.87), carbon)
	add_cylinder(body, 0.10, 0.32, Vector3(-0.34, 0.69, 1.91), chrome, Vector3(PI * 0.5, 0.0, 0.0), 16)
	add_cylinder(body, 0.10, 0.32, Vector3(0.34, 0.69, 1.91), chrome, Vector3(PI * 0.5, 0.0, 0.0), 16)

	var wheel_positions := [
		Vector3(-0.86, 0.37, -1.27),
		Vector3(0.86, 0.37, -1.27),
		Vector3(-0.86, 0.37, 1.22),
		Vector3(0.86, 0.37, 1.22),
	]
	var front_wheels: Array[Node3D] = []
	var all_wheels: Array[Node3D] = []
	for wheel_index in wheel_positions.size():
		var wheel_pos: Vector3 = wheel_positions[wheel_index]
		var wheel_root := Node3D.new()
		wheel_root.name = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"][wheel_index]
		wheel_root.position = wheel_pos
		body.add_child(wheel_root)
		add_cylinder(wheel_root, 0.38, 0.39, Vector3.ZERO, tire, Vector3(0.0, 0.0, PI * 0.5), 32)
		add_cylinder(wheel_root, 0.315, 0.405, Vector3.ZERO, carbon, Vector3(0.0, 0.0, PI * 0.5), 32)
		add_cylinder(wheel_root, 0.235, 0.365, Vector3.ZERO, rim, Vector3(0.0, 0.0, PI * 0.5), 32)
		add_cylinder(wheel_root, 0.075, 0.40, Vector3.ZERO, chrome, Vector3(0.0, 0.0, PI * 0.5), 20)
		var inward := -1.0 if wheel_pos.x > 0.0 else 1.0
		add_cylinder(
			wheel_root,
			0.175,
			0.035,
			Vector3(inward * 0.10, 0.0, 0.0),
			chrome,
			Vector3(0.0, 0.0, PI * 0.5),
			24
		)
		add_box(
			wheel_root,
			Vector3(0.08, 0.17, 0.11),
			Vector3(inward * 0.13, 0.13, 0.0),
			red_light
		)
		for spoke in 5:
			var angle := TAU * float(spoke) / 5.0
			var spoke_node := add_box(
				wheel_root,
				Vector3(0.38, 0.035, 0.07),
				Vector3(0.0, sin(angle) * 0.13, cos(angle) * 0.13),
				carbon
			)
			spoke_node.rotation.x = angle
		if wheel_pos.z < 0.0:
			front_wheels.append(wheel_root)
		all_wheels.append(wheel_root)
	root.set_meta("front_wheels", front_wheels)
	root.set_meta("all_wheels", all_wheels)

	# Suspension arms and brake glow make the open-wheel silhouette readable.
	for wheel_pos in wheel_positions:
		var inward := -1.0 if wheel_pos.x > 0.0 else 1.0
		add_box(body, Vector3(0.80, 0.045, 0.045), wheel_pos + Vector3(inward * 0.28, 0.02, -0.14), chrome, Vector3(0.0, 0.0, -0.12 * inward))
		add_box(body, Vector3(0.80, 0.045, 0.045), wheel_pos + Vector3(inward * 0.28, 0.02, 0.14), chrome, Vector3(0.0, 0.0, 0.12 * inward))
		add_cylinder(body, 0.055, 0.06, wheel_pos + Vector3(inward * 0.24, 0.0, 0.0), red_light, Vector3(0.0, 0.0, PI * 0.5), 14)

	var smoke_emitters: Array[GPUParticles3D] = []
	if is_player:
		var smoke_color := make_material(Color(0.82, 0.86, 0.88, 0.36), 0.0, 0.74)
		smoke_color.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke_color.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_color.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		for x in [-0.78, 0.78]:
			var smoke := GPUParticles3D.new()
			smoke.amount = 34
			smoke.lifetime = 1.25
			smoke.position = Vector3(x, 0.16, 1.28)
			smoke.local_coords = false
			smoke.emitting = false
			var smoke_process := ParticleProcessMaterial.new()
			smoke_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			smoke_process.emission_sphere_radius = 0.18
			smoke_process.direction = Vector3(0.0, 0.55, 0.85)
			smoke_process.spread = 62.0
			smoke_process.initial_velocity_min = 0.8
			smoke_process.initial_velocity_max = 2.4
			smoke_process.gravity = Vector3(0.0, 1.1, 0.0)
			smoke_process.scale_min = 0.6
			smoke_process.scale_max = 1.4
			smoke.process_material = smoke_process
			var smoke_mesh := QuadMesh.new()
			smoke_mesh.size = Vector2(0.78, 0.78)
			smoke_mesh.material = smoke_color
			smoke.draw_pass_1 = smoke_mesh
			body.add_child(smoke)
			smoke_emitters.append(smoke)
	root.set_meta("smoke_emitters", smoke_emitters)

	var boost_flames: Array[MeshInstance3D] = []
	for x in [-0.33, 0.33]:
		var flame := add_sphere(body, 0.12, Vector3(x, 0.68, 2.22), boost_mat, Vector3(1.0, 0.55, 2.6))
		flame.visible = false
		boost_flames.append(flame)
	root.set_meta("boost_flames", boost_flames)

	if is_player:
		for x in [-0.54, 0.54]:
			var headlamp := SpotLight3D.new()
			headlamp.name = "Headlight"
			headlamp.position = Vector3(x, 0.62, -2.08)
			headlamp.light_color = Color("#fff0cd")
			headlamp.light_energy = 2.4
			headlamp.spot_range = 34.0
			headlamp.spot_angle = 31.0
			headlamp.shadow_enabled = false
			body.add_child(headlamp)
		var camera := Camera3D.new()
		camera.name = "DriverEyeCamera"
		camera.position = Vector3(0.0, 1.58, -0.32)
		camera.near = 0.045
		camera.far = 520.0
		camera.fov = 76.0
		camera.look_at_from_position(camera.position, Vector3(0.0, 1.14, -8.0), Vector3.UP)
		camera.current = true
		body.add_child(camera)
		root.set_meta("camera", camera)

	return root
