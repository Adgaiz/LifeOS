# Security Batch 1：用户控制的加密备份与恢复

- 状态：Implemented，等待 vivo X100s 真机恢复演练
- 对应决策：[ADR-0004](../adr/0004-encrypted-database-and-user-controlled-backup.md)
- 平台：Android

## 目标与边界

本批次为免登录、离线优先的 LifeOS 提供用户主动发起的可移植备份。备份包含一致性 SQLite 快照和数据库仍在引用的 Diary 原图、缩略图，不包含 AI Provider API Key、数据库设备密钥、Secure Store、日志、缓存、pending 图片或孤儿文件。

数据库日常存储加密和明文数据库迁移属于 Security Batch 2，本批次不改变当前 SQLite 引擎。

## `.lifeos-backup` 格式 v1

文件由明文最小头和认证加密数据块组成：

1. 8 字节魔数 `LIFEOSB1`。
2. 4 字节大端无符号文件头长度。
3. UTF-8 JSON 文件头，只包含格式版本、Argon2id 参数、salt、AES-GCM 算法名、数据块大小/数量和加密前负载长度。
4. 逐块存放：4 字节明文长度、12 字节随机 nonce、等长密文、16 字节 GCM tag。

口令使用 Argon2id 派生 256-bit 密钥，当前生产参数为 19 MiB、2 次迭代、单并行度。每个备份使用新的 16 字节随机 salt，每个数据块使用唯一随机 nonce。AES-256-GCM 的 AAD 绑定文件头 SHA-256、数据块序号和明文长度，因此乱序、删减、追加与修改都会导致验证失败。

解密器限制 KDF 参数、文件头长度、数据块大小/数量和总负载长度，防止恶意文件诱发无上限内存或 CPU 消耗。备份口令不会持久化。

## 加密负载

加密前负载是 ZIP：

```text
manifest.json
database/lifeos.sqlite
files/diary/attachments/<受控文件名>
```

`manifest.json` 本身位于加密区域，记录格式版本、创建时间、数据库 Schema、实体数量以及每个负载文件的路径、大小和 SHA-256。数据库通过 SQLite `VACUUM INTO` 创建一致性快照。备份前会校验 Diary 原图与数据库中已有的 SHA-256；任何活跃引用文件缺失时整次备份失败。

ZIP 解包不使用会忽略异常的快捷方法。恢复代码逐项拒绝绝对路径、`..`、反斜杠、重复条目、符号链接、未知目录、超量条目和异常大小，并对清单中的每个文件重新计算大小与 SHA-256。

## 恢复状态流

```text
用户选文件并输入口令
  → App 私有临时区解密
  → 校验 AEAD、清单、附件和 SQLite quick_check
  → 在临时数据库内执行受支持的 Drift Schema 迁移
  → 用户二次确认整体替换
  → 同文件系统准备数据库和附件 staging
  → 关闭当前数据库
  → 当前文件改名为 rollback
  → staging 原子改名为正式文件
  → 重新 quick_check
  → 成功后删除 rollback，重建 Riverpod 数据库依赖
```

验证阶段不关闭、移动或修改当前数据库。正式切换中任一步失败都会恢复数据库、WAL/SHM/journal 边车文件和附件 rollback；应用不会创建空数据库冒充恢复成功。

恢复是整体替换，不执行自动合并。API Key 不在备份中，因此恢复后保留当前安全存储状态，跨设备时需要用户重新配置。

## Android 文件交互

导出使用 Android `ACTION_CREATE_DOCUMENT`，导入使用 `ACTION_OPEN_DOCUMENT`。原生层只允许将 App 私有缓存中的已验证备份写到用户选择的 URI；导入内容先复制到私有缓存，Dart 完成验证后立即清理。应用不申请广泛存储权限，也不自动上传云端。

## 自动化验证

- 多数据块加密/解密往返。
- 错误口令不留下解密明文。
- 单字节篡改、截断和尾部追加均失败。
- 拒绝 ZIP 路径逃逸，且当前数据库哨兵记录保持不变。
- 只打包数据库引用的附件，排除孤儿文件。
- 备份后修改本机数据，再恢复可回到备份快照；数据库和附件共同替换。
- UI 展示 API Key 排除、口令不可找回和替换确认边界。

## 真机验收

1. 创建包含日记图片的备份并保存到用户选择的目录。
2. 使用错误口令恢复，确认当前数据不变。
3. 修改一条记录后使用正确口令恢复，确认记录和图片回到备份状态。
4. 卸载并重装 App 后恢复，确认业务数据完整且 AI Provider 需要重新配置。
5. 验证大图片备份期间内存、耗时和界面响应；据 vivo X100s 实测结果校准 Argon2id 参数。
