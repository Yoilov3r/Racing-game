# 五部分同步集成规范

## 角色

本线程是项目唯一的整合与协调入口。五个独立设计线程只对自己的领域文件负责，
本线程负责合并、解决跨领域冲突、执行兼容性检查、更新版本、导出和推送 GitHub。

## 五个部分

| 编号 | 部分 | 主要文件 | 对外契约 |
| --- | --- | --- | --- |
| 1 | 车辆模型与材质 | `scripts/car_factory.gd` | 车辆节点及 `camera/all_wheels/front_wheels/brake_material/brake_lights/smoke_emitters/boost_flames/visual_layers` 元数据 |
| 2 | 赛道与环境 | `scripts/track_factory.gd` | `build_track()` 返回字典、捷径字典、`get_quality_budget()` |
| 3 | 驾驶物理与反馈 | `scripts/driving_tuning.gd`、`main.gd` 驾驶段落 | 调参属性、车辆状态、碰撞与镜头参数 |
| 4 | 比赛、AI、UI 与音频 | `main.gd` 比赛段落、`scripts/race_hud_widgets.gd`、`scripts/race_minimap.gd`、`scripts/race_audio_director.gd`、`scripts/showroom_factory.gd` | `race_state`、HUD 节点、AI 数组、比赛结果和音频状态 |
| 5 | 资源、性能与构建 | `assets/`、`project.godot`、`export_presets.cfg`、`quality_audit.gd`、`qa/race_ui_audit.gd`、`qa/smoke_render.gd` | 资源路径、质量预算、导出版本和测试产物 |

`main.gd` 同时包含驾驶和比赛逻辑，是当前最容易发生冲突的文件。未完成服务拆分前，
各部分只能修改自己负责的函数段落；整合线程合并时必须逐段核对，不能整文件覆盖。

## 部分提交格式

每个部分完成一轮设计后，提供一份简短报告：

```text
部分：
版本/日期：
修改文件：
对外契约是否变化：
依赖的其他部分：
已执行测试：
截图或日志：
已知风险：
```

报告可以写入 `qa/parts/<部分名>.md`。如果契约发生变化，必须同时说明受影响字段，
不能只提交代码。

## 整合顺序

1. 先合并资源和性能配置，确保输出路径与质量预算稳定。
2. 再合并车辆模型，确认元数据名称不变化。
3. 合并赛道与环境，确认返回字典和捷径字段不变化。
4. 合并驾驶物理，验证调参属性与车辆、赛道元数据匹配。
5. 最后合并比赛、AI、UI 和音频，验证完整状态流。
6. 由整合线程统一修改版本文件并重新导出。

## 整体大更新门禁

满足以下任一条件即视为一次整体大更新：

- 两个或以上部分同时产生用户可见变化。
- 任一对外契约新增、删除或改名。
- 驾驶、碰撞、赛道返回数据、车辆元数据或导出格式发生变化。
- 完成一个明确的版本阶段，例如 `2.8`、`2.9`。

整体大更新必须依次执行：

1. Godot 编辑器脚本解析。
2. `integration_check.gd` 契约检查。
3. `driving_audit.gd` 固定步长驾驶回归，失败数必须为 `0`。
4. `ai_race_audit.gd` 三赛道 AI 完赛与越界检查。
5. `quality_audit.gd` 网格、灯光、捷径净空与质量预算检查。
6. `qa/race_ui_audit.gd` 菜单、倒计时、比赛、暂停、完赛界面和音频状态检查。
7. `art_audit.gd` 三赛道和展厅渲染检查。
8. 主场景无界面启动冒烟测试。
9. Windows 导出并核对产品版本。
10. 更新 `README.md`、`VERSION_METRICS.md` 和 `CODEX_HANDOFF.md`。
11. 检查 `git status`，确认没有覆盖其他部分的未提交改动。
12. 提交、同步远程 `main`、推送；必要时创建同版本 GitHub Release。

可以在项目根目录执行一键门禁：

```powershell
.\run_integration_gate.ps1
```

门禁默认执行解析、五部分契约、驾驶回归、AI 竞速、渲染、启动和导出；调试时可用
`-SkipRender` 或 `-SkipExport` 缩短单次检查，但正式推送不得跳过任何步骤。

## GitHub 规则

- 不再按三次更新累计，而是每次整体大更新后同步推送一次。
- 推送前先拉取并核对远程 `main`，禁止强制推送。
- 提交前必须通过上述兼容性门禁；任何一步失败都不得推送。
- 推送后记录提交号和版本号，下一轮从远程最新提交继续。
