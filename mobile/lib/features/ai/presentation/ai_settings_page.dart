import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/ai/application/ai_providers.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

final class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

final class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();
  AiProviderType _provider = AiProviderType.deepSeek;
  AiProviderSummary? _summary;
  bool _loading = true;
  bool _busy = false;
  bool _showApiKey = false;
  int _loadSequence = 0;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final selected = await ref
          .read(aiConfigurationServiceProvider)
          .readSelectedProvider();
      if (!mounted) return;
      _provider = selected;
      await _loadProvider(selected, persistSelection: false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('AI 配置暂时无法读取');
    }
  }

  Future<void> _loadProvider(
    AiProviderType provider, {
    bool persistSelection = true,
  }) async {
    final sequence = ++_loadSequence;
    setState(() {
      _provider = provider;
      _loading = true;
      _summary = null;
      _apiKeyController.clear();
      _showApiKey = false;
    });
    try {
      final service = ref.read(aiConfigurationServiceProvider);
      if (persistSelection) await service.selectProvider(provider);
      final summary = await service.readSummary(provider);
      if (!mounted || sequence != _loadSequence) return;
      setState(() {
        _summary = summary;
        _modelController.text = summary.model;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || sequence != _loadSequence) return;
      setState(() => _loading = false);
      _showMessage('AI 配置暂时无法读取');
    }
  }

  Future<bool> _save({bool showFeedback = true}) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      final summary = await ref
          .read(aiConfigurationServiceProvider)
          .save(
            provider: _provider,
            model: _modelController.text,
            newApiKey: _apiKeyController.text,
          );
      if (!mounted) return false;
      setState(() {
        _summary = summary;
        _apiKeyController.clear();
        _showApiKey = false;
      });
      if (showFeedback) _showMessage('${_provider.displayName} 配置已安全保存');
      return true;
    } on AiException catch (error) {
      if (mounted) _showMessage(error.message);
      return false;
    } catch (_) {
      if (mounted) _showMessage('配置保存失败，请稍后重试');
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testConnection() async {
    final saved = await _save(showFeedback: false);
    if (!saved || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('测试 API 连接？'),
        content: Text(
          '将向 ${_provider.displayName} 发送一条最小测试消息，可能产生少量费用。'
          '不会发送日记、目标或其他 LifeOS 数据。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('开始测试'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(aiServiceProvider)
          .generate(
            AiRequest(
              messages: const [
                AiMessage(role: AiMessageRole.user, text: '仅回复：连接成功'),
              ],
              maxOutputTokens: 64,
              reasoningMode: AiReasoningMode.disabled,
            ),
          );
      if (mounted) _showMessage('${_provider.displayName} 连接成功');
    } on AiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('连接测试失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_summary?.isConfigured != true || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除 ${_provider.displayName} 配置？'),
        content: const Text('本机保存的 API Key 和模型设置将被清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(aiConfigurationServiceProvider).delete(_provider);
      if (!mounted) return;
      await _loadProvider(_provider, persistSelection: false);
      if (mounted) _showMessage('配置已从安全存储中删除');
    } catch (_) {
      if (mounted) _showMessage('配置删除失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AI 服务设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            LifeOsSpacing.lg,
            LifeOsSpacing.md,
            LifeOsSpacing.lg,
            LifeOsSpacing.xxl,
          ),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
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
                        'API Key 仅保存在本机 Android 安全存储中。'
                        'LifeOS 不会把它写入数据库或日志。',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LifeOsSpacing.xl),
            Text('服务提供商', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: LifeOsSpacing.md),
            DropdownButtonFormField<AiProviderType>(
              key: ValueKey(_provider),
              initialValue: _provider,
              decoration: const InputDecoration(labelText: '当前 Provider'),
              items: [
                for (final provider in AiProviderType.values)
                  DropdownMenuItem(
                    value: provider,
                    child: Text(provider.displayName),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (provider) {
                      if (provider != null && provider != _provider) {
                        _loadProvider(provider);
                      }
                    },
            ),
            const SizedBox(height: LifeOsSpacing.lg),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              TextFormField(
                controller: _modelController,
                enabled: !_busy,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  helperText: '可按服务商最新可用模型修改',
                ),
              ),
              const SizedBox(height: LifeOsSpacing.lg),
              TextFormField(
                controller: _apiKeyController,
                enabled: !_busy,
                obscureText: !_showApiKey,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _summary?.isConfigured == true
                      ? '替换 API Key（留空则保留）'
                      : 'API Key',
                  hintText: _provider.keyPlaceholder,
                  helperText: _summary?.isConfigured == true
                      ? '已配置 ${_summary?.maskedApiKey}'
                      : '尚未配置',
                  suffixIcon: IconButton(
                    tooltip: _showApiKey ? '隐藏 API Key' : '显示 API Key',
                    onPressed: () => setState(() => _showApiKey = !_showApiKey),
                    icon: Icon(
                      _showApiKey
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LifeOsSpacing.xl),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('安全保存'),
              ),
              const SizedBox(height: LifeOsSpacing.sm),
              OutlinedButton.icon(
                onPressed: _busy ? null : _testConnection,
                icon: const Icon(Icons.wifi_tethering_rounded),
                label: const Text('保存并测试连接'),
              ),
              if (_summary?.isConfigured == true) ...[
                const SizedBox(height: LifeOsSpacing.sm),
                TextButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('删除本机配置'),
                ),
              ],
            ],
            const SizedBox(height: LifeOsSpacing.xl),
            Text(
              '正式使用 AI 功能时，每次都会明确展示将发送的数据范围；'
              '默认不会读取全部历史日记或图片。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
