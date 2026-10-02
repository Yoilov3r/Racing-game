class_name DrivingTuning
extends Resource


@export_group("Engine")
@export_range(20.0, 60.0, 0.1) var max_forward_speed := 38.0
@export_range(30.0, 80.0, 0.1) var nitro_max_speed := 54.0
@export_range(8.0, 40.0, 0.1) var launch_acceleration := 24.0
@export_range(1.0, 18.0, 0.1) var high_speed_acceleration := 5.2
@export_range(0.5, 3.0, 0.05) var acceleration_curve_power := 1.42
@export_range(0.0, 40.0, 0.1) var nitro_acceleration_bonus := 20.0
@export_range(4.0, 24.0, 0.1) var reverse_acceleration := 11.5
@export_range(4.0, 18.0, 0.1) var reverse_max_speed := 12.0
@export_range(0.0, 3.0, 0.01) var rolling_drag := 0.52
@export_range(0.0, 0.01, 0.0001) var aero_drag := 0.0011

@export_group("Braking")
@export_range(20.0, 90.0, 0.1) var brake_deceleration := 48.0
@export_range(0.0, 1.0, 0.01) var brake_high_speed_bonus := 0.34

@export_group("Steering")
@export_range(2.0, 24.0, 0.1) var steering_input_attack := 10.0
@export_range(2.0, 24.0, 0.1) var steering_input_release := 13.0
@export_range(0.1, 1.8, 0.01) var low_speed_yaw_rate := 1.06
@export_range(0.1, 1.4, 0.01) var high_speed_yaw_rate := 0.70
@export_range(0.5, 2.0, 0.01) var drift_yaw_multiplier := 1.28
@export_range(0.8, 3.0, 0.01) var max_yaw_rate := 2.05
@export_range(0.2, 6.0, 0.05) var steering_min_speed := 0.9

@export_group("Drift And Grip")
@export_range(2.0, 20.0, 0.1) var drift_min_speed := 7.2
@export_range(1.0, 16.0, 0.1) var drift_entry_rate := 7.5
@export_range(1.0, 12.0, 0.1) var drift_exit_rate := 3.2
@export_range(3.0, 20.0, 0.1) var normal_lateral_grip := 10.8
@export_range(0.5, 6.0, 0.05) var drift_lateral_grip := 1.85
@export_range(0.0, 8.0, 0.1) var countersteer_grip_bonus := 3.8
@export_range(0.2, 1.8, 0.01) var slip_generation := 0.82
@export_range(0.0, 1.8, 0.01) var drift_slip_generation_bonus := 0.72
@export_range(8.0, 55.0, 1.0) var max_slip_angle_degrees := 44.0
@export_range(4.0, 24.0, 1.0) var max_normal_slip_angle_degrees := 10.0
@export_range(0.0, 1.0, 0.01) var drift_drag := 0.16

@export_group("Offroad")
@export_range(0.25, 1.0, 0.01) var offroad_speed_factor := 0.58
@export_range(0.0, 6.0, 0.05) var offroad_extra_drag := 2.6
@export_range(0.1, 1.0, 0.01) var offroad_grip_multiplier := 0.42
@export_range(0.1, 1.0, 0.01) var offroad_traction_multiplier := 0.22
@export_range(0.5, 6.0, 0.1) var offroad_overspeed_recovery := 3.0

@export_group("Nitro")
@export_range(1.0, 50.0, 0.5) var nitro_activation_cost := 22.0
@export_range(0.0, 12.0, 0.1) var nitro_passive_charge := 3.8
@export_range(0.0, 20.0, 0.1) var nitro_steering_charge := 4.8
@export_range(0.0, 60.0, 0.5) var nitro_drift_charge := 24.0
@export_range(0.0, 180.0, 1.0) var nitro_drift_angle_charge := 112.0
@export_range(0.0, 20.0, 0.1) var nitro_drain_rate := 5.2

@export_group("Collision")
@export_range(0.0, 1.0, 0.01) var collision_speed_retention := 0.74
@export_range(0.0, 1.0, 0.01) var collision_lateral_retention := 0.18
@export_range(0.0, 1.0, 0.01) var collision_camera_trauma := 0.72
@export_range(0.2, 3.0, 0.05) var collision_cooldown := 0.72

@export_group("Camera")
@export_range(50.0, 90.0, 0.5) var base_fov := 76.0
@export_range(0.0, 20.0, 0.5) var speed_fov_gain := 11.0
@export_range(0.0, 12.0, 0.5) var nitro_fov_boost := 4.0
@export_range(0.0, 12.0, 0.1) var fov_attack_rate := 5.2
@export_range(0.0, 12.0, 0.1) var fov_release_rate := 3.2
@export_range(0.0, 0.3, 0.005) var acceleration_camera_stretch := 0.072
@export_range(0.0, 0.05, 0.001) var base_camera_shake := 0.0025
@export_range(0.0, 0.08, 0.001) var drift_camera_shake := 0.012
@export_range(0.0, 0.08, 0.001) var nitro_camera_shake := 0.009
@export_range(0.0, 0.12, 0.001) var collision_camera_kick := 0.055
@export_range(0.0, 0.12, 0.001) var body_roll_steering := 0.026
@export_range(0.0, 0.12, 0.001) var body_roll_drift := 0.048
@export_range(0.0, 0.08, 0.001) var body_roll_lateral := 0.025
@export_range(0.02, 0.24, 0.005) var max_body_roll := 0.11

@export_group("Effects")
@export_range(100, 2000, 50) var max_skid_segments := 900
@export_range(0.08, 0.8, 0.01) var skid_mark_width := 0.22
@export_range(0.05, 0.6, 0.01) var skid_segment_length := 0.16
@export_range(2.0, 20.0, 0.1) var skid_min_speed := 5.0
