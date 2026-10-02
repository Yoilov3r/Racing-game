class_name CarFactory
extends RefCounted


static func make_material(
		color: Color,
		metallic: float = 0.45,
		roughness: float = 0.3,
		emission: Color = Color.BLACK,
		layer_name: String = "general"
	) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = layer_name
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	material.metallic_specular = 0.55
	if metallic > 0.32:
		material.clearcoat_enabled = true
		material.clearcoat = 0.72
		material.clearcoat_roughness = 0.12
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 2.2
	material.set_meta("layer", layer_name)
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


static func add_cone(
		parent: Node3D,
		radius: float,
		height: float,
		position: Vector3,
		material: Material,
		rotation: Vector3 = Vector3.ZERO,
		segments: int = 20
	) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
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


static func add_torus(
		parent: Node3D,
		inner_radius: float,
		outer_radius: float,
		position: Vector3,
		material: Material,
		rotation: Vector3 = Vector3.ZERO,
		rings: int = 20,
		ring_segments: int = 8
	) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = rings
	mesh.ring_segments = ring_segments
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = position
	node.rotation = rotation
	node.material_override = material
	parent.add_child(node)
	return node


static func add_beam(
		parent: Node3D,
		start: Vector3,
		end: Vector3,
		radius: float,
		material: Material,
		segments: int = 10
	) -> MeshInstance3D:
	var direction := end - start
	var length := direction.length()
	if length < 0.001:
		return null
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = length
	mesh.radial_segments = segments
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = (start + end) * 0.5
	node.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
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
	# A single 13-section loft keeps the nose, waist, haunches and tail connected.
	var sections := [
		[-2.48, 0.40, 0.25, 0.32, 0.36],
		[-2.37, 0.54, 0.19, 0.32, 0.41],
		[-2.18, 0.69, 0.14, 0.33, 0.47],
		[-1.88, 0.81, 0.11, 0.34, 0.53],
		[-1.48, 0.89, 0.09, 0.35, 0.58],
		[-0.98, 0.95, 0.10, 0.37, 0.63],
		[-0.38, 0.98, 0.12, 0.39, 0.67],
		[0.28, 0.99, 0.13, 0.41, 0.70],
		[0.84, 0.98, 0.14, 0.42, 0.73],
		[1.32, 0.96, 0.16, 0.42, 0.75],
		[1.70, 0.92, 0.18, 0.39, 0.70],
		[1.97, 0.84, 0.20, 0.36, 0.62],
		[2.18, 0.68, 0.25, 0.34, 0.51],
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
			Vector3(half_width * 0.74, crown, z),
			Vector3(half_width * 0.28, crown + 0.014, z),
			Vector3(-half_width * 0.28, crown + 0.014, z),
			Vector3(-half_width * 0.74, crown, z),
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


static func add_wheel_arch(
		parent: Node3D,
		center: Vector3,
		width: float,
		material: Material,
		segments: int = 9
	) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer_left: Array[Vector3] = []
	var outer_right: Array[Vector3] = []
	var inner_left: Array[Vector3] = []
	var inner_right: Array[Vector3] = []
	for step in segments + 1:
		var theta := lerpf(0.11, PI - 0.11, float(step) / float(segments))
		var outer_y := sin(theta) * 0.455
		var outer_z := cos(theta) * 0.485
		var inner_y := sin(theta) * 0.355
		var inner_z := cos(theta) * 0.375
		outer_left.append(center + Vector3(-width * 0.5, outer_y, outer_z))
		outer_right.append(center + Vector3(width * 0.5, outer_y, outer_z))
		inner_left.append(center + Vector3(-width * 0.5, inner_y, inner_z))
		inner_right.append(center + Vector3(width * 0.5, inner_y, inner_z))
	for step in segments:
		var next := step + 1
		st.add_vertex(outer_left[step])
		st.add_vertex(outer_right[step])
		st.add_vertex(outer_right[next])
		st.add_vertex(outer_left[step])
		st.add_vertex(outer_right[next])
		st.add_vertex(outer_left[next])
		st.add_vertex(inner_left[next])
		st.add_vertex(inner_right[next])
		st.add_vertex(inner_right[step])
		st.add_vertex(inner_left[next])
		st.add_vertex(inner_right[step])
		st.add_vertex(inner_left[step])
		st.add_vertex(outer_left[next])
		st.add_vertex(inner_left[next])
		st.add_vertex(inner_left[step])
		st.add_vertex(outer_left[next])
		st.add_vertex(inner_left[step])
		st.add_vertex(outer_left[step])
		st.add_vertex(outer_right[step])
		st.add_vertex(inner_right[step])
		st.add_vertex(inner_right[next])
		st.add_vertex(outer_right[step])
		st.add_vertex(inner_right[next])
		st.add_vertex(outer_right[next])
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, material)
	var arch := MeshInstance3D.new()
	arch.name = "CurvedWheelArch"
	arch.mesh = mesh
	parent.add_child(arch)


static func create_car(color: Color, is_player: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "PlayerCar" if is_player else "AICar"
	var body := Node3D.new()
	body.name = "OpenTopBody"
	root.add_child(body)

	# Seven visually distinct PBR families: paint, carbon, glass, rubber,
	# forged metal, brake hardware and emissive light lenses.
	var paint := make_material(color, 0.62, 0.16, Color.BLACK, "paint")
	paint.clearcoat_enabled = true
	paint.clearcoat = 1.0
	paint.clearcoat_roughness = 0.045
	var paint_dark := make_material(color.darkened(0.34), 0.42, 0.27, Color.BLACK, "paint_dark")
	var carbon := make_material(Color("#090c11"), 0.16, 0.36, Color.BLACK, "carbon")
	carbon.clearcoat_enabled = true
	carbon.clearcoat = 0.46
	carbon.clearcoat_roughness = 0.28
	var tire := make_material(Color("#05070a"), 0.0, 0.93, Color.BLACK, "rubber")
	tire.clearcoat_enabled = true
	tire.clearcoat = 0.12
	tire.clearcoat_roughness = 0.72
	var tire_sidewall := make_material(Color("#171b20"), 0.0, 0.66, Color.BLACK, "rubber_sidewall")
	tire_sidewall.clearcoat_enabled = true
	tire_sidewall.clearcoat = 0.32
	tire_sidewall.clearcoat_roughness = 0.42
	var rim := make_material(Color("#c8d1d7"), 0.95, 0.12, Color.BLACK, "forged_metal")
	rim.clearcoat_enabled = true
	rim.clearcoat = 0.86
	rim.clearcoat_roughness = 0.055
	var chrome := make_material(Color("#edf4f7"), 1.0, 0.065, Color.BLACK, "chrome")
	var silver := make_material(Color("#aeb8be"), 0.82, 0.16, Color.BLACK, "machined_metal")
	var titanium := make_material(Color("#4d5459"), 0.74, 0.24, Color.BLACK, "suspension_metal")
	var leather := make_material(Color("#202329"), 0.0, 0.72, Color.BLACK, "leather")
	var skin := make_material(Color("#df9b68"), 0.0, 0.66, Color.BLACK, "skin")
	var helmet_white := make_material(Color("#f2f5f1"), 0.10, 0.21, Color.BLACK, "helmet")
	var visor := make_material(Color("#102236"), 0.44, 0.055, Color.BLACK, "visor")
	visor.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visor.albedo_color.a = 0.9
	var glass := make_material(Color("#8fcbe1"), 0.06, 0.035, Color.BLACK, "glass")
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color.a = 0.28
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var brake_disc := make_material(Color("#555c61"), 0.86, 0.25, Color.BLACK, "brake_disc")
	var caliper := make_material(Color("#ce1726"), 0.30, 0.22, Color.BLACK, "caliper")
	var brake_light := make_material(Color("#641019"), 0.30, 0.18, Color("#ff1737"), "brake_light")
	brake_light.emission_energy_multiplier = 1.05
	var head_light := make_material(Color("#a8c8d3"), 0.30, 0.12, Color("#b8ecff"), "head_lens")
	head_light.emission_energy_multiplier = 0.72
	var head_glow := make_material(Color("#d7f5fb"), 0.08, 0.06, Color("#68d7ee"), "head_glow")
	head_glow.emission_energy_multiplier = 1.05
	var marker_light := make_material(Color("#b85812"), 0.24, 0.17, Color("#ff861e"), "marker_light")
	marker_light.emission_energy_multiplier = 0.65
	var reverse_light := make_material(Color("#d6e3e4"), 0.16, 0.13, Color("#e9f7ff"), "reverse_light")
	reverse_light.emission_energy_multiplier = 0.75
	var boost_outer := make_material(Color("#ff6a17"), 0.0, 0.18, Color("#ff4b00"), "boost_outer")
	boost_outer.emission_energy_multiplier = 5.6
	var boost_inner := make_material(Color("#b9f7ff"), 0.0, 0.08, Color("#42dfff"), "boost_core")
	boost_inner.emission_energy_multiplier = 7.0
	var display := make_material(Color("#102b35"), 0.18, 0.10, Color("#24d8e4"), "display")
	display.emission_energy_multiplier = 0.9
	var harness := make_material(Color("#e0a925"), 0.06, 0.42, Color.BLACK, "harness")

	# Continuous shell, floor, longitudinal accents and layered side skirts.
	add_streamlined_shell(body, paint)
	add_box(body, Vector3(0.17, 0.028, 2.12), Vector3(-0.35, 0.635, -0.27), silver, Vector3(0.0, -0.045, 0.0))
	add_box(body, Vector3(0.17, 0.028, 2.12), Vector3(0.35, 0.635, -0.27), silver, Vector3(0.0, 0.045, 0.0))
	add_box(body, Vector3(0.58, 0.036, 1.22), Vector3(0.0, 0.662, -0.82), carbon, Vector3(-0.035, 0.0, 0.0))
	add_box(body, Vector3(1.74, 0.085, 3.88), Vector3(0.0, 0.145, 0.02), carbon)
	add_box(body, Vector3(1.28, 0.23, 2.46), Vector3(0.0, 0.35, 0.12), paint_dark)
	for side in [-1.0, 1.0]:
		add_box(body, Vector3(0.11, 0.16, 2.86), Vector3(side * 0.975, 0.31, -0.08), carbon, Vector3(0.0, 0.0, -0.035 * side))
		add_box(body, Vector3(0.07, 0.045, 2.92), Vector3(side * 1.012, 0.235, -0.08), paint, Vector3(0.0, 0.0, -0.025 * side))
		add_box(body, Vector3(0.09, 0.14, 0.34), Vector3(side * 1.015, 0.31, -1.48), carbon, Vector3(0.0, 0.0, -0.10 * side))
		add_box(body, Vector3(0.09, 0.12, 0.30), Vector3(side * 1.015, 0.30, 1.32), carbon, Vector3(0.0, 0.0, 0.10 * side))
		add_box(body, Vector3(0.30, 0.22, 0.70), Vector3(side * 0.76, 0.50, 0.72), paint_dark, Vector3(0.0, 0.0, -0.05 * side))

	# Open cockpit, instrument binnacle, steering wheel, roll structure and driver.
	add_box(body, Vector3(1.13, 0.055, 0.34), Vector3(0.0, 0.95, -0.02), carbon, Vector3(-0.13, 0.0, 0.0))
	add_box(body, Vector3(0.55, 0.16, 0.60), Vector3(0.0, 0.73, 0.42), leather)
	add_box(body, Vector3(0.62, 0.60, 0.18), Vector3(0.0, 1.00, 0.60), leather, Vector3(-0.12, 0.0, 0.0))
	add_box(body, Vector3(0.70, 0.22, 0.32), Vector3(0.0, 0.82, 0.50), leather)
	add_box(body, Vector3(0.51, 0.06, 0.06), Vector3(0.0, 1.035, -0.30), carbon, Vector3(-0.24, 0.0, 0.0))
	add_box(body, Vector3(0.39, 0.05, 0.065), Vector3(0.0, 1.054, -0.338), display, Vector3(-0.24, 0.0, 0.0))
	add_torus(body, 0.122, 0.158, Vector3(0.0, 1.14, -0.12), leather, Vector3(PI * 0.5, 0.0, 0.0), 28, 10)
	add_box(body, Vector3(0.245, 0.025, 0.035), Vector3(0.0, 1.14, -0.12), carbon)
	add_box(body, Vector3(0.025, 0.135, 0.035), Vector3(-0.065, 1.12, -0.12), carbon, Vector3(0.0, 0.0, -0.62))
	add_box(body, Vector3(0.025, 0.135, 0.035), Vector3(0.065, 1.12, -0.12), carbon, Vector3(0.0, 0.0, 0.62))
	add_cylinder(body, 0.037, 0.50, Vector3(0.0, 1.11, 0.10), chrome, Vector3(PI * 0.52, 0.0, 0.0), 16)
	for side in [-1.0, 1.0]:
		add_box(body, Vector3(0.46, 0.34, 0.20), Vector3(side * 0.63, 1.01, 0.06), paint_dark, Vector3(0.0, 0.0, -0.18 * side))
		add_box(body, Vector3(0.055, 0.40, 0.055), Vector3(side * 0.42, 1.18, 0.58), chrome, Vector3(0.0, 0.0, -0.10 * side))
	add_box(body, Vector3(0.92, 0.065, 0.10), Vector3(0.0, 1.39, 0.58), carbon, Vector3(0.12, 0.0, 0.0))
	add_box(body, Vector3(0.42, 0.10, 0.08), Vector3(0.0, 0.91, 0.67), harness)
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
	add_sphere(body, 0.285, Vector3(0.0, 1.50, 0.35), helmet_white, Vector3(1.0, 1.03, 1.02))
	add_box(body, Vector3(0.45, 0.15, 0.06), Vector3(0.0, 1.51, 0.10), visor, Vector3(-0.11, 0.0, 0.0))
	add_box(body, Vector3(0.34, 0.08, 0.09), Vector3(0.0, 1.37, 0.18), carbon)
	add_box(body, Vector3(0.045, 0.50, 0.05), Vector3(-0.15, 1.09, 0.33), harness, Vector3(-0.18, 0.0, 0.24))
	add_box(body, Vector3(0.045, 0.50, 0.05), Vector3(0.15, 1.09, 0.33), harness, Vector3(-0.18, 0.0, -0.24))
	add_aero_canopy(body, glass)
	for side in [-1.0, 1.0]:
		add_box(body, Vector3(0.25, 0.17, 0.075), Vector3(side * 0.78, 1.11, -0.42), carbon, Vector3(0.0, 0.0, 0.14 * side))
		add_box(body, Vector3(0.19, 0.12, 0.05), Vector3(side * 0.78, 1.13, -0.47), glass)

	# Front bumper, splitter stack, canards, intake and layered lamps.
	add_box(body, Vector3(2.09, 0.065, 0.62), Vector3(0.0, 0.155, -2.01), carbon)
	add_box(body, Vector3(1.86, 0.075, 0.48), Vector3(0.0, 0.22, -2.04), carbon, Vector3(-0.045, 0.0, 0.0))
	add_box(body, Vector3(1.15, 0.09, 0.31), Vector3(0.0, 0.39, -2.22), paint)
	add_box(body, Vector3(0.74, 0.24, 0.09), Vector3(0.0, 0.43, -2.20), carbon)
	add_box(body, Vector3(0.34, 0.11, 0.12), Vector3(0.0, 0.34, -2.245), titanium)
	for side in [-1.0, 1.0]:
		add_box(body, Vector3(0.42, 0.045, 0.18), Vector3(side * 0.82, 0.29, -1.96), carbon, Vector3(0.0, -0.14 * side, -0.08 * side))
		add_box(body, Vector3(0.32, 0.035, 0.15), Vector3(side * 0.86, 0.38, -2.00), carbon, Vector3(0.0, -0.18 * side, -0.10 * side))
		add_box(body, Vector3(0.46, 0.15, 0.09), Vector3(side * 0.58, 0.59, -2.13), carbon)
		add_cylinder(body, 0.072, 0.055, Vector3(side * 0.58, 0.59, -2.18), head_glow, Vector3(PI * 0.5, 0.0, 0.0), 24)
		add_box(body, Vector3(0.34, 0.066, 0.09), Vector3(side * 0.58, 0.58, -2.215), head_light)
		add_box(body, Vector3(0.075, 0.045, 0.11), Vector3(side * 0.88, 0.565, -1.98), marker_light)
		add_cylinder(body, 0.085, 0.055, Vector3(side * 0.72, 0.335, -1.73), carbon, Vector3(PI * 0.5, 0.0, 0.0), 18)
	for x in [-0.20, 0.20]:
		add_box(body, Vector3(0.30, 0.024, 0.12), Vector3(x, 0.575, -2.225), head_light)

	# Rear bumper, twin-plane wing, diffuser vanes, rain light and exhausts.
	add_box(body, Vector3(1.92, 0.10, 0.58), Vector3(0.0, 0.64, 1.74), carbon)
	add_box(body, Vector3(0.66, 0.22, 0.12), Vector3(0.0, 0.86, 1.98), carbon)
	add_box(body, Vector3(2.10, 0.062, 0.48), Vector3(0.0, 1.08, 1.88), carbon, Vector3(-0.055, 0.0, 0.0))
	add_box(body, Vector3(2.02, 0.052, 0.34), Vector3(0.0, 0.91, 1.88), carbon, Vector3(-0.075, 0.0, 0.0))
	for side in [-1.0, 1.0]:
		add_box(body, Vector3(0.065, 0.36, 0.66), Vector3(side * 1.055, 1.03, 1.84), carbon, Vector3(0.0, 0.0, -0.05 * side))
		add_box(body, Vector3(0.07, 0.40, 0.10), Vector3(side * 0.68, 0.87, 1.86), carbon, Vector3(0.0, 0.0, -0.06 * side))
		add_box(body, Vector3(0.07, 0.35, 0.10), Vector3(side * 0.46, 0.78, 1.87), carbon, Vector3(0.0, 0.0, -0.05 * side))
		add_box(body, Vector3(0.52, 0.14, 0.13), Vector3(side * 0.48, 0.62, 1.87), carbon)
	var brake_lights: Array[MeshInstance3D] = []
	brake_lights.append(add_box(body, Vector3(0.33, 0.145, 0.065), Vector3(-0.62, 0.59, 1.895), brake_light))
	brake_lights.append(add_box(body, Vector3(0.33, 0.145, 0.065), Vector3(0.62, 0.59, 1.895), brake_light))
	brake_lights.append(add_box(body, Vector3(0.22, 0.075, 0.055), Vector3(-0.62, 0.57, 1.935), brake_light))
	brake_lights.append(add_box(body, Vector3(0.22, 0.075, 0.055), Vector3(0.62, 0.57, 1.935), brake_light))
	brake_lights.append(add_box(body, Vector3(0.34, 0.075, 0.055), Vector3(0.0, 0.92, 2.02), brake_light))
	add_box(body, Vector3(0.17, 0.055, 0.055), Vector3(-0.43, 0.47, 1.94), reverse_light)
	add_box(body, Vector3(0.17, 0.055, 0.055), Vector3(0.43, 0.47, 1.94), reverse_light)
	add_box(body, Vector3(1.78, 0.055, 0.94), Vector3(0.0, 0.135, 1.74), carbon, Vector3(0.08, 0.0, 0.0))
	for x in [-0.62, -0.31, 0.0, 0.31, 0.62]:
		add_box(body, Vector3(0.045, 0.23, 0.62), Vector3(x, 0.20, 1.88), carbon)
		add_box(body, Vector3(0.055, 0.045, 0.46), Vector3(x, 0.35, 2.02), carbon, Vector3(-0.16, 0.0, 0.0))
	root.set_meta("brake_lights", brake_lights)
	root.set_meta("brake_material", brake_light)
	for side in [-1.0, 1.0]:
		add_cylinder(body, 0.105, 0.34, Vector3(side * 0.34, 0.60, 2.06), chrome, Vector3(PI * 0.5, 0.0, 0.0), 24)
		add_cylinder(body, 0.070, 0.36, Vector3(side * 0.34, 0.60, 2.08), carbon, Vector3(PI * 0.5, 0.0, 0.0), 24)

	# Wheel arches are curved extruded ribbons rather than stacked boxes.
	var wheel_positions := [
		Vector3(-0.92, 0.39, -1.28),
		Vector3(0.92, 0.39, -1.28),
		Vector3(-0.92, 0.39, 1.24),
		Vector3(0.92, 0.39, 1.24),
	]
	for wheel_pos in wheel_positions:
		add_wheel_arch(body, wheel_pos + Vector3(0.0, -0.02, 0.0), 0.23, carbon)

	var front_wheels: Array[Node3D] = []
	var all_wheels: Array[Node3D] = []
	for wheel_index in wheel_positions.size():
		var wheel_pos: Vector3 = wheel_positions[wheel_index]
		var is_front := wheel_pos.z < 0.0
		var tire_radius := 0.385 if is_front else 0.415
		var tire_width := 0.39 if is_front else 0.43
		var wheel_root := Node3D.new()
		wheel_root.name = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"][wheel_index]
		wheel_root.position = wheel_pos
		wheel_root.set_script(SuspensionWheel)
		body.add_child(wheel_root)

		add_cylinder(wheel_root, tire_radius, tire_width, Vector3.ZERO, tire, Vector3(0.0, 0.0, PI * 0.5), 36)
		add_cylinder(wheel_root, tire_radius * 0.79, tire_width * 1.025, Vector3.ZERO, tire_sidewall, Vector3(0.0, 0.0, PI * 0.5), 36)
		add_cylinder(wheel_root, tire_radius * 0.66, tire_width * 0.90, Vector3.ZERO, carbon, Vector3(0.0, 0.0, PI * 0.5), 32)
		add_torus(wheel_root, tire_radius * 0.62, tire_radius * 0.73, Vector3.ZERO, carbon, Vector3(0.0, 0.0, PI * 0.5), 32, 8)
		add_cylinder(wheel_root, tire_radius * 0.61, tire_width * 0.82, Vector3.ZERO, rim, Vector3(0.0, 0.0, PI * 0.5), 32)
		add_torus(wheel_root, tire_radius * 0.53, tire_radius * 0.625, Vector3.ZERO, rim, Vector3(0.0, 0.0, PI * 0.5), 32, 9)
		add_cylinder(wheel_root, 0.068, tire_width * 0.92, Vector3.ZERO, chrome, Vector3(0.0, 0.0, PI * 0.5), 20)

		var side_sign := signf(wheel_pos.x)
		var outward_x := side_sign * tire_width * 0.51
		add_cylinder(wheel_root, tire_radius * 0.68, 0.024, Vector3(outward_x, 0.0, 0.0), tire_sidewall, Vector3(0.0, 0.0, PI * 0.5), 32)
		add_torus(wheel_root, tire_radius * 0.52, tire_radius * 0.625, Vector3(outward_x, 0.0, 0.0), rim, Vector3(0.0, 0.0, PI * 0.5), 32, 9)
		var inward_x := -side_sign * tire_width * 0.22
		add_cylinder(wheel_root, tire_radius * 0.57, 0.026, Vector3(inward_x, 0.0, 0.0), brake_disc, Vector3(0.0, 0.0, PI * 0.5), 32)
		add_torus(wheel_root, tire_radius * 0.41, tire_radius * 0.57, Vector3(inward_x, 0.0, 0.0), brake_disc, Vector3(0.0, 0.0, PI * 0.5), 28, 6)
		add_box(wheel_root, Vector3(0.088, 0.19, 0.12), Vector3(inward_x - side_sign * 0.025, 0.13, -0.04), caliper)

		for spoke in 7:
			var angle := TAU * float(spoke) / 7.0
			var spoke_node := add_box(
				wheel_root,
				Vector3(0.032, tire_radius * 0.49, 0.045),
				Vector3(outward_x * 0.98, sin(angle) * tire_radius * 0.27, cos(angle) * tire_radius * 0.27),
				rim
			)
			spoke_node.rotation.x = angle
		add_cylinder(wheel_root, 0.060, 0.032, Vector3(outward_x * 1.025, 0.0, 0.0), carbon, Vector3(0.0, 0.0, PI * 0.5), 20)
		add_cylinder(wheel_root, 0.026, 0.040, Vector3(outward_x * 1.055, 0.0, 0.0), chrome, Vector3(0.0, 0.0, PI * 0.5), 16)

		if is_front:
			front_wheels.append(wheel_root)
		all_wheels.append(wheel_root)
	root.set_meta("front_wheels", front_wheels)
	root.set_meta("all_wheels", all_wheels)

	# Double wishbones and pushrods read clearly from side and cockpit views.
	for wheel_pos in wheel_positions:
		var side_sign := signf(wheel_pos.x)
		var chassis_x: float = wheel_pos.x - side_sign * 0.50
		var hub_upper: Vector3 = wheel_pos + Vector3(0.0, 0.13, 0.0)
		var hub_lower: Vector3 = wheel_pos + Vector3(0.0, -0.12, 0.0)
		add_beam(body, Vector3(chassis_x, wheel_pos.y + 0.16, wheel_pos.z - 0.18), hub_upper + Vector3(0.0, 0.0, -0.12), 0.030, titanium, 10)
		add_beam(body, Vector3(chassis_x, wheel_pos.y + 0.16, wheel_pos.z + 0.18), hub_upper + Vector3(0.0, 0.0, 0.12), 0.030, titanium, 10)
		add_beam(body, Vector3(chassis_x, wheel_pos.y - 0.15, wheel_pos.z - 0.18), hub_lower + Vector3(0.0, 0.0, -0.12), 0.035, titanium, 10)
		add_beam(body, Vector3(chassis_x, wheel_pos.y - 0.15, wheel_pos.z + 0.18), hub_lower + Vector3(0.0, 0.0, 0.12), 0.035, titanium, 10)
		add_beam(body, Vector3(chassis_x + side_sign * 0.14, wheel_pos.y + 0.35, wheel_pos.z), hub_upper, 0.024, chrome, 8)

	var smoke_emitters: Array[GPUParticles3D] = []
	if is_player:
		var smoke_color := make_material(Color(0.82, 0.86, 0.88, 0.36), 0.0, 0.74, Color.BLACK, "smoke")
		smoke_color.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke_color.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_color.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		for x in [-0.84, 0.84]:
			var smoke := GPUParticles3D.new()
			smoke.amount = 34
			smoke.lifetime = 1.25
			smoke.position = Vector3(x, 0.16, 1.32)
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
	for x in [-0.34, 0.34]:
		var outer_flame := add_cone(
			body,
			0.105,
			0.68,
			Vector3(x, 0.60, 2.42),
			boost_outer,
			Vector3(PI * 0.5, 0.0, 0.0),
			20
		)
		outer_flame.visible = false
		boost_flames.append(outer_flame)
		var inner_flame := add_cone(
			body,
			0.050,
			0.48,
			Vector3(x, 0.60, 2.34),
			boost_inner,
			Vector3(PI * 0.5, 0.0, 0.0),
			18
		)
		inner_flame.visible = false
		boost_flames.append(inner_flame)
	root.set_meta("boost_flames", boost_flames)

	for x in [-0.58, 0.58]:
		var headlamp := SpotLight3D.new()
		headlamp.name = "Headlight"
		headlamp.position = Vector3(x, 0.60, -2.10)
		headlamp.light_color = Color("#e6f7ff")
		headlamp.light_energy = 1.15 if is_player else 0.88
		headlamp.spot_range = 34.0 if is_player else 28.0
		headlamp.spot_angle = 28.0
		headlamp.shadow_enabled = false
		body.add_child(headlamp)
	if is_player:
		var camera := Camera3D.new()
		camera.name = "DriverEyeCamera"
		camera.position = Vector3(0.0, 1.61, -0.34)
		camera.near = 0.045
		camera.far = 520.0
		camera.fov = 76.0
		camera.look_at_from_position(camera.position, Vector3(0.0, 1.10, -8.0), Vector3.UP)
		camera.current = true
		body.add_child(camera)
		root.set_meta("camera", camera)

	root.set_meta("visual_layers", PackedStringArray([
		"paint",
		"carbon",
		"glass",
		"rubber",
		"forged_metal",
		"brake_hardware",
		"emissive_light",
	]))
	return root


class SuspensionWheel extends Node3D:
	var base_y := 0.0
	var previous_world_position := Vector3.ZERO
	var previous_velocity := Vector3.ZERO
	var oscillation_phase := 0.0

	func _ready() -> void:
		base_y = position.y
		previous_world_position = global_position

	func _physics_process(delta: float) -> void:
		if delta <= 0.0:
			return
		var current_position := global_position
		var velocity := (current_position - previous_world_position) / delta
		var acceleration := (velocity - previous_velocity) / delta
		previous_world_position = current_position
		previous_velocity = velocity

		var lateral_acceleration := 0.0
		var chassis := get_parent().get_parent() as Node3D
		if chassis:
			var right_axis := chassis.global_transform.basis.x.normalized()
			lateral_acceleration = acceleration.dot(right_axis)
		var speed_load := minf(velocity.length() * 0.00045, 0.012)
		var target_offset := clampf(
			-acceleration.y * 0.0045
			+ absf(lateral_acceleration) * 0.0013
			+ speed_load
			+ sin(oscillation_phase) * speed_load * 0.45,
			-0.030,
			0.048
		)
		oscillation_phase += delta * (8.0 + minf(velocity.length() * 0.35, 12.0))
		position.y = lerpf(position.y, base_y + target_offset, 1.0 - exp(-13.0 * delta))
