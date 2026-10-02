class_name RaceMinimap
extends Control

var track_points := PackedVector2Array()
var shortcut_paths: Array[PackedVector2Array] = []
var map_min := Vector2.ZERO
var map_max := Vector2.ONE
var player_position := Vector2.ZERO
var player_heading := Vector2.UP
var ai_positions: Array[Vector2] = []
var ai_colors: Array[Color] = []
var panel_style := StyleBoxFlat.new()


func _ready() -> void:
	panel_style.bg_color = Color(0.008, 0.025, 0.038, 0.88)
	panel_style.border_color = Color(0.25, 0.83, 0.86, 0.62)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(5)
	panel_style.anti_aliasing = true


func configure(
		samples: PackedVector3Array,
		shortcuts: Array,
		colors: Array[Color]
	) -> void:
	track_points.clear()
	shortcut_paths.clear()
	map_min = Vector2(INF, INF)
	map_max = Vector2(-INF, -INF)
	for sample in samples:
		var point := Vector2(sample.x, sample.z)
		track_points.append(point)
		map_min = map_min.min(point)
		map_max = map_max.max(point)
	for shortcut in shortcuts:
		var path := PackedVector2Array()
		for sample in shortcut["samples"]:
			var point := Vector2(sample.x, sample.z)
			path.append(point)
			map_min = map_min.min(point)
			map_max = map_max.max(point)
		shortcut_paths.append(path)
	ai_colors = colors
	var padding := Vector2(18.0, 18.0)
	map_min -= padding
	map_max += padding
	queue_redraw()


func update_racers(
		player_world: Vector3,
		forward: Vector3,
		ai_world_positions: Array[Vector3]
	) -> void:
	player_position = _map_point(Vector2(player_world.x, player_world.z))
	var heading := Vector2(forward.x, forward.z)
	if heading.length_squared() > 0.001:
		player_heading = heading.normalized()
	ai_positions.clear()
	for position in ai_world_positions:
		ai_positions.append(_map_point(Vector2(position.x, position.z)))
	queue_redraw()


func _draw() -> void:
	if track_points.is_empty():
		return
	var panel := Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0))
	draw_style_box(panel_style, panel)
	draw_line(Vector2(1.0, 30.0), Vector2(size.x - 2.0, 30.0), Color(0.28, 0.78, 0.82, 0.22), 1.0)
	var closed_track := PackedVector2Array()
	for point in track_points:
		closed_track.append(_map_point(point))
	if closed_track.size() > 1:
		closed_track.append(closed_track[0])
	draw_polyline(closed_track, Color(0.22, 0.86, 0.90, 0.17), 9.0, true)
	draw_polyline(closed_track, Color("#b9d3d7"), 5.4, true)
	draw_polyline(closed_track, Color("#1d3340"), 3.0, true)
	for shortcut_path in shortcut_paths:
		var mapped_shortcut := PackedVector2Array()
		for point in shortcut_path:
			mapped_shortcut.append(_map_point(point))
		draw_polyline(mapped_shortcut, Color(1.0, 0.58, 0.16, 0.24), 6.0, true)
		draw_polyline(mapped_shortcut, Color("#ff9f27"), 3.2, true)
	if track_points.size() > 1:
		var start_point := _map_point(track_points[0])
		var tangent := (_map_point(track_points[1]) - start_point).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		for tile in 4:
			var center := start_point + tangent * (float(tile) * 2.4 - 3.6)
			var color := Color.WHITE if tile % 2 == 0 else Color("#17242b")
			var extent := normal.abs() * 3.2 + tangent.abs() * 1.0
			draw_rect(Rect2(center - extent, extent * 2.0), color, true)
	for ai_index in ai_positions.size():
		var ai_position := ai_positions[ai_index]
		var ai_color: Color = ai_colors[ai_index % ai_colors.size()]
		draw_circle(ai_position, 5.1, Color(0.01, 0.03, 0.04, 0.92))
		draw_circle(ai_position, 3.5, ai_color)
	var right := Vector2(-player_heading.y, player_heading.x)
	var player_triangle := PackedVector2Array([
		player_position + player_heading * 9.2,
		player_position - player_heading * 5.8 + right * 5.4,
		player_position - player_heading * 5.8 - right * 5.4,
	])
	draw_colored_polygon(player_triangle, Color("#eaffff"))
	draw_polyline(PackedVector2Array([
		player_triangle[0],
		player_triangle[1],
		player_triangle[2],
		player_triangle[0],
	]), Color("#13cbd4"), 2.0, true)


func _map_point(world_point: Vector2) -> Vector2:
	var map_size := map_max - map_min
	var inner := Rect2(Vector2(12.0, 36.0), size - Vector2(24.0, 48.0))
	if map_size.x <= 0.001 or map_size.y <= 0.001:
		return inner.get_center()
	var scale_factor := minf(inner.size.x / map_size.x, inner.size.y / map_size.y)
	var drawing_size := map_size * scale_factor
	var offset := inner.position + (inner.size - drawing_size) * 0.5
	var normalized := (world_point - map_min) / map_size
	return offset + normalized * drawing_size
