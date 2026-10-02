# AI Race Audit

Simulation: fixed 60 Hz, standard difficulty, five personality profiles.
Rubber band: target-speed factor only, hard-capped at +/-6%; no position or collision bypass.

## Driver Profiles

| Driver | Speed | Corner | Aggression | Drift | Mistake | Reaction |
|---|---:|---:|---:|---:|---:|---:|
| 稳健 · 岚 | 0.95 | 0.98 | 0.24 | 0.12 | 0.12 | 0.26 |
| 激进 · 赤锋 | 1.01 | 1.04 | 0.94 | 0.38 | 0.34 | 0.12 |
| 漂移 · 白刃 | 0.97 | 0.96 | 0.58 | 0.96 | 0.48 | 0.20 |
| 失误 · 小满 | 0.93 | 0.90 | 0.36 | 0.26 | 1.00 | 0.38 |
| 机会 · 追星 | 0.99 | 1.00 | 0.68 | 0.34 | 0.24 | 0.16 |

## Difficulty Presets

| Difficulty | Speed | Corner | Reaction | Mistake | Racecraft |
|---|---:|---:|---:|---:|---:|
| 新手 | 0.88 | 0.88 | 1.35 | 1.60 | 0.55 |
| 标准 | 0.96 | 0.96 | 1.00 | 1.00 | 0.82 |
| 高手 | 1.02 | 1.02 | 0.78 | 0.70 | 1.00 |
| 大师 | 1.06 | 1.06 | 0.62 | 0.45 | 1.18 |

## 霓虹夜街

- Track: 1299 m, 3 laps, 1 shortcuts
- All five AI finished: YES
- Race window: 191.783 s to 204.483 s; simulated 204.5 s
- Peak simultaneous offroad: 2/5; peak in shortcut: 1/5; rubber band cap observed: 6.00%
- Performance: 11.048 s wall, 0.1801 ms per AI-frame, 18.5x realtime

| AI | Finished | Time | Avg km/h | Max km/h | Max step m | Offroad | Out bounds | Shortcut block | Stuck | Recoveries | Mistakes | Collision frames |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 稳健 · 岚 | YES | 191.783 | 76.0 | 155.9 | 0.722 | 1.08% | 0 | 0 | 0 | 0 | 2 | 0 |
| 激进 · 赤锋 | YES | 191.967 | 75.3 | 163.0 | 0.755 | 0.32% | 0 | 0 | 0 | 0 | 5 | 0 |
| 漂移 · 白刃 | YES | 198.133 | 74.6 | 161.4 | 0.839 | 7.15% | 0 | 0 | 0 | 0 | 7 | 161 |
| 失误 · 小满 | YES | 204.283 | 71.3 | 146.8 | 0.680 | 0.00% | 0 | 0 | 0 | 0 | 13 | 73 |
| 机会 · 追星 | YES | 204.483 | 70.7 | 154.1 | 0.714 | 0.00% | 0 | 0 | 0 | 0 | 4 | 96 |

## 雪山竞速

- Track: 2598 m, 2 laps, 1 shortcuts
- All five AI finished: YES
- Race window: 184.883 s to 192.350 s; simulated 192.3 s
- Peak simultaneous offroad: 2/5; peak in shortcut: 1/5; rubber band cap observed: 6.00%
- Performance: 11.882 s wall, 0.2059 ms per AI-frame, 16.2x realtime

| AI | Finished | Time | Avg km/h | Max km/h | Max step m | Offroad | Out bounds | Shortcut block | Stuck | Recoveries | Mistakes | Collision frames |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 稳健 · 岚 | YES | 184.883 | 101.7 | 155.9 | 0.723 | 0.00% | 0 | 0 | 0 | 0 | 2 | 0 |
| 激进 · 赤锋 | YES | 185.300 | 101.3 | 169.8 | 0.787 | 1.43% | 0 | 0 | 0 | 0 | 4 | 0 |
| 漂移 · 白刃 | YES | 189.000 | 100.5 | 158.4 | 0.734 | 3.71% | 0 | 0 | 0 | 0 | 6 | 0 |
| 失误 · 小满 | YES | 191.950 | 98.7 | 157.1 | 0.729 | 0.00% | 0 | 0 | 0 | 0 | 11 | 0 |
| 机会 · 追星 | YES | 192.350 | 98.8 | 156.6 | 0.739 | 0.91% | 0 | 0 | 0 | 0 | 3 | 0 |

## 环城极速

- Track: 3015 m, 2 laps, 2 shortcuts
- All five AI finished: YES
- Race window: 212.683 s to 223.567 s; simulated 223.6 s
- Peak simultaneous offroad: 2/5; peak in shortcut: 2/5; rubber band cap observed: 6.00%
- Performance: 21.232 s wall, 0.3166 ms per AI-frame, 10.5x realtime

| AI | Finished | Time | Avg km/h | Max km/h | Max step m | Offroad | Out bounds | Shortcut block | Stuck | Recoveries | Mistakes | Collision frames |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 稳健 · 岚 | YES | 212.683 | 103.6 | 159.8 | 0.742 | 1.54% | 0 | 0 | 0 | 0 | 3 | 43 |
| 激进 · 赤锋 | YES | 212.883 | 102.7 | 162.8 | 0.754 | 1.60% | 0 | 0 | 0 | 0 | 5 | 199 |
| 漂移 · 白刃 | YES | 213.150 | 103.2 | 162.4 | 0.752 | 0.34% | 0 | 0 | 0 | 0 | 7 | 118 |
| 失误 · 小满 | YES | 223.383 | 99.3 | 157.1 | 0.728 | 1.10% | 0 | 0 | 0 | 0 | 15 | 85 |
| 机会 · 追星 | YES | 223.567 | 98.9 | 170.8 | 0.791 | 0.07% | 0 | 0 | 0 | 0 | 4 | 28 |

## Verdict

- PASS: all acceptance checks passed.

