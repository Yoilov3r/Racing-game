# Q版氮气竞速驾驶审计

- 固定步长：60 Hz
- 测试用例：37
- 失败：0
- 输入入口：与实机相同的 `_update_player` 驾驶路径

| 结果 | 赛道 | 用例 | 指标 |
| --- | --- | --- | --- |
| 通过 | 霓虹夜街 | acceleration_curve | `{"max_step_mps":0.4,"top_speed_mps":38.0,"zero_to_100_s":1.98}` |
| 通过 | 霓虹夜街 | brake_reverse | `{"max_step_mps":1.072,"reverse_mps":-12.0,"stop_time_s":0.72}` |
| 通过 | 霓虹夜街 | nitro_camera | `{"boost_speed_mps":54.0,"max_fov":91.0}` |
| 通过 | 霓虹夜街 | low_speed_steering | `{"max_heading_step_rad":0.015,"max_yaw_rps":0.9,"sign_flips":0}` |
| 通过 | 霓虹夜街 | high_speed_steering | `{"final_slip_deg":3.19,"max_yaw_rps":0.8,"sign_flips":0}` |
| 通过 | 霓虹夜街 | drift_entry | `{"peak_slip_deg":37.7,"peak_smoke":1.0,"peak_yaw_rps":1.01,"skid_segments":474}` |
| 通过 | 霓虹夜街 | drift_exit | `{"final_blend":0.06,"final_slip_deg":3.33,"recovery_frames":53}` |
| 通过 | 霓虹夜街 | offroad_penalty | `{"final_speed_mps":21.54,"max_step_mps":0.321,"offroad_frames":257,"soft_limit_mps":22.04}` |
| 通过 | 霓虹夜街 | collision_feedback | `{"audio_events_delta":1,"cooldown_before_camera_s":0.72,"cooldown_s":0.72,"initial_distance_m":8.69,"initial_outward_speed_mps":14.0,"offroad_limit_m":8.45,"outward_speed_after_mps":-1.86,"trauma":0.27}` |
| 通过 | 霓虹夜街 | slope_uphill | `{"final_speed_mps":19.05,"grade_percent":1.6,"max_y_step_m":0.0145}` |
| 通过 | 霓虹夜街 | slope_downhill | `{"final_speed_mps":19.05,"grade_percent":-2.0,"max_y_step_m":0.0258}` |
| 通过 | 霓虹夜街 | shortcut_0 | `{"completed":true,"final_index":68,"final_path_distance_m":2.06,"final_speed_mps":6.12,"frames_used":2869,"max_slip_deg":4.02,"max_y_step_m":0.0175,"on_shortcut_frames":2869}` |
| 通过 | 雪山竞速 | acceleration_curve | `{"max_step_mps":0.4,"top_speed_mps":38.0,"zero_to_100_s":1.98}` |
| 通过 | 雪山竞速 | brake_reverse | `{"max_step_mps":1.072,"reverse_mps":-12.0,"stop_time_s":0.72}` |
| 通过 | 雪山竞速 | nitro_camera | `{"boost_speed_mps":54.0,"max_fov":91.0}` |
| 通过 | 雪山竞速 | low_speed_steering | `{"max_heading_step_rad":0.015,"max_yaw_rps":0.9,"sign_flips":0}` |
| 通过 | 雪山竞速 | high_speed_steering | `{"final_slip_deg":3.2,"max_yaw_rps":0.8,"sign_flips":0}` |
| 通过 | 雪山竞速 | drift_entry | `{"peak_slip_deg":37.7,"peak_smoke":1.0,"peak_yaw_rps":1.01,"skid_segments":474}` |
| 通过 | 雪山竞速 | drift_exit | `{"final_blend":0.06,"final_slip_deg":3.33,"recovery_frames":53}` |
| 通过 | 雪山竞速 | offroad_penalty | `{"final_speed_mps":21.15,"max_step_mps":0.423,"offroad_frames":300,"soft_limit_mps":22.04}` |
| 通过 | 雪山竞速 | collision_feedback | `{"audio_events_delta":1,"cooldown_before_camera_s":0.72,"cooldown_s":0.72,"initial_distance_m":9.64,"initial_outward_speed_mps":14.0,"offroad_limit_m":9.4,"outward_speed_after_mps":-1.86,"trauma":0.27}` |
| 通过 | 雪山竞速 | slope_uphill | `{"final_speed_mps":18.8,"grade_percent":16.1,"max_y_step_m":0.102}` |
| 通过 | 雪山竞速 | slope_downhill | `{"final_speed_mps":18.76,"grade_percent":-17.4,"max_y_step_m":0.0983}` |
| 通过 | 雪山竞速 | shortcut_0 | `{"completed":true,"final_index":68,"final_path_distance_m":4.48,"final_speed_mps":6.12,"frames_used":5931,"max_slip_deg":3.7,"max_y_step_m":0.056,"on_shortcut_frames":5931}` |
| 通过 | 环城极速 | acceleration_curve | `{"max_step_mps":0.4,"top_speed_mps":38.0,"zero_to_100_s":1.98}` |
| 通过 | 环城极速 | brake_reverse | `{"max_step_mps":1.072,"reverse_mps":-12.0,"stop_time_s":0.72}` |
| 通过 | 环城极速 | nitro_camera | `{"boost_speed_mps":54.0,"max_fov":91.0}` |
| 通过 | 环城极速 | low_speed_steering | `{"max_heading_step_rad":0.015,"max_yaw_rps":0.9,"sign_flips":0}` |
| 通过 | 环城极速 | high_speed_steering | `{"final_slip_deg":3.19,"max_yaw_rps":0.8,"sign_flips":0}` |
| 通过 | 环城极速 | drift_entry | `{"peak_slip_deg":37.7,"peak_smoke":1.0,"peak_yaw_rps":1.01,"skid_segments":474}` |
| 通过 | 环城极速 | drift_exit | `{"final_blend":0.06,"final_slip_deg":3.33,"recovery_frames":53}` |
| 通过 | 环城极速 | offroad_penalty | `{"final_speed_mps":21.15,"max_step_mps":0.316,"offroad_frames":300,"soft_limit_mps":22.04}` |
| 通过 | 环城极速 | collision_feedback | `{"audio_events_delta":1,"cooldown_before_camera_s":0.72,"cooldown_s":0.72,"initial_distance_m":10.89,"initial_outward_speed_mps":14.0,"offroad_limit_m":10.65,"outward_speed_after_mps":-1.86,"trauma":0.27}` |
| 通过 | 环城极速 | slope_uphill | `{"final_speed_mps":19.02,"grade_percent":6.0,"max_y_step_m":0.0344}` |
| 通过 | 环城极速 | slope_downhill | `{"final_speed_mps":18.93,"grade_percent":-11.4,"max_y_step_m":0.0779}` |
| 通过 | 环城极速 | shortcut_0 | `{"completed":true,"final_index":68,"final_path_distance_m":3.79,"final_speed_mps":6.06,"frames_used":5137,"max_slip_deg":3.71,"max_y_step_m":0.0254,"on_shortcut_frames":5137}` |
| 通过 | 环城极速 | shortcut_1 | `{"completed":true,"final_index":68,"final_path_distance_m":3.69,"final_speed_mps":6.07,"frames_used":4917,"max_slip_deg":3.91,"max_y_step_m":0.0241,"on_shortcut_frames":4917}` |

自动测试不会替代人工手感评估；它用于阻止不连续速度、无限侧滑、坡度/捷径高度跳变和输入抖动回归。