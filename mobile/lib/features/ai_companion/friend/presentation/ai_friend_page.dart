import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';
import 'package:lifeos/features/ai_companion/friend/application/ai_friend_providers.dart';
import 'package:lifeos/features/ai_companion/friend/domain/ai_friend.dart';

final class AiFriendPage extends ConsumerStatefulWidget {
  const AiFriendPage({super.key});

  @override
  ConsumerState<AiFriendPage> createState() => _AiFriendPageState();
}

final class _AiFriendPageState extends ConsumerState<AiFriendPage> {
  final _messageController = TextEditingController();
  AiFriendExchange? _exchange;
  bool _loading = true;
  bool _sending = false;
  bool _showComposer = true;
  bool _saveLocally = true;
  bool _currentIsPersisted = false;

  @override
  void initState() {
    super.initState();
    _loadLatest();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    setState(() => _loading = true);
    try {
      final exchange = await ref.read(aiFriendServiceProvider).loadLatest();
      if (!mounted) return;
      setState(() {
        _exchange = exchange;
        _showComposer = exchange == null;
        _currentIsPersisted = exchange != null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('陪伴记录暂时无法读取');
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    final saveLocally = _saveLocally;
    setState(() => _sending = true);
    try {
      final exchange = await ref
          .read(aiFriendServiceProvider)
          .respond(_messageController.text, saveLocally: saveLocally);
      if (!mounted) return;
      setState(() {
        _exchange = exchange;
        _currentIsPersisted = saveLocally;
        _showComposer = false;
      });
    } on AiFriendValidationException catch (error) {
      if (mounted) _showMessage(error.message);
    } on AiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('AI 暂时无法回应，请稍后重试');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startNewExchange() {
    setState(() {
      _messageController.clear();
      _showComposer = true;
    });
  }

  Future<void> _deleteCurrent() async {
    final exchange = _exchange;
    if (exchange == null || !_currentIsPersisted || _sending) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这次陪伴记录？'),
        content: const Text('你说的话和 AI 回应都会从本机记录中删除。'),
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
    try {
      await ref.read(aiFriendServiceProvider).delete(exchange.id);
      if (!mounted) return;
      setState(() {
        _exchange = null;
        _currentIsPersisted = false;
        _messageController.clear();
        _showComposer = true;
      });
      _showMessage('陪伴记录已从本机删除');
    } catch (_) {
      if (mounted) _showMessage('记录删除失败，请稍后重试');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Friend')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  LifeOsSpacing.lg,
                  LifeOsSpacing.md,
                  LifeOsSpacing.lg,
                  LifeOsSpacing.xxl,
                ),
                children: [
                  if (_showComposer)
                    _FriendComposer(
                      controller: _messageController,
                      sending: _sending,
                      saveLocally: _saveLocally,
                      onSaveLocallyChanged: (value) {
                        setState(() => _saveLocally = value);
                      },
                      onSend: _send,
                    )
                  else if (_exchange != null)
                    _FriendResult(
                      exchange: _exchange!,
                      isPersisted: _currentIsPersisted,
                      onStartNew: _startNewExchange,
                      onDelete: _deleteCurrent,
                    ),
                ],
              ),
      ),
    );
  }
}

final class _FriendComposer extends StatelessWidget {
  const _FriendComposer({
    required this.controller,
    required this.sending,
    required this.saveLocally,
    required this.onSaveLocallyChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool saveLocally;
  final ValueChanged<bool> onSaveLocallyChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '此刻，想说点什么？',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: LifeOsSpacing.xs),
        Text(
          '不用组织得很完整，从真实的一句话开始就好。',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: LifeOsSpacing.xl),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(LifeOsRadii.card),
          ),
          child: const Padding(
            padding: EdgeInsets.all(LifeOsSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined),
                SizedBox(width: LifeOsSpacing.md),
                Expanded(
                  child: Text(
                    '只发送你在这里主动输入的文字。不会自动读取日记、状态、任务、'
                    '历史复盘或过去的对话。AI 不是人类，也不能替代专业支持。',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: LifeOsSpacing.xl),
        TextField(
          controller: controller,
          enabled: !sending,
          minLines: 5,
          maxLines: 9,
          maxLength: aiFriendMaximumMessageLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: '我想说',
            hintText: '例如：今天有点累，我不知道该不该继续硬撑……',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: LifeOsSpacing.md),
        Card(
          child: SwitchListTile(
            value: saveLocally,
            onChanged: sending ? null : onSaveLocallyChanged,
            title: const Text('保存这次交流到本机'),
            subtitle: const Text('关闭后，本次回应只在当前页面显示'),
            secondary: const Icon(Icons.phonelink_lock_outlined),
          ),
        ),
        const SizedBox(height: LifeOsSpacing.xl),
        FilledButton.icon(
          onPressed: sending ? null : onSend,
          icon: sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(sending ? '正在回应…' : '发送并听听回应'),
        ),
        const SizedBox(height: LifeOsSpacing.md),
        Text(
          '如果你正处于紧急危险中，请优先联系现实中的可信任的人或当地紧急服务。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

final class _FriendResult extends StatelessWidget {
  const _FriendResult({
    required this.exchange,
    required this.isPersisted,
    required this.onStartNew,
    required this.onDelete,
  });

  final AiFriendExchange exchange;
  final bool isPersisted;
  final VoidCallback onStartNew;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('你刚才说', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: LifeOsSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(LifeOsSpacing.lg),
            child: SelectableText(exchange.userMessage),
          ),
        ),
        const SizedBox(height: LifeOsSpacing.lg),
        Row(
          children: [
            Icon(
              exchange.isLocalSafetyResponse
                  ? Icons.health_and_safety_outlined
                  : Icons.favorite_border_rounded,
              color: exchange.isLocalSafetyResponse
                  ? colors.error
                  : colors.primary,
            ),
            const SizedBox(width: LifeOsSpacing.sm),
            Expanded(
              child: Text(
                exchange.isLocalSafetyResponse ? '安全回应' : 'AI Friend 回应',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: LifeOsSpacing.sm),
        Card(
          color: exchange.isLocalSafetyResponse
              ? colors.errorContainer.withValues(alpha: 0.5)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(LifeOsSpacing.lg),
            child: MarkdownBody(
              data: exchange.assistantMessage,
              selectable: true,
            ),
          ),
        ),
        const SizedBox(height: LifeOsSpacing.sm),
        Text(
          exchange.isLocalSafetyResponse
              ? '这条安全回应在本机生成，没有把原文发送给 AI Provider。'
              : '${exchange.provider?.displayName} / ${exchange.model}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: LifeOsSpacing.xl),
        FilledButton.tonalIcon(
          onPressed: onStartNew,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('再聊一次此刻'),
        ),
        if (isPersisted) ...[
          const SizedBox(height: LifeOsSpacing.sm),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('删除本机记录'),
          ),
        ] else ...[
          const SizedBox(height: LifeOsSpacing.md),
          Text(
            '本次交流未保存，离开页面后将无法再次查看。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
