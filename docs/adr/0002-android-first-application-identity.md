# ADR-0002：Android 首发与应用标识

- 状态：Accepted
- 日期：2026-07-29
- 决策者：LifeOS 项目

## 背景

LifeOS 初期为个人使用，首个实际设备是 vivo X100s。同步维护 Android 与 iOS 会扩大构建、签名、权限和真机测试范围，不利于尽快完成每日使用闭环。

Android `applicationId` 一旦发布后不宜修改，后端 Java 基础包也应保持稳定。

## 决策

1. MVP 仅支持 Android，不建立 iOS 构建和发布流水线。
2. Android `applicationId` 使用 `com.adgaiz.lifeos`。
3. Spring Boot 基础包使用 `com.adgaiz.lifeos`。
4. Flutter 工程名使用 `lifeos`，产品展示名使用 `LifeOS`。
5. vivo X100s 是首个真机验收设备，同时保留至少一个标准 Android 模拟器测试。
6. 业务层保持跨平台 Dart 设计，避免无必要的 Android 专属耦合，为未来 iOS 版本保留可能性。

## 结果

- 首期发布与测试范围更小。
- 通知、后台任务、图片权限和安全存储必须在 vivo 系统上单独验证。
- 若未来需要变更 `applicationId`，必须在首次公开发布前通过新 ADR 决定。

## 验证方式

- CI 执行 Flutter analyze、test 和 Android debug 构建。
- 真机检查启动、数据库迁移、图片选择、安全存储、通知权限和节电限制。
