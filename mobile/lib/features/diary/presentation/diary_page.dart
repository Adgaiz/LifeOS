import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/app/navigation/lifeos_scaffold.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/diary/application/diary_providers.dart';
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/presentation/diary_content_widgets.dart';
import 'package:lifeos/features/diary/presentation/diary_editor_page.dart';

final class DiaryPage extends ConsumerWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(allDiaryEntriesProvider);
    ref.watch(diaryMaintenanceProvider);
    final today = ref.watch(todayProvider);
    final todayEntry = entries.asData?.value
        .where((aggregate) => aggregate.entry.localDate == today)
        .firstOrNull;
    return LifeOsScaffold(
      selectedIndex: 3,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDiaryEditor(context, aggregate: todayEntry),
        icon: Icon(todayEntry == null ? Icons.edit_outlined : Icons.edit_note),
        label: Text(todayEntry == null ? '写今天' : '继续写'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allDiaryEntriesProvider);
            ref.invalidate(diaryMaintenanceProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LifeOsSpacing.lg,
              LifeOsSpacing.xl,
              LifeOsSpacing.lg,
              104,
            ),
            children: [
              Text(
                '人生记录',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: LifeOsSpacing.xs),
              Text(
                '不必写得完整，只要留下此刻真实的你。',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LifeOsSpacing.xl),
              entries.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _LoadError(
                  onRetry: () => ref.invalidate(allDiaryEntriesProvider),
                ),
                data: (items) => items.isEmpty
                    ? const _EmptyDiary()
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            _DiaryCard(aggregate: items[index]),
                            if (index != items.length - 1)
                              const SizedBox(height: LifeOsSpacing.md),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DiaryAction { edit, delete }

final class _DiaryCard extends ConsumerWidget {
  const _DiaryCard({required this.aggregate});

  final DiaryAggregate aggregate;

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref,
    _DiaryAction action,
  ) async {
    if (action == _DiaryAction.edit) {
      await openDiaryEditor(context, aggregate: aggregate);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这篇日记？'),
        content: const Text('日记会从列表中移除，图片将在 7 天后清理。'),
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
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(diaryServiceProvider).delete(aggregate.entry.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('日记暂时无法删除，请稍后重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = aggregate.entry;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openDiaryEditor(context, aggregate: aggregate),
        child: Padding(
          padding: const EdgeInsets.all(LifeOsSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.localDate.year}年${entry.localDate.month}月${entry.localDate.day}日',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  PopupMenuButton<_DiaryAction>(
                    tooltip: '日记操作',
                    onSelected: (action) => _runAction(context, ref, action),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _DiaryAction.edit,
                        child: Text('编辑'),
                      ),
                      PopupMenuItem(
                        value: _DiaryAction.delete,
                        child: Text('删除'),
                      ),
                    ],
                  ),
                ],
              ),
              if (aggregate.attachments.isNotEmpty) ...[
                const SizedBox(height: LifeOsSpacing.sm),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(LifeOsRadii.control),
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: DiaryStoredImage(
                        relativePath:
                            aggregate.attachments.first.thumbnailRelativePath,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: LifeOsSpacing.md),
              Text(
                _plainTextExcerpt(entry.markdown),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (aggregate.tags.isNotEmpty) ...[
                const SizedBox(height: LifeOsSpacing.md),
                Wrap(
                  spacing: LifeOsSpacing.sm,
                  runSpacing: LifeOsSpacing.xs,
                  children: [
                    for (final tag in aggregate.tags)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('#${tag.name}'),
                      ),
                  ],
                ),
              ],
              if (aggregate.attachments.length > 1) ...[
                const SizedBox(height: LifeOsSpacing.sm),
                Text(
                  '共 ${aggregate.attachments.length} 张图片',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _plainTextExcerpt(String markdown) {
    return markdown
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '[图片]')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]*\)'), r'$1')
        .replaceAll(RegExp(r'^[#>*+\-]+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'[`*_~]'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

final class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.xxl),
        child: Column(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: LifeOsSpacing.md),
            Text('为今天留下一点痕迹', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: LifeOsSpacing.sm),
            const Text('一句话、一种感受，也是一篇值得保存的日记。'),
            const SizedBox(height: LifeOsSpacing.xl),
            FilledButton.tonalIcon(
              onPressed: () => openDiaryEditor(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('写下第一篇日记'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('日记暂时无法读取'),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}
