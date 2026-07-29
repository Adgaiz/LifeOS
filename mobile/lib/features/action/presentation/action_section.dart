import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/action/application/action_providers.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/action/presentation/action_editor_sheet.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

final class ActionSection extends ConsumerWidget {
  const ActionSection({required this.date, super.key});

  final CalendarDate date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(todayActionsProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '今日行动',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '添加今日行动',
                  onPressed: () =>
                      showActionEditorSheet(context: context, date: date),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: LifeOsSpacing.md),
            actions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _LoadError(
                onRetry: () => ref.invalidate(todayActionsProvider),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyActions()
                  : _ActionList(actions: items),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ActionList extends ConsumerWidget {
  const _ActionList({required this.actions});

  final List<DailyAction> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = actions
        .where((action) => action.status == ActionStatus.completed)
        .length;
    final partial = actions
        .where((action) => action.status == ActionStatus.partial)
        .length;
    final progress = (completed + partial * 0.5) / actions.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LifeOsRadii.control),
                child: LinearProgressIndicator(value: progress, minHeight: 7),
              ),
            ),
            const SizedBox(width: LifeOsSpacing.md),
            Text('$completed/${actions.length} 完成'),
          ],
        ),
        const SizedBox(height: LifeOsSpacing.md),
        for (var index = 0; index < actions.length; index++) ...[
          _ActionTile(action: actions[index]),
          if (index != actions.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

final class _ActionTile extends ConsumerWidget {
  const _ActionTile({required this.action});

  final DailyAction action;

  IconData get _statusIcon => switch (action.status) {
    ActionStatus.pending => Icons.radio_button_unchecked_rounded,
    ActionStatus.partial => Icons.timelapse_rounded,
    ActionStatus.completed => Icons.check_circle_rounded,
  };

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个行动？'),
        content: const Text('删除后，它将不再出现在今天的行动中。'),
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
      await ref.read(actionServiceProvider).delete(action.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂时无法删除，请稍后重试')));
      }
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    ActionStatus status,
  ) async {
    try {
      await ref.read(actionServiceProvider).updateStatus(action.id, status);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('状态更新失败，请稍后重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LifeOsSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PopupMenuButton<ActionStatus>(
            tooltip: '更新完成状态',
            initialValue: action.status,
            onSelected: (status) => _updateStatus(context, ref, status),
            itemBuilder: (context) => [
              for (final status in ActionStatus.values)
                PopupMenuItem(value: status, child: Text(status.label)),
            ],
            child: Semantics(
              button: true,
              label: '当前状态：${action.status.label}，点击修改',
              child: Padding(
                padding: const EdgeInsets.all(LifeOsSpacing.sm),
                child: Icon(
                  _statusIcon,
                  color: action.status == ActionStatus.completed
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: LifeOsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    decoration: action.status == ActionStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: LifeOsSpacing.xs),
                Text(
                  [
                    action.category.label,
                    action.status.label,
                    if (action.minimumAction != null)
                      '最低：${action.minimumAction}',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '删除行动',
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }
}

final class _EmptyActions extends StatelessWidget {
  const _EmptyActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LifeOsSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.spa_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: LifeOsSpacing.sm),
          const Text('今天还没有行动'),
          const SizedBox(height: LifeOsSpacing.xs),
          Text('先添加一件真正重要的小事。', style: Theme.of(context).textTheme.bodySmall),
        ],
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
        const Text('今日行动暂时无法读取'),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}
