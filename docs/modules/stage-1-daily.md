# Stage 1：Daily 本地每日闭环设计

## 1. 目标

Daily 是 LifeOS 的第一个业务模块。它不追求完整的人生管理能力，而是先验证一个最重要的问题：用户是否愿意每天打开应用，用很低的成本看见并安排今天。

本阶段交付：

- 记录睡眠、心情、精力、体重和运动；所有字段均可选。
- 创建今日行动，支持健康、学习、工作、生活、关系五个分类。
- 行动支持未完成、部分完成、已完成三种状态。
- 行动可填写“最低行动”，在状态不佳时保留温和的起点。
- 首页只聚焦今天，数据离线保存到 SQLite。

AI 建议、历史日历、提醒、目标关联和云同步不属于本阶段。首页的“今日陪伴”是固定产品文案，不冒充 AI 输出。

## 2. 模块边界

移动端按 Feature-first 与分层架构组织：

```text
presentation -> application -> domain
data ------------------------> domain
```

- `daily`：每日身心状态、日期语义及今日首页组合。
- `action`：每日行动、最低行动、分类和完成状态。
- 页面只调用应用服务和 Riverpod Provider，不直接执行 Drift 查询。
- Phase 1 不调用服务端，保存成功以本地事务完成为准。

## 3. 数据模型

SQLite schema 从 v1 升级到 v2，迁移只新增表，不删除或重建已有数据。

### daily_records

- `id`：客户端 UUID。
- `local_date + timezone`：联合唯一，表达用户所在时区的一天。
- `sleep_minutes`：整数分钟，避免浮点小时误差。
- `weight_grams`：整数克，避免浮点体重误差。
- `mood / energy`：1 至 5 的有限等级。
- `exercise_minutes`：整数分钟。
- `created_at / updated_at / version / deleted_at`：为后续同步预留。

### daily_actions

- `id`：客户端 UUID。
- `local_date`：行动所属本地日期。
- `goal_id`：可空，Stage 2 接入 90 天目标。
- `title / minimum_action / category / status / position`：行动内容与排序。
- `created_at / updated_at / version / deleted_at`：版本递增，删除采用软删除。

## 4. 关键规则

- 睡眠和运动范围为 0 至 1440 分钟。
- 体重以克保存，输入范围为 1 至 1000 千克。
- 行动标题长度为 1 至 80 个字符，最低行动不超过 120 个字符。
- 同一天重复保存状态时更新原记录并递增版本，不创建重复记录。
- 行动状态变更和软删除使用单条原子 SQL，同时递增版本。
- UI 用文字、图标和颜色共同表达状态，避免只依赖颜色。

## 5. 异常与隐私

- 输入错误展示可理解的中文提示；存储异常展示可重试提示。
- 日志不记录睡眠、体重、行动标题等个人内容。
- 当前数据库保护策略遵循 ADR-0003，不宣称 SQLite 已加密。

## 6. 测试与验收

- 日期值对象解析与非法日期测试。
- Daily 和 Action 应用服务校验测试。
- Drift 持久化、状态更新、版本递增与软删除测试。
- schema v1 到 v2 的非破坏性迁移测试。
- 今日首页空状态 Widget 测试。
- `dart format`、`flutter analyze`、`flutter test`、Android Debug APK 构建。
- vivo X100s 真机验证记录、添加行动和三态切换。
