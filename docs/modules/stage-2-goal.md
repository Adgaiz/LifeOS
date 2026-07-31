# Stage 2：Goal 90 天目标模块设计

## 1. 目标

Goal 把长期愿景转化为可持续推进的阶段方向。90 天是默认模板，而不是强制期限；用户可以根据现实节奏调整开始与结束日期。

本模块交付：

- 创建、编辑、完成、恢复、归档和软删除目标。
- 每个目标包含至少一个 Key Result（关键结果）。
- Key Result 采用手动 `0–100%` 进度，目标总进度取所有 Key Result 进度的算术平均值。
- 目标可关联一个 Vision，Daily Action 可选择关联一个进行中的 Goal。
- 所有数据离线保存在 SQLite，Phase 1 不依赖服务端或登录。

## 2. 模块边界

```text
presentation -> application -> domain
data ------------------------> domain
```

- 页面通过 `GoalService` 和 Riverpod Provider 操作目标，不直接依赖 Drift。
- `GoalRepository` 是领域端口，`DriftGoalRepository` 是 Phase 1 的本地适配器。
- Goal 只管理阶段方向和关键结果；每日执行记录仍由 Daily Action 模块负责。
- Goal 可选关联 Vision。删除 Goal 不级联删除已关联的 Daily Action，避免破坏历史记录。

## 3. 进度规则

- 每个 Key Result 的进度是 `0–100` 的整数，由用户主动更新。
- 创建 Key Result 时默认进度为 `0%`。
- 目标总进度为 `Key Result 进度总和 / Key Result 数量`。
- 展示层将总进度四舍五入为整数；领域层保留平均值，避免累计舍入误差。
- 完成状态与进度解耦：用户可以主动标记目标已完成，也可以恢复为进行中。

示例：三个 Key Result 的进度分别为 `100%`、`50%` 和 `0%`，目标总进度为 `50%`。

## 4. 数据模型与迁移

SQLite schema 从 v3 升级到 v4，新增两张表：

### `goals`

- `id`：客户端 UUID。
- `vision_id`：可空，关联 Vision。
- `title / description`：目标标题和可选说明。
- `start_date / end_date`：本地日历日期；默认首尾共 90 个自然日。
- `status`：`active`、`completed` 或 `archived`。
- `created_at / updated_at`：UTC 时间点。
- `version`：每次编辑、状态变化和删除时递增。
- `deleted_at`：软删除时间。

### `goal_key_results`

- `id / goal_id`：客户端 UUID 与所属 Goal。
- `title`：关键结果描述。
- `progress`：`0–100` 整数，并由数据库约束范围。
- `position`：稳定保存用户定义的显示顺序。
- `created_at / updated_at / version / deleted_at`：审计、并发和软删除字段。

v1、v2、v3 数据库均通过增量迁移升级到 v4，不重建或清空已有 Daily 与 Vision 数据。

## 5. 交互原则

- 空状态强调“把方向变成一个阶段”，降低首次创建压力。
- 编辑器默认今天开始、包含首尾共 90 天，并提供一键恢复 90 天模板。
- 日期始终可编辑，结束日期不得早于开始日期。
- Key Result 可动态添加和移除，但目标必须至少保留一个。
- 列表卡片直接显示目标平均进度；点击 Key Result 可快速调整 `0–100%`。
- 离开未保存的编辑内容前二次确认；删除目标前明确告知 Daily Action 会保留。

## 6. 异常、隐私与一致性

- UI 与应用服务双层校验标题、日期、Key Result 数量和进度范围。
- Goal 与 Key Result 在同一数据库事务中保存，防止只写入部分数据。
- 单个 Key Result 进度更新使用原子数据库更新，并同步更新时间和版本号。
- 数据库异常仅展示通用提示，日志不记录目标标题、说明或 Key Result 内容。
- 本地数据保护遵循 ADR-0003，不宣称当前 SQLite 已加密。

## 7. 测试与验收

- 应用服务创建、编辑、校验、状态变化和 `0–100%` 进度测试。
- 领域层平均进度规则测试。
- Drift 事务保存、排序、原子进度更新和软删除测试。
- schema v1/v2/v3 → v4 增量迁移测试。
- 从空状态创建首个 90 天目标的 Widget 测试。
- Daily Action 关联 Goal 的应用服务测试。
- `dart format`、`flutter analyze`、`flutter test` 和 Android Debug APK 构建。
- vivo X100s 真机验证创建、编辑、进度更新、状态切换、Vision/Action 关联和重启后持久化。
