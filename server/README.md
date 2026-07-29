# LifeOS Server

LifeOS 的 Spring Boot 3 模块化单体服务端。Stage 0 只包含运行基线，不包含用户或成长管理业务。

当前基线包括：

- Java 17 / Spring Boot 3.5.16
- 统一 API 错误模型
- `X-Request-Id` 请求追踪
- Actuator 健康检查
- MySQL 8.4 与 Flyway
- H2 MySQL 模式快速测试
- Maven Wrapper 与 Spotless

## 验证

```shell
./mvnw spotless:check verify
```

本地运行前请在仓库根目录准备 `.env` 并启动 MySQL，随后运行：

```shell
./mvnw spring-boot:run
```
