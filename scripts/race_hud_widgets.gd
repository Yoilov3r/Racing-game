class_name RaceHudWidgets
extends RefCounted


static func make_style(
		background: Color,
		border: Color = Color.TRANSPARENT,
		border_width: int = 0,
		radius: int = 6
	) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	return style


static func make_panel(
		name: String,
		background: Color,
		border: Color = Color.TRANSPARENT,
		border_width: int = 0,
		radius: int = 6
	) -> Panel:
	var panel := Panel.new()
	panel.name = name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel",
		make_style(background, border, border_width, radius)
	)
	return panel


class SpeedGauge:
	extends Control

	var speed_ratio := 0.0
	var boost_ratio := 0.0
	var drifting := false
	var offroad := false
	var pulse := 0.0

	func set_metrics(
			next_speed_ratio: float,
			next_boost_ratio: float,
			next_drifting: bool,
			next_offroad: bool,
			next_pulse: float
		) -> void:
		speed_ratio = clampf(next_speed_ratio, 0.0, 1.0)
		boost_ratio = clampf(next_boost_ratio, 0.0, 1.0)
		drifting = next_drifting
		offroad = next_offroad
		pulse = clampf(next_pulse, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(size.x * 0.5, size.y * 0.58)
		var radius := minf(size.x, size.y) * 0.40
		var start_angle := deg_to_rad(148.0)
		var end_angle := deg_to_rad(392.0)
		draw_arc(
			center,
			radius,
			start_angle,
			end_angle,
			64,
			Color(0.08, 0.14, 0.18, 0.9),
			maxf(7.0, size.x * 0.026),
			true
		)
		var active_color := Color("#35e5ec")
		if boost_ratio > 0.01:
			active_color = Color("#ff9b2f")
		elif offroad:
			active_color = Color("#ffd55b")
		elif drifting:
			active_color = Color("#ff8a36")
		var active_end := lerpf(start_angle, end_angle, speed_ratio)
		draw_arc(
			center,
			radius,
			start_angle,
			active_end,
			64,
			Color(
				active_color.r,
				active_color.g,
				active_color.b,
				clampf(0.78 + pulse * 0.22, 0.0, 1.0)
			),
			maxf(7.0, size.x * 0.026),
			true
		)
		for tick_index in 9:
			var amount := float(tick_index) / 8.0
			var angle := lerpf(start_angle, end_angle, amount)
			var direction := Vector2(cos(angle), sin(angle))
			var tick_color := Color(0.62, 0.75, 0.79, 0.42)
			if amount <= speed_ratio:
				tick_color = active_color
			draw_line(
				center + direction * (radius + 7.0),
				center + direction * (radius + 15.0),
				tick_color,
				3.0,
				true
			)
		draw_arc(
			center,
			radius - 16.0,
			start_angle,
			end_angle,
			64,
			Color(0.55, 0.86, 0.9, 0.18),
			1.2,
			true
		)


class NitroGauge:
	extends Control

	var value := 0.0
	var active := false
	var is_ready := false
	var pulse := 0.0

	func set_metrics(next_value: float, next_active: bool, next_ready: bool, next_pulse: float) -> void:
		value = clampf(next_value, 0.0, 1.0)
		active = next_active
		is_ready = next_ready
		pulse = clampf(next_pulse, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var bounds := Rect2(Vector2.ZERO, size)
		draw_rect(bounds, Color(0.018, 0.045, 0.06, 0.86), true)
		draw_rect(bounds, Color(0.34, 0.77, 0.8, 0.35), false, 1.0)
		var cell_count := 18
		var gap := 2.0
		var cell_width := maxf(2.0, (size.x - gap * float(cell_count - 1)) / float(cell_count))
		var lit_count := int(ceil(value * float(cell_count)))
		for cell_index in cell_count:
			var cell_rect := Rect2(
				Vector2(float(cell_index) * (cell_width + gap), 2.0),
				Vector2(cell_width, maxf(2.0, size.y - 4.0))
			)
			var color := Color(0.08, 0.15, 0.18, 0.9)
			if cell_index < lit_count:
				if active:
					color = Color("#ffb13d")
				elif is_ready:
					color = Color(
						0.35 + pulse * 0.25,
						0.94,
						0.92,
						0.95
					)
				else:
					color = Color("#20c8d1")
			draw_rect(cell_rect, color, true)
		var threshold_x := size.x * 0.10
		draw_line(
			Vector2(threshold_x, 0.0),
			Vector2(threshold_x, size.y),
			Color("#fff0a6"),
			2.0,
			true
		)


class DriftGauge:
	extends Control

	var value := 0.0
	var active := false

	func set_metrics(next_value: float, next_active: bool) -> void:
		value = clampf(next_value, 0.0, 1.0)
		active = next_active
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(size.x * 0.5, size.y * 0.76)
		var radius := minf(size.x * 0.43, size.y * 0.68)
		var start_angle := deg_to_rad(205.0)
		var end_angle := deg_to_rad(335.0)
		draw_arc(
			center,
			radius,
			start_angle,
			end_angle,
			28,
			Color(0.48, 0.60, 0.63, 0.30),
			4.0,
			true
		)
		var marker_angle := lerpf(start_angle, end_angle, value)
		var marker_direction := Vector2(cos(marker_angle), sin(marker_angle))
		draw_line(
			center + marker_direction * (radius - 6.0),
			center + marker_direction * (radius + 6.0),
			Color("#ff9b36") if active else Color("#f3d276"),
			3.0,
			true
		)
		draw_circle(
			center + marker_direction * radius,
			3.2,
			Color("#fff3c7") if active else Color("#ffcf68")
		)


class CountdownLights:
	extends Control

	var lit_count := 0
	var go := false
	var pulse := 0.0

	func set_state(next_lit_count: int, next_go: bool, next_pulse: float) -> void:
		lit_count = clampi(next_lit_count, 0, 3)
		go = next_go
		pulse = clampf(next_pulse, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var radius := minf(size.y * 0.34, size.x * 0.12)
		var gap := size.x / 4.0
		var center_y := size.y * 0.50
		for lamp_index in 3:
			var center := Vector2(gap * float(lamp_index + 1), center_y)
			draw_circle(center, radius + 5.0, Color(0.02, 0.035, 0.045, 0.88))
			var lit := go or lamp_index < lit_count
			var color := Color("#ff3f48") if not go else Color("#37e58d")
			if not lit:
				color = Color(0.18, 0.22, 0.24, 0.72)
			elif pulse > 0.0:
				color = color.lerp(Color.WHITE, pulse * 0.34)
			draw_circle(center, radius, color)
			draw_arc(center, radius + 1.5, 0.0, TAU, 24, Color(1, 1, 1, 0.28), 1.5, true)
