import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';
import 'package:lifeos/features/ai_companion/daily_review/application/daily_review_providers.dart';
import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';

final class DailyReviewPage extends ConsumerStatefulWidget {
  const DailyReviewPage({super.key});

  @override
  ConsumerState<DailyReviewPage> createState() => _DailyReviewPageState();
}

final class _DailyReviewPageState extends ConsumerState<DailyReviewPage> {
  DailyReviewPageData? _data;
  AiDailyReview? _review;
  final Set<DailyReviewContextType> _selectedTypes = {};
  bool _loading = true;
  bool _generating = false;
  bool _showComposer = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref
          .read(dailyReviewServiceProvider)
          .load(ref.read(todayProvider), ref.read(currentTimeZoneProvider));
      if (!mounted) return;
      setState(() {
        _data = data;
        _review = data.latestReview;
        _showComposer = data.latestReview == null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('今日复盘数据暂时无法读取');
    }
  }

  Future<void> _generate() async {
    final context = _data?.context;
    if (context == null || _generating) return;
    setState(() => _generating = true);
    try {
      final review = await ref
          .read(dailyReviewServiceProvider)
          .generate(context, DailyReviewSelection(_selectedTypes));
      if (!mounted) return;
      setState(() {
        _review = review;
        _showComposer = false;
      });
    } on DailyReviewException catch (error) {
      if (mounted) _showMessage(error.message);
    } on AiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('AI 复盘生成失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _startNewReview() {
    setState(() {
      _selectedTypes.clear();
      _showComposer = true;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 当日复盘')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
            ? _LoadError(onRetry: _load)
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  LifeOsSpacing.lg,
                  LifeOsSpacing.md,
                  LifeOsSpacing.lg,
                  LifeOsSpacing.xxl,
                ),
                children: [
                  if (_showComposer)
                    _ReviewComposer(
                      contextData: _data!.context,
                      selectedTypes: _selectedTypes,
                      generating: _generating,
                      onChanged: (type, selected) {
                        setState(() {
                          if (selected) {
                            _selectedTypes.add(type);
                          } else {
                            _selectedTypes.remove(type);
                          }
                        });
                      },
                      onGenerate: _generate,
                    )
                  else if (_review != null)
                    _ReviewResult(
                      review: _review!,
                      onGenerateAgain: _startNewReview,
                    ),
                ],
              ),
      ),
    );
  }
}

final class _ReviewComposer extends StatelessWidget {
  const _ReviewComposer({
    required this.contextData,
    required this.selectedTypes,
    required this.generating,
    required this.onChanged,
    required this.onGenerate,
  });

  final DailyReviewContext contextData;
  final Set<DailyReviewContextType> selectedTypes;
  final bool generating;
  final void Function(DailyReviewContextType type, bool selected) onChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final available = contextData.availableTypes;
    final diaryLength = contextData.diary?.entry.markdown.length ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '一起看看今天',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: LifeOsSpacing.xs),
        Text(
          '${contextData.localDate.month}月${contextData.localDate.day}日 · '
          '你决定 AI 这次能看到什么',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: LifeOsSpacing.xl),
        _PrivacyNotice(hasDiary: diaryLength > 0),
        const SizedBox(height: LifeOsSpacing.xl),
        Text('选择本次发送内容', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: LifeOsSpacing.sm),
        _ContextOption(
          icon: Icons.favorite_border_rounded,
          title: '今日状态',
          subtitle: available.contains(DailyReviewContextType.dailyStatus)
              ? '睡眠、情绪、精力、体重和运动记录'
              : '今天还没有状态记录',
          enabled:
              !generating &&
              available.contains(DailyReviewContextType.dailyStatus),
          selected: selectedTypes.contains(DailyReviewContextType.dailyStatus),
          onChanged: (value) =>
              onChanged(DailyReviewContextType.dailyStatus, value),
        ),
        _ContextOption(
          icon: Icons.task_alt_rounded,
          title: '今日任务',
          subtitle: available.contains(DailyReviewContextType.actions)
              ? '${contextData.actions.length} 项任务及完成状态'
              : '今天还没有任务',
          enabled:
              !generating && available.contains(DailyReviewContextType.actions),
          selected: selectedTypes.contains(DailyReviewContextType.actions),
          onChanged: (value) =>
              onChanged(DailyReviewContextType.actions, value),
        ),
        _ContextOption(
          icon: Icons.menu_book_outlined,
          title: '今日日记原文',
          subtitle: available.contains(DailyReviewContextType.diary)
              ? '$diaryLength 字；最多发送前 '
                    '$dailyReviewDiaryCharacterLimit 字，图片不会发送'
              : '今天还没有日记',
          enabled:
              !generating && available.contains(DailyReviewContextType.diary),
          selected: selectedTypes.contains(DailyReviewContextType.diary),
          onChanged: (value) => onChanged(DailyReviewContextType.diary, value),
        ),
        const SizedBox(height: LifeOsSpacing.xl),
        FilledButton.icon(
          onPressed: selectedTypes.isEmpty || generating ? null : onGenerate,
          icon: generating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_rounded),
          label: Text(generating ? '正在整理今天…' : '授权并生成复盘'),
        ),
        const SizedBox(height: LifeOsSpacing.md),
        Text(
          '生成内容是基于有限数据的陪伴性建议，不是对你的评价或事实裁决。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

final class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.hasDiary});

  final bool hasDiary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(LifeOsRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.privacy_tip_outlined, color: colors.primary),
            const SizedBox(width: LifeOsSpacing.md),
            Expanded(
              child: Text(
                '只发送你本次勾选的数据，并通过当前配置的 AI Provider 处理。'
                '${hasDiary ? '日记属于敏感内容，请按自己的意愿选择。' : ''}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ContextOption extends StatelessWidget {
  const _ContextOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: LifeOsSpacing.sm),
      child: CheckboxListTile(
        value: selected,
        onChanged: enabled ? (value) => onChanged(value ?? false) : null,
        secondary: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}

final class _ReviewResult extends StatelessWidget {
  const _ReviewResult({required this.review, required this.onGenerateAgain});

  final AiDailyReview review;
  final VoidCallback onGenerateAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '今天的复盘',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.auto_awesome_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: LifeOsSpacing.xs),
        Text(
          '${review.localDate.month}月${review.localDate.day}日 · '
          '${review.provider.displayName} / ${review.model}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: LifeOsSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(LifeOsSpacing.lg),
            child: MarkdownBody(data: review.content, selectable: true),
          ),
        ),
        const SizedBox(height: LifeOsSpacing.md),
        Wrap(
          spacing: LifeOsSpacing.sm,
          runSpacing: LifeOsSpacing.sm,
          children: [
            for (final type in review.contextTypes)
              Chip(label: Text('已使用：${type.label}')),
          ],
        ),
        const SizedBox(height: LifeOsSpacing.xl),
        OutlinedButton.icon(
          onPressed: onGenerateAgain,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('生成新的复盘'),
        ),
        const SizedBox(height: LifeOsSpacing.md),
        Text(
          'AI 复盘已保存在本机。重新生成会创建新版本，不会修改你的原始记录。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('今日复盘暂时无法打开'),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
