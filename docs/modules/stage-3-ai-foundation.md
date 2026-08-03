# Stage 3：AI Service 基础层

## 模块目标

本模块只建立可替换的 AI 调用基础设施与本机配置能力，不在同一批次实现 Coach、Friend、Analyst 对话。这样可以先验证凭据安全、Provider 切换、异常边界和接口契约，再让后续陪伴场景只依赖统一的 `AiService`。

## 设计决策

### Provider 端口与适配器

- 领域层通过 `AiService.generate(AiRequest)` 发起请求，不引用任何厂商 SDK 或 LifeOS 业务实体。
- OpenAI、Gemini、Claude、DeepSeek 分别拥有独立 Adapter，集中处理各自的鉴权、请求结构和响应解析。
- `AiServiceRouter` 根据本机选中的 Provider 读取配置并路由，后续迁移服务器代理时不需要修改 Coach、Friend、Analyst 的核心逻辑。
- 使用轻量 HTTP 传输抽象，自动化测试以 Fake Client 固定响应，不调用真实收费接口。

### 当前官方接口

| Provider | 接口 | 默认模型（可修改） |
| --- | --- | --- |
| OpenAI | `POST https://api.openai.com/v1/responses` | `gpt-5.6-sol` |
| Gemini | `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent` | `gemini-3.6-flash` |
| Claude | `POST https://api.anthropic.com/v1/messages` | `claude-sonnet-5` |
| DeepSeek | `POST https://api.deepseek.com/chat/completions` | `deepseek-v4-flash` |

模型名不是业务常量，用户可在设置页按厂商最新可用模型调整。DeepSeek 虽提供 OpenAI 兼容格式，仍采用独立 Adapter，避免两个厂商的接口演进互相耦合。

## 凭据与隐私

- API Key、模型名和当前 Provider 通过 `flutter_secure_storage` 保存，由 Android Keystore 提供密钥保护。
- API Key 不进入 SQLite、源码、日志、崩溃信息或 Git；保存后界面仅显示末四位掩码。
- 设置页支持保存、替换、删除和主动连接测试。连接测试会先提示可能产生费用，并且只发送固定的最小测试消息。
- DeepSeek 默认开启思考模式；连接测试会显式关闭思考并预留 64 个输出 Token，避免思考过程耗尽额度后最终 `content` 为空。正式场景可通过统一请求参数明确选择思考模式。
- 本模块不读取 Daily、Goal、Diary 或图片。后续 AI 场景必须在调用前明确展示并获得本次上下文授权；默认不发送全部历史日记。
- OpenAI 请求显式设置 `store: false`。所有 Provider 只使用 HTTPS 固定官方域名，首期不开放自定义 Base URL，避免误配置与请求伪造风险。

## 异常策略

对上层只暴露不含响应正文和敏感输入的类型化错误：

- 配置无效
- 鉴权失败
- 限流或额度不足
- 超时
- 网络不可用
- Provider 暂时不可用
- 响应结构异常
- 输出达到 Token 上限或内容被服务商过滤

AI 调用失败不会影响 Daily、Vision、Goal、Diary 等离线核心能力。

## 验证范围

- 四家 Adapter 的请求序列化与响应解析。
- Provider 路由选择与未配置拦截。
- HTTP 鉴权失败、异常响应的安全映射。
- 安全存储键隔离、Key 掩码和删除。
- 设置页保存、掩码展示和删除流程。
- 测试均使用 Fake，不需要也不会读取真实 API Key。

## 下一步

在此基础层通过真机配置与连接验证后，进入 AI Companion 的首个有限场景。建议先实现“当日复盘”，由用户勾选本次发送的 Daily、Action 和 Diary 摘要，再调用 Coach/Analyst；不默认开放全历史读取。
