# LifeOS Mobile

LifeOS 的 Flutter Android 客户端。当前仅包含 Stage 0 工程基线：启动主题、路由、Riverpod、统一日志入口、Drift schema v1 与 Android Keystore 安全存储端口。

## 验证

```shell
flutter pub get
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

不要手工修改 `*.g.dart`。修改 Drift 表定义后必须重新运行代码生成并提交生成结果。
