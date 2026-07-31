# Stage 2：Vision 人生愿景模块设计

## 1. 目标

Vision 回答“我想成为怎样的人？”。它不是目标清单，也不用于监督用户，而是保存用户愿意长期靠近的生活方向，为后续 90 天 Goal 提供上层语境。

本模块交付：

- 创建和编辑多个长期愿景。
- 查看进行中的愿景。
- 归档、恢复和软删除愿景。
- 在“今天 / 愿景”底部导航间切换。
- 所有数据离线保存在 SQLite，Phase 1 不依赖服务端或登录。

## 2. 模块边界

```text
presentation -> application -> domain
data ------------------------> domain
```

- 页面只通过 `VisionService` 和 Riverpod Provider 操作愿景。
- `VisionRepository` 是领域端口，Drift 是 Phase 1 的本地适配器。
- Vision 内容为纯文本；Markdown 属于 Diary 模块，不在此阶段混用。
- Goal 关联在下一个模块实现，Vision 表不提前包含目标细节。

## 3. 数据模型

SQLite schema 从 v2 升级到 v3，只新增 `visions` 表：

- `id`：客户端 UUID。
- `title`：1 至 80 个字符。
- `content`：1 至 5000 个字符。
- `status`：`active` 或 `archived`。
- `created_at / updated_at`：UTC 时间点。
- `version`：每次编辑、归档、恢复和删除时递增。
- `deleted_at`：软删除时间；非空记录不出现在正常查询中。

从 schema v1 或 v2 升级时均使用增量迁移，不重建已有 Daily 数据库。

## 4. 交互原则

- 空状态使用“给未来一个方向”，避免要求用户一次写出完整人生答案。
- 编辑器使用独立全屏页面，为长文本提供足够空间。
- 离开未保存编辑内容前必须二次确认。
- 归档可随时恢复；删除必须确认。
- 卡片最多预览六行，避免愿景列表信息密度过高。

## 5. 异常与隐私

- 输入校验在 UI 和应用服务两层执行。
- 数据库异常展示通用可重试提示，不暴露 SQL 或内部堆栈。
- 日志不记录愿景标题和正文。
- 本地数据保护继续遵循 ADR-0003，不宣称 SQLite 已加密。

## 6. 测试与验收

- 应用服务创建、规范化、更新和非法输入测试。
- Drift 保存、归档、版本递增和软删除测试。
- schema v1 → v3、v2 → v3 增量迁移测试。
- 空状态创建首个愿景 Widget 测试。
- `dart format`、`flutter analyze`、`flutter test` 和 Android Debug APK 构建。
- vivo X100s 真机验证创建、编辑、归档、恢复、删除和重启后持久化。
