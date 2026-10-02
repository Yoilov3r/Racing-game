class_name ShowroomFactory
extends RefCounted


static func build(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Showroom"
	parent.add_child(root)

	var floor_material := CarFactory.make_material(Color("#080b11"), 0.72, 0.12)
	floor_material.clearcoat_enabled = true
	floor_material.clearcoat = 1.0
	floor_material.clearcoat_roughness = 0.05
	var platform_material := CarFactory.make_material(Color("#05070a"), 0.62, 0.16)
	platform_material.clearcoat_enabled = true
	platform_material.clearcoat = 0.95
	platform_material.clearcoat_roughness = 0.06
	var glow_material := CarFactory.make_material(Color("#e8fbff"), 0.0, 0.08, Color("#d9f8ff"))
	glow_material.emission_energy_multiplier = 1.8
	var frame_material := CarFactory.make_material(Color("#1c2532"), 0.78, 0.22)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(42.0, 34.0)
	floor_mesh.subdivide_width = 8
	floor_mesh.subdivide_depth = 8
	var floor := MeshInstance3D.new()
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.05, 0.0)
	floor.material_override = floor_material
	root.add_child(floor)

	var outer_ring := CylinderMesh.new()
	outer_ring.top_radius = 7.85
	outer_ring.bottom_radius = 7.85
	outer_ring.height = 0.10
	outer_ring.radial_segments = 96
	var ring := MeshInstance3D.new()
	ring.mesh = outer_ring
	ring.position = Vector3(0.0, -0.06, 0.0)
	ring.material_override = glow_material
	root.add_child(ring)

	var platform_mesh := CylinderMesh.new()
	platform_mesh.top_radius = 7.74
	platform_mesh.bottom_radius = 7.74
	platform_mesh.height = 0.12
	platform_mesh.radial_segments = 96
	var platform := MeshInstance3D.new()
	platform.mesh = platform_mesh
	platform.position = Vector3(0.0, 0.06, 0.0)
	platform.material_override = platform_material
	root.add_child(platform)

	# Geometric back wall inspired by the reference showroom.
	for row in 6:
		for column in 19:
			var hex_mesh := CylinderMesh.new()
			hex_mesh.top_radius = 0.53
			hex_mesh.bottom_radius = 0.53
			hex_mesh.height = 0.13
			hex_mesh.radial_segments = 6
			var hex := MeshInstance3D.new()
			hex.mesh = hex_mesh
			hex.position = Vector3(
				-13.5 + float(column) * 1.50 + (0.75 if row % 2 == 1 else 0.0),
				5.2 - float(row) * 1.28,
				8.8
			)
			hex.rotation = Vector3(PI * 0.5, 0.0, 0.0)
			hex.material_override = frame_material
			root.add_child(hex)
			if (column + row * 3) % 11 == 0:
				var edge_mesh := CylinderMesh.new()
				edge_mesh.top_radius = 0.34
				edge_mesh.bottom_radius = 0.34
				edge_mesh.height = 0.15
				edge_mesh.radial_segments = 6
				var edge := MeshInstance3D.new()
				edge.mesh = edge_mesh
				edge.position = hex.position + Vector3(0.0, 0.0, -0.05)
				edge.rotation = hex.rotation
				edge.material_override = glow_material
				root.add_child(edge)

	for z in [-4.0, 0.0, 4.0]:
		var strip := CarFactory.add_box(
			root,
			Vector3(25.0, 0.09, 0.16),
			Vector3(0.0, 6.45, z),
			glow_material
		)
		strip.rotation.x = -0.06

	var key_light := SpotLight3D.new()
	key_light.position = Vector3(3.8, 8.5, -4.5)
	key_light.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
	key_light.light_color = Color("#dcecff")
	key_light.light_energy = 8.0
	key_light.spot_range = 24.0
	key_light.spot_angle = 34.0
	key_light.shadow_enabled = true
	root.add_child(key_light)
	key_light.look_at(Vector3.ZERO, Vector3.UP)
	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(-4.5, 2.8, 5.5)
	rim_light.light_color = Color("#54cfff")
	rim_light.light_energy = 4.2
	rim_light.omni_range = 13.0
	root.add_child(rim_light)
	var warm_light := OmniLight3D.new()
	warm_light.position = Vector3(4.8, 1.8, 4.8)
	warm_light.light_color = Color("#8bacff")
	warm_light.light_energy = 2.5
	warm_light.omni_range = 12.0
	root.add_child(warm_light)

	return root
