# LifeOS

> 你要怎样度过这一生？

LifeOS 是一个离线优先的个人 AI 成长管理系统。它不监督用户成为更优秀的人，而是陪伴用户成为自己想成为的人。

## 当前阶段

项目已进入 **Stage 3：AI Companion MVP**。移动端已提供 Daily 本地每日闭环、Vision 人生愿景、90 天 Goal、支持 Markdown 和私有图片附件的 Diary、可安全配置 OpenAI、Gemini、Claude、DeepSeek 的统一 AI Service 基础层，以及采用显式数据授权的 AI 当日复盘。Friend、多轮对话和历史趋势分析将按模块继续实现。

## 技术基线

- Mobile：Flutter 3.44.8、Dart 3.12、Android first
- Server：Spring Boot 3.5.16、Java 17、Maven
- Local data：SQLite / Drift
- Cloud data：MySQL 8.4 / Flyway
- Architecture：Offline-first、Feature-first、模块化单体、AI Provider Adapter

详细设计见 [技术架构文档](docs/LifeOS%20技术架构设计文档%20Architecture.md)、[ADR](docs/adr/README.md) 与 [开发环境配置](docs/开发环境配置.md)。

## 目录

```text
LifeOS/
├─ mobile/       # Flutter Android 应用
├─ server/       # Spring Boot API
├─ docs/         # PRD、架构与 ADR
├─ .github/      # CI 配置
└─ compose.yaml  # 本地 MySQL
```

## 本地开发

### Mobile

前置条件：Flutter 3.44.8 stable、Android SDK、接受 Android licenses。

```shell
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

### Server

快速测试使用 H2 的 MySQL 兼容模式，不需要启动本地 MySQL：

```shell
cd server
./mvnw verify
```

本地连接 MySQL：

```shell
docker compose --env-file .env up -d mysql
cd server
./mvnw spring-boot:run
```

Windows PowerShell 中可使用 `mvnw.cmd`。

## 配置与安全

1. 将 `.env.example` 复制为 `.env`，只填写本地开发值。
2. 不要提交 `.env`、API Key、Token、真实日记或本地数据库。
3. Phase 1 的 AI Key 必须进入 Android Keystore 封装的安全存储。
4. 当前 MVP 不自动备份日记数据库和图片，具体原因见 ADR-0003。

## Git

默认分支为 `main`，远程仓库为 GitHub `Adgaiz/LifeOS`。提交信息遵循 Conventional Commits。
