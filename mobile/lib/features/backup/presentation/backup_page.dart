import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/database/database_provider.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/backup/application/backup_providers.dart';
import 'package:lifeos/features/backup/domain/backup_exception.dart';
import 'package:lifeos/features/backup/domain/backup_models.dart';

final class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

final class _BackupPageState extends ConsumerState<BackupPage> {
  String? _operation;

  bool get _busy => _operation != null;

  Future<void> _createBackup() async {
    final password = await _requestNewPassword();
    if (password == null || !mounted) return;
    await _waitForDialogTeardown();
    if (!mounted) return;
    setState(() => _operation = '正在创建并验证加密备份…');
    try {
      final summary = await ref
          .read(backupServiceProvider)
          .createBackup(password);
      if (!mounted) return;
      if (summary != null) {
        _showMessage(
          '备份已保存（${_formatBytes(summary.fileSize)}，'
          '${summary.attachmentCount} 张日记图片）',
        );
      }
    } on BackupException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('备份创建失败，当前数据未受影响');
    } finally {
      if (mounted) setState(() => _operation = null);
    }
  }

  Future<void> _restoreBackup() async {
    final password = await _requestRestorePassword();
    if (password == null || !mounted) return;
    await _waitForDialogTeardown();
    if (!mounted) return;
    setState(() => _operation = '正在解密并检查备份…');
    PreparedRestore? prepared;
    try {
      prepared = await ref.read(backupServiceProvider).prepareRestore(password);
      if (prepared == null || !mounted) return;
      setState(() => _operation = null);
      final confirmed = await _confirmRestore(prepared);
      if (confirmed != true) {
        await ref.read(backupServiceProvider).cancelRestore(prepared);
        return;
      }
      await _waitForDialogTeardown();
      if (!mounted) return;
      setState(() => _operation = '正在安全替换本机数据…');
      try {
        await ref.read(backupServiceProvider).confirmRestore(prepared);
      } finally {
        // commitRestore closes the current connection before switching files,
        // including rollback paths. Recreate all dependent repositories.
        ref.invalidate(appDatabaseProvider);
      }
      if (mounted) _showMessage('恢复完成，API Key 未被恢复');
    } on BackupException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('恢复失败，原有数据已保留');
    } finally {
      if (mounted) setState(() => _operation = null);
    }
  }

  Future<String?> _requestNewPassword() async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    String? error;
    var obscure = true;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建加密备份'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('请设置一个只用于此备份的口令。LifeOS 不会保存它，忘记后任何人都无法恢复。'),
                const SizedBox(height: LifeOsSpacing.lg),
                TextField(
                  controller: password,
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '备份口令（至少 10 个字符）',
                    errorText: error,
                    suffixIcon: IconButton(
                      tooltip: obscure ? '显示口令' : '隐藏口令',
                      onPressed: () => setDialogState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: LifeOsSpacing.md),
                TextField(
                  controller: confirmation,
                  obscureText: obscure,
                  decoration: const InputDecoration(labelText: '再次输入口令'),
                ),
                const SizedBox(height: LifeOsSpacing.md),
                Text(
                  '数据库、日记图片会进入加密备份；AI API Key、设备密钥、缓存和日志不会进入。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final validation = validateBackupPassword(password.text);
                if (validation != null || password.text != confirmation.text) {
                  setDialogState(() {
                    error = validation ?? '两次输入的口令不一致';
                  });
                  return;
                }
                Navigator.of(context).pop(password.text);
              },
              child: const Text('选择保存位置'),
            ),
          ],
        ),
      ),
    );
    await _waitForDialogTeardown();
    password.dispose();
    confirmation.dispose();
    return result;
  }

  Future<String?> _requestRestorePassword() async {
    final password = TextEditingController();
    var obscure = true;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('验证加密备份'),
          content: TextField(
            controller: password,
            obscureText: obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '创建备份时使用的口令',
              suffixIcon: IconButton(
                tooltip: obscure ? '显示口令' : '隐藏口令',
                onPressed: () => setDialogState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (password.text.isNotEmpty) {
                  Navigator.of(context).pop(password.text);
                }
              },
              child: const Text('选择备份文件'),
            ),
          ],
        ),
      ),
    );
    await _waitForDialogTeardown();
    password.dispose();
    return result;
  }

  Future<void> _waitForDialogTeardown() async {
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<bool?> _confirmRestore(PreparedRestore prepared) {
    final localTime = prepared.manifest.createdAt.toLocal();
    final recordCount = prepared.manifest.entityCounts.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('用备份替换当前数据？'),
        content: Text(
          '备份时间：${_formatDateTime(localTime)}\n'
          '记录数量：$recordCount\n\n'
          '恢复会整体替换本机数据库和日记图片。LifeOS 已完成口令、文件清单、图片哈希和数据库完整性检查；'
          '切换失败时会自动回滚。API Key 不会被恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('暂不恢复'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认替换'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('数据与备份')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                LifeOsSpacing.lg,
                LifeOsSpacing.md,
                LifeOsSpacing.lg,
                LifeOsSpacing.xxl,
              ),
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(LifeOsRadii.card),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(LifeOsSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined),
                        SizedBox(width: LifeOsSpacing.md),
                        Expanded(
                          child: Text(
                            '备份完全由你主动创建和保管，不会自动上传云端。'
                            '文件离开本机前会使用独立口令加密。',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: LifeOsSpacing.xl),
                _BackupActionCard(
                  icon: Icons.lock_outline_rounded,
                  title: '创建加密备份',
                  description: '保存数据库与日记图片，自动排除 API Key、缓存和日志。',
                  buttonLabel: '创建备份',
                  onPressed: _busy ? null : _createBackup,
                ),
                const SizedBox(height: LifeOsSpacing.lg),
                _BackupActionCard(
                  icon: Icons.settings_backup_restore_rounded,
                  title: '从备份恢复',
                  description: '先在临时区完整验证，再由你确认是否替换当前本机数据。',
                  buttonLabel: '选择并验证备份',
                  onPressed: _busy ? null : _restoreBackup,
                ),
                const SizedBox(height: LifeOsSpacing.lg),
                Text(
                  '请将备份保存在可信位置，并记住口令。卸载 LifeOS 会删除应用私有数据，但不会删除你主动导出的备份文件。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (_operation != null)
              Positioned.fill(
                child: ColoredBox(
                  color: colors.scrim.withValues(alpha: 0.32),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(LifeOsSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: LifeOsSpacing.lg),
                            Text(_operation!),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

final class _BackupActionCard extends StatelessWidget {
  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: LifeOsSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LifeOsSpacing.sm),
            Text(description),
            const SizedBox(height: LifeOsSpacing.lg),
            FilledButton.tonal(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
