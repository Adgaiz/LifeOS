# ADR-0004：采用加密 Drift 数据库与用户控制的加密备份

- 状态：Accepted
- 日期：2026-08-06
- 决策者：LifeOS 项目
- 部分替代：[ADR-0003：MVP 本地数据、图片与备份保护](0003-local-data-image-and-backup-protection.md) 的数据库不加密结论及未落地的备份设计
- 复审触发：引入账户/云同步、支持 iOS、加密引擎停止维护、Android 密钥模型变化或公开发布

## 背景

LifeOS 当前是 Android 单用户、免登录、离线优先应用。数据库 Schema 9 已保存 Daily、Action、Vision、Goal、Diary、AI 复盘、AI Friend、Timeline 和 AI 周期报告。即将开发的 AI Friend 2.0 会增加连续聊天和用户确认的长期记忆，原始对话属于高敏感数据。

ADR-0003 在工程基线阶段决定暂不引入数据库加密，以降低早期原生依赖和迁移风险，同时要求在威胁模型变化时复审。连续 AI 对话使数据库中敏感长文本的数量和集中度明显上升，已经满足复审条件。

当前技术基线：

- Flutter 3.44.8 / Dart 3.12.2。
- Drift 2.34.2、`drift_flutter` 0.3.1、`sqlite3` 3.5.0。
- 生产数据库通过 `driftDatabase(name: 'lifeos')` 打开标准 SQLite。
- API Key 通过 `flutter_secure_storage` 保存，由 Android Keystore 提供保护。
- Android Manifest 已设置 `android:allowBackup="false"` 和 `android:fullBackupContent="false"`。
- 数据库、Diary 图片和头像均位于 App 私有目录，但当前数据库和图片文件本身未加密。

## 驱动因素

本决策需要同时满足：

1. 降低数据库文件被离线复制后泄露日记、健康数据和 AI 对话的风险。
2. 不把加密密钥写入源码、SQLite、普通配置、日志、备份或 Git。
3. 已有真实数据从明文 SQLite 迁移时不能静默丢失。
4. 禁止敏感数据无提示进入 Google、vivo 或其他系统备份通道。
5. 禁用自动备份后，仍提供用户可控、可验证、可跨设备恢复的加密备份。
6. 继续使用 Drift Repository 和既有 Schema 迁移，不让加密实现侵入业务模块。
7. 在 vivo X100s 上保持可接受的启动、查询、图片和迁移性能。

## 威胁模型

### 本决策覆盖

- 攻击者离线获得数据库、WAL、SHM 或系统备份副本。
- 未授权的普通文件复制、调试产物泄露和云备份误配置。
- 设备损坏、应用升级失败或迁移中断造成的数据丢失。
- 用户主动备份文件被第三方获取或篡改。
- 错误密钥、损坏备份或不兼容 Schema 覆盖当前可用数据。

### 本决策不覆盖

- 设备已解锁且攻击者能够正常操作 LifeOS。
- App 进程、系统输入法、Android 系统或 AI Provider 已被攻破。
- 已 root 的设备在应用运行时借助应用进程使用 Keystore 密钥。
- 屏幕截图、通知预览、用户主动复制或 Provider 侧数据处理。
- 用户选择过弱的备份口令。

数据库加密是纵深防御，不等于设备、附件、网络和 Provider 全链路都已安全。

## 方案比较

| 方案 | 优点 | 缺点 | 结论 |
| --- | --- | --- | --- |
| 继续标准 SQLite，仅依赖沙箱 | 无迁移和原生加密依赖 | 离线复制数据库即可读取全部正文；不适合新增连续 AI 对话 | 拒绝 |
| 对敏感字段逐列加密 | 可选择保护部分字段 | 查询、索引、迁移和密钥轮换复杂；表结构、关系和大量元数据仍泄露 | 拒绝 |
| `encrypted_drift` / `sqflite_sqlcipher` | 使用 SQLCipher，已有平台插件 | 增加平台插件和 Git 依赖；偏离当前 FFI Drift 路线；迁移和 Release 配置更复杂 | 暂不采用 |
| `sqlcipher_flutter_libs` + 自定义 NativeDatabase | 旧版 Drift 常见方案 | 官方包已标记 EOL；Drift 2.32+ 不再推荐该接入方式 | 拒绝 |
| `NativeDatabase` + SQLite3MultipleCiphers | Drift 当前推荐；保持 FFI 和 Drift API；Android/桌面路径一致；MIT 许可 | 需要 build hook、异步密钥启动、明文迁移和真机验证 | 采用 |

## 决策

### 1. 数据库加密引擎

1. 生产数据库改为 Drift `NativeDatabase.createInBackground`，通过 `sqlite3` build hook 打包 SQLite3MultipleCiphers：

   ```yaml
   hooks:
     user_defines:
       sqlite3:
         source: sqlite3mc
   ```

2. 使用 SQLite3MultipleCiphers 推荐的 ChaCha20-Poly1305 加密方案；实现时显式固定 cipher 与兼容参数，不能依赖未来版本可能变化的隐式默认值。
3. 不新增对已 EOL 的 `sqlcipher_flutter_libs` 的直接依赖，也不把 `encrypted_drift` Git 依赖作为首选生产路径。
4. 加密引擎、`sqlite3` 和 Drift 版本必须进入锁文件；升级任一项前执行密文兼容和回滚测试。
5. Android 进程中只能有一个 SQLite 实现访问 LifeOS 数据库，避免不同 SQLite native library 同时打开同一文件。

### 2. 数据库密钥

1. 第一次启用加密时由安全随机数生成器创建独立的 256-bit 数据库密钥。
2. 密钥以专用命名空间保存在 Android Keystore 封装的 Secure Store 中，不与 AI API Key、备份口令或用户名称共用键名。
3. 数据库文件、SharedPreferences、资源文件、环境变量、日志、崩溃报告、手动备份和 Git 中不得出现数据库密钥。
4. 数据库打开前异步读取密钥，并在第一条 SQL 执行前设置 cipher 和 key。生产代码不得先尝试明文打开再降级到加密。
5. 首期不要求每次打开数据库都进行生物识别，避免破坏后台恢复和每日使用体验。未来如增加“应用锁”，另立 ADR。
6. 不进行没有风险事件的周期性密钥轮换。确需轮换时使用经过验证的 rekey 流程，并先生成可恢复备份。

### 3. 启动与失败策略

1. 数据库初始化改为显式异步 Bootstrap；业务 Repository 只能在密钥和加密执行器准备完成后创建。
2. Debug 和 Release 都必须在运行时验证 `PRAGMA cipher` 可用，不能只依赖会在 Release 中移除的 `assert`。
3. 设置 key 后执行最小验证，包括 Schema 版本读取和 `PRAGMA quick_check`；验证通过后才向业务层暴露数据库。
4. 密钥缺失、错误或 Keystore 不可用时必须 fail closed：停止打开数据库并展示可恢复错误，不得自动新建空库覆盖旧文件。
5. 只有用户完成二次确认后才允许清除无法解密的数据并重新开始；该操作必须说明不可恢复。
6. 测试继续允许显式注入内存数据库，但生产入口不得提供明文 fallback。

### 4. 已有明文数据库迁移

明文到密文采用“复制、验证、原子替换”，禁止直接在唯一原文件上原地修改：

1. 在迁移前确认数据库关闭，并获得进程内独占迁移锁。
2. 用户必须先完成一次可恢复的加密手动备份；没有已验证备份时不执行正式迁移。
3. 在同一 App 私有文件系统内创建加密临时数据库。
4. 按 Drift 官方 SQLite3MultipleCiphers 路线复制明文数据库并对临时副本执行 rekey。
5. 使用新密钥重新打开临时数据库，执行 `quick_check`、Schema 版本、关键表计数和代表性校验。
6. 校验全部通过后，通过同文件系统重命名完成原子切换。
7. 原明文库仅作为迁移回滚副本短暂保留；新密文库成功打开后立即删除，不进入普通备份。
8. 迁移状态使用不含正文和密钥的状态标记记录。App 被杀死后能够识别并恢复“未开始、临时文件完成、等待切换、切换完成”状态。
9. WAL 和 SHM 在复制前完成 checkpoint 并关闭，不能遗漏尚未合并的数据。
10. 存储格式迁移不替代 Drift Schema 迁移；两类迁移分阶段执行并分别测试。

任何失败都保留最后一个已验证可打开的数据副本，不静默删除、不自动重置。

### 5. SQLite 安全设置

每次生产数据库打开后统一设置并验证：

- `PRAGMA foreign_keys = ON`。
- `PRAGMA secure_delete = ON`，降低已删除正文留在可复用页面中的风险。
- 明确的 journal 和同步策略，实施时以崩溃恢复测试结果为准，不能为了性能关闭必要持久性保证。
- AI Friend 30 天物理清理等大批删除后执行受控 checkpoint；是否 VACUUM 由文件增长和真机耗时决定，不能阻塞正常聊天。

### 6. Android 系统备份

1. 当前阶段继续禁止 Android Auto Backup 和系统设备迁移自动复制 LifeOS 数据。
2. 保留 `android:allowBackup="false"`。
3. 为 Android 11 及以下增加明确的 `android:fullBackupContent` 排除规则。
4. 为 Android 12 及以上增加 `android:dataExtractionRules`，同时排除 Cloud Backup 和 Device-to-Device Transfer 中的数据库、文件、SharedPreferences、Secure Store 与外部文件域。
5. Release 验证不能只检查 Manifest 文本，必须检查 merged manifest 和实际 APK/AAB 中的规则资源。
6. 数据库密钥、API Key 和 Secure Store 在任何情况下都不进入 Android 系统备份。

即使 Android 官方备份服务通常提供传输和静态加密，LifeOS 在账户与密钥恢复尚未设计前仍选择显式排除，以避免出现“恢复了密文数据库但没有设备密钥”或敏感数据进入用户未知云端的问题。

### 7. 用户控制的手动加密备份

1. 备份只能由用户主动发起，不后台定时生成，不自动上传任何云盘。
2. 使用 Storage Access Framework 让用户选择目标位置；目标文件离开 App 后由用户负责保管。
3. 文件扩展名使用 `.lifeos-backup`，格式必须版本化。
4. 备份明文负载至少包含：
   - 一致性数据库快照或等价的完整逻辑数据；
   - Diary 原图、缩略图和校验值；
   - AI Friend 自定义头像；
   - 用户确认的 AI Friend 记忆与本地配置；
   - Schema 版本、备份格式版本、实体计数和附件 SHA-256 清单。
5. 备份明确排除：
   - 所有 AI Provider API Key；
   - 数据库设备密钥和 Keystore 材料；
   - 缓存、日志、临时文件、失败迁移副本和构建信息；
   - 不再被数据库引用的孤儿附件。
6. 整个负载（包括文件名、记录日期、实体计数和附件清单）必须经过认证加密；外部明文头只允许包含格式魔数、版本和解密所必需的 KDF/算法参数。
7. 使用用户输入的备份口令通过 Argon2id 派生独立备份密钥，再使用 AES-256-GCM 或经安全评审的等价 AEAD 加密。
8. 每个备份使用新的随机 salt 和 nonce；KDF 参数随文件保存，并在 vivo X100s 上校准到可接受等待时间和足够内存成本。
9. 不使用传统 ZipCrypto、固定口令、数据库设备密钥复用或自行设计的密码算法。
10. 大型备份必须采用经过维护的流式/分块认证加密实现，不能把所有图片一次性载入内存；每块 nonce 唯一并绑定格式版本和顺序。
11. 创建过程中产生的临时明文只能存在于 App 私有缓存，尽量采用边读边加密；无论成功或失败都必须清理。
12. 完成后立即用同一口令进行结构、认证标签和清单校验，只有验证通过才报告“备份成功”。

备份口令不保存到设备或备份文件。用户忘记口令时，项目方无法恢复备份。

### 8. 恢复策略

1. 恢复是显式的“验证后整体替换”，首版不提供自动合并。
2. 用户选择文件并输入口令后，先在 App 私有临时目录解密和验证，不触碰当前数据库。
3. 验证内容包括 AEAD 认证、格式版本、清单哈希、附件大小、数据库 `quick_check` 和可支持的 Schema 版本。
4. 旧 Schema 在临时数据库内按顺序迁移到当前版本，再次验证后才能切换。
5. 正式替换前再次向用户说明当前本机数据将被替换，并为当前数据创建已验证的回滚副本。
6. 数据库和附件都准备完成后才执行切换；任一步骤失败都继续使用原数据。
7. 恢复完成后使用当前设备新生成或已有的数据库密钥重新加密，不把备份口令作为日常数据库密钥。
8. API Key 不恢复，用户需要重新配置 Provider。
9. 成功启动并完成校验后清理临时文件和回滚副本。

### 9. Diary 图片与其他私有文件

本 ADR 采用整库加密，但不宣称 Diary 图片和自定义头像已获得独立的静态文件加密：

- 它们继续只保存在 App 私有目录。
- 它们被 Android 自动备份和 D2D 规则排除。
- 它们进入手动备份时包含在整体认证加密负载中。
- EXIF 清理、随机文件名、路径边界、孤儿清理和物理删除继续遵循 ADR-0003 与 Diary 模块设计。

如果威胁模型要求防御 App 私有文件被离线复制后直接查看图片，必须新增文件级加密 ADR。产品文案只能声明“数据库已加密”，不能声明“所有本地数据均已加密”。

## 实施顺序与准入门槛

### Security Batch 1：备份与恢复

- 定义 `.lifeos-backup` 格式和独立测试向量。
- 实现用户主动加密备份、错误口令处理和临时恢复验证。
- 在测试数据上完成备份、卸载、重装、恢复演练。
- UI 明确提示备份口令不可找回，API Key 不包含在备份中。

### Security Batch 2：数据库加密与迁移

- 增加 sqlite3 build hook、专用 DatabaseKeyStore 和异步数据库 Bootstrap。
- 实现明文到密文的可中断迁移和回滚。
- 增加 Android 双版本备份排除规则。
- 在 vivo X100s 上验证 Release APK、冷启动、迁移、查询、30 天删除和升级兼容。

### Security Batch 3：恢复与故障演练

- 错误密钥、密钥缺失、磁盘满、进程中断、临时文件损坏、备份损坏和旧 Schema 恢复测试。
- 验证 Release 包确实包含 SQLite3MultipleCiphers 且 `PRAGMA cipher` 非空。
- 验证数据库二进制中无法检索预置的日记和 AI 聊天哨兵文本。
- 形成一次有记录的恢复演练结果。

AI Friend 2.0 Batch A 在 Security Batch 1 和 2 真机验证通过后开始；Security Batch 3 必须在该模块交付前完成。

## 验证标准

### 自动化

- 正确密钥可以打开数据库，错误或缺失密钥不能打开且不会创建空库。
- 生产入口缺少 cipher 支持时 fail closed。
- 明文迁移后 Schema、实体计数、关键关系、附件引用和 `quick_check` 一致。
- 在迁移每个状态注入中断后都能恢复到最后一个有效副本。
- 已删除敏感正文不会通过正常 SQLite 查询或明文字符串扫描恢复。
- 备份错误口令、单字节篡改、截断、乱序和未知版本均在替换当前数据前失败。
- 备份不包含 API Key、数据库密钥、日志、缓存和孤儿附件。
- 恢复旧 Schema 后通过全部数据库迁移测试。
- Android merged manifest 和规则文件排除所有敏感域。

### 真机

- vivo X100s Release 构建首次迁移和后续冷启动成功。
- 加密后的 Daily、Diary、图片、AI、Timeline 和 Analytics 回归正常。
- 加密前后常用查询性能回归保持在可接受范围；冷启动新增等待目标不超过 500 ms，超出时必须分析而不是静默放宽。
- 代表性数据备份、卸载、重装和恢复完整成功。
- 错误备份口令不会破坏当前数据。
- App 卸载后自动备份不会静默恢复数据库、附件或 Secure Store。

## 结果

### 正面影响

- 离线获得数据库文件不再能直接读取日记、健康信息和 AI 对话。
- AI Friend 2.0 可以在明确的数据保护边界下保存 30 天原始聊天和长期记忆。
- 用户在无账户、无云同步阶段仍有可移植、可验证的恢复路径。
- 加密保持在数据库基础设施层，业务 Repository 和模块边界不需要感知 cipher。

### 成本与风险

- App 启动、数据库工厂、迁移和测试复杂度增加。
- Keystore 密钥丢失且没有可用手动备份时，数据库不可恢复。
- 禁用系统自动备份要求用户主动维护备份，仍可能因忘记备份而丢失数据。
- SQLite3MultipleCiphers 是 SQLite 分支，需要持续跟踪兼容、安全和 native 构建变化。
- Diary 图片当前仍是 App 私有目录中的未单独加密文件，保护范围必须如实说明。
- 用户选择弱口令会降低手动备份的抗离线破解能力。

## 被部分替代的结论

ADR-0003 以下内容继续有效：

- 数据库、Diary 图片和头像只保存在 App 私有目录。
- API Key 始终使用 Android Keystore 封装的安全存储。
- 图片使用文件保存，数据库只保存受控相对路径和元数据。
- 敏感正文、图片、Prompt 和凭据禁止进入日志。
- 未经验证的 Android 自动备份继续禁用。

ADR-0003 中“MVP 使用标准 SQLite，不引入数据库加密”的结论由本 ADR 替代；“加密导出与恢复尚待设计”由本 ADR 的用户控制备份策略替代。

## 参考资料

- [Drift：Encryption](https://drift.simonbinder.eu/platforms/encryption/)：推荐新应用使用 `NativeDatabase` 与 SQLite3MultipleCiphers，说明 build hook、运行时验证和明文迁移方式。
- [Android Developers：Android Keystore system](https://developer.android.com/privacy-and-security/keystore)：Keystore 密钥防提取、硬件支持和使用授权边界。
- [Android Developers：Security recommendations for backups](https://developer.android.com/privacy-and-security/risks/backup-best-practices)：敏感数据备份排除、Android 12+ `dataExtractionRules` 与旧版 `fullBackupContent`。
- [SQLite3MultipleCiphers](https://utelle.github.io/SQLite3MultipleCiphers/)：推荐 ChaCha20-Poly1305、配置与兼容说明。
- [SQLite3MultipleCiphers GitHub](https://github.com/utelle/SQLite3MultipleCiphers)：MIT 许可、版本和维护状态。
- [sqlcipher_flutter_libs](https://pub.dev/packages/sqlcipher_flutter_libs)：包已标记 EOL，不作为新实现的直接依赖。
- [cryptography 2.8.1 changelog](https://pub.dev/packages/cryptography/versions/2.8.1/changelog)：Dart/Flutter 可用的 Argon2id 与 AES-GCM 能力；实现前仍需完成依赖维护与性能评审。

以上资料核对日期为 2026-08-06。
