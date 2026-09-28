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
	var panel := Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0))
	draw_rect(panel, Color(0.015, 0.035, 0.055, 0.82), true)
	draw_rect(panel, Color(0.35, 0.88, 0.92, 0.75), false, 2.0)
	var closed_track := PackedVector2Array()
	for point in track_points:
		closed_track.append(_map_point(point))
	if closed_track.size() > 1:
		closed_track.append(closed_track[0])
	draw_polyline(closed_track, Color("#8ea8b2"), 6.0, true)
	draw_polyline(closed_track, Color("#253746"), 3.2, true)
	for shortcut_path in shortcut_paths:
		var mapped_shortcut := PackedVector2Array()
		for point in shortcut_path:
			mapped_shortcut.append(_map_point(point))
		draw_polyline(mapped_shortcut, Color("#ff9f27"), 3.6, true)
	if track_points.size() > 1:
		var start_point := _map_point(track_points[0])
		var finish_point := _map_point(track_points[1])
		draw_line(start_point, finish_point, Color.WHITE, 4.0, true)
	for ai_index in ai_positions.size():
		draw_circle(ai_positions[ai_index], 4.2, ai_colors[ai_index % ai_colors.size()])
	var right := Vector2(-player_heading.y, player_heading.x)
	var player_triangle := PackedVector2Array([
		player_position + player_heading * 8.0,
		player_position - player_heading * 5.0 + right * 5.0,
		player_position - player_heading * 5.0 - right * 5.0,
	])
	draw_colored_polygon(player_triangle, Color("#ffffff"))
	draw_polyline(PackedVector2Array([
		player_triangle[0],
		player_triangle[1],
		player_triangle[2],
		player_triangle[0],
	]), Color("#101820"), 1.6, true)


func _map_point(world_point: Vector2) -> Vector2:
	var map_size := map_max - map_min
	var inner := Rect2(Vector2(10.0, 10.0), size - Vector2(20.0, 20.0))
	if map_size.x <= 0.001 or map_size.y <= 0.001:
		return inner.get_center()
	var scale_factor := minf(inner.size.x / map_size.x, inner.size.y / map_size.y)
	var drawing_size := map_size * scale_factor
	var offset := inner.position + (inner.size - drawing_size) * 0.5
	var normalized := (world_point - map_min) / map_size
	return offset + normalized * drawing_size
