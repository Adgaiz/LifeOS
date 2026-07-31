import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/app/navigation/lifeos_scaffold.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/goal/application/goal_providers.dart';
import 'package:lifeos/features/goal/domain/goal.dart';
import 'package:lifeos/features/goal/presentation/goal_editor_page.dart';
import 'package:lifeos/features/vision/application/vision_providers.dart';

final class GoalPage extends ConsumerWidget {
  const GoalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(allGoalsProvider);
    final visionTitles = ref
        .watch(allVisionsProvider)
        .maybeWhen(
          data: (items) => {
            for (final vision in items) vision.id: vision.title,
          },
          orElse: () => const <String, String>{},
        );
    return LifeOsScaffold(
      selectedIndex: 2,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openGoalEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新目标'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allGoalsProvider);
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
                '90 天目标',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: LifeOsSpacing.xs),
              Text(
                '把人生方向，带回接下来的每一天。',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LifeOsSpacing.xl),
              goals.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    _LoadError(onRetry: () => ref.invalidate(allGoalsProvider)),
                data: (items) => _GoalGroups(
                  goals: items,
                  visionTitles: visionTitles,
                  today: ref.watch(todayProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _GoalGroups extends StatelessWidget {
  const _GoalGroups({
    required this.goals,
    required this.visionTitles,
    required this.today,
  });

  final List<GoalAggregate> goals;
  final Map<String, String> visionTitles;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    final active = _withStatus(GoalStatus.active);
    final completed = _withStatus(GoalStatus.completed);
    final archived = _withStatus(GoalStatus.archived);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isEmpty) const _EmptyGoal() else ..._cards(active),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: LifeOsSpacing.xl),
          _StoredGoals(
            title: '已完成目标',
            goals: completed,
            visionTitles: visionTitles,
            today: today,
          ),
        ],
        if (archived.isNotEmpty) ...[
          const SizedBox(height: LifeOsSpacing.md),
          _StoredGoals(
            title: '已归档目标',
            goals: archived,
            visionTitles: visionTitles,
            today: today,
          ),
        ],
      ],
    );
  }

  List<GoalAggregate> _withStatus(GoalStatus status) => goals
      .where((aggregate) => aggregate.goal.status == status)
      .toList(growable: false);

  List<Widget> _cards(List<GoalAggregate> items) => [
    for (var index = 0; index < items.length; index++) ...[
      _GoalCard(
        aggregate: items[index],
        visionTitle: visionTitles[items[index].goal.visionId],
        today: today,
      ),
      if (index != items.length - 1) const SizedBox(height: LifeOsSpacing.md),
    ],
  ];
}

enum _GoalAction { edit, complete, reopen, archive, delete }

final class _GoalCard extends ConsumerWidget {
  const _GoalCard({
    required this.aggregate,
    required this.today,
    this.visionTitle,
  });

  final GoalAggregate aggregate;
  final CalendarDate today;
  final String? visionTitle;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    _GoalAction action,
  ) async {
    try {
      switch (action) {
        case _GoalAction.edit:
          await openGoalEditor(context, aggregate: aggregate);
          return;
        case _GoalAction.complete:
          await ref.read(goalServiceProvider).complete(aggregate.goal.id);
          return;
        case _GoalAction.reopen:
          await ref.read(goalServiceProvider).reopen(aggregate.goal.id);
          return;
        case _GoalAction.archive:
          await ref.read(goalServiceProvider).archive(aggregate.goal.id);
          return;
        case _GoalAction.delete:
          await _delete(context, ref);
          return;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('目标暂时无法更新，请稍后重试')));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个目标？'),
        content: const Text('目标和关键结果将不再显示，已关联的每日行动会保留。'),
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
    if (confirmed == true) {
      await ref.read(goalServiceProvider).delete(aggregate.goal.id);
    }
  }

  Future<void> _updateProgress(
    BuildContext context,
    WidgetRef ref,
    GoalKeyResult keyResult,
  ) async {
    var progress = keyResult.progress;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('更新关键结果进度'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(keyResult.title),
              const SizedBox(height: LifeOsSpacing.lg),
              Text(
                '$progress%',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Slider(
                value: progress.toDouble(),
                max: 100,
                divisions: 100,
                label: '$progress%',
                onChanged: (value) =>
                    setDialogState(() => progress = value.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(progress),
              child: const Text('保存进度'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || selected == keyResult.progress) {
      return;
    }
    try {
      await ref
          .read(goalServiceProvider)
          .updateKeyResultProgress(keyResult.id, selected);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('进度暂时无法更新，请稍后重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = aggregate.goal;
    final progress = aggregate.progress.round();
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => openGoalEditor(context, aggregate: aggregate),
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                PopupMenuButton<_GoalAction>(
                  tooltip: '目标操作',
                  onSelected: (action) => _run(context, ref, action),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _GoalAction.edit,
                      child: Text('编辑'),
                    ),
                    if (goal.status == GoalStatus.active)
                      const PopupMenuItem(
                        value: _GoalAction.complete,
                        child: Text('标记为已完成'),
                      )
                    else
                      const PopupMenuItem(
                        value: _GoalAction.reopen,
                        child: Text('恢复为进行中'),
                      ),
                    if (goal.status != GoalStatus.archived)
                      const PopupMenuItem(
                        value: _GoalAction.archive,
                        child: Text('归档'),
                      ),
                    const PopupMenuItem(
                      value: _GoalAction.delete,
                      child: Text('删除'),
                    ),
                  ],
                ),
              ],
            ),
            if (goal.description != null) ...[
              const SizedBox(height: LifeOsSpacing.sm),
              Text(
                goal.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (visionTitle != null) ...[
              const SizedBox(height: LifeOsSpacing.sm),
              Text(
                '愿景 · $visionTitle',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: colors.primary),
              ),
            ],
            const SizedBox(height: LifeOsSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(LifeOsRadii.control),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 9,
                    ),
                  ),
                ),
                const SizedBox(width: LifeOsSpacing.md),
                Text('$progress%'),
              ],
            ),
            const SizedBox(height: LifeOsSpacing.sm),
            Row(
              children: [
                Text(
                  '${_date(goal.startDate)} – ${_date(goal.endDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  _period(goal),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(height: LifeOsSpacing.xl),
            for (
              var index = 0;
              index < aggregate.keyResults.length;
              index++
            ) ...[
              _KeyResultTile(
                keyResult: aggregate.keyResults[index],
                onTap: () =>
                    _updateProgress(context, ref, aggregate.keyResults[index]),
              ),
              if (index != aggregate.keyResults.length - 1)
                const SizedBox(height: LifeOsSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  String _date(CalendarDate date) => '${date.month}.${date.day}';

  String _period(Goal goal) {
    if (today.compareTo(goal.startDate) < 0) {
      return '${today.daysUntil(goal.startDate)} 天后开始';
    }
    if (today.compareTo(goal.endDate) > 0) {
      return '周期已结束';
    }
    return '第 ${goal.startDate.daysUntil(today) + 1}/${goal.durationInDays} 天';
  }
}

final class _KeyResultTile extends StatelessWidget {
  const _KeyResultTile({required this.keyResult, required this.onTap});

  final GoalKeyResult keyResult;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(LifeOsRadii.control),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LifeOsSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: keyResult.progress / 100,
                    strokeWidth: 4,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  Center(
                    child: Text(
                      '${keyResult.progress}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: LifeOsSpacing.md),
            Expanded(child: Text(keyResult.title)),
            const Icon(Icons.edit_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

final class _StoredGoals extends StatelessWidget {
  const _StoredGoals({
    required this.title,
    required this.goals,
    required this.visionTitles,
    required this.today,
  });

  final String title;
  final List<GoalAggregate> goals;
  final Map<String, String> visionTitles;
  final CalendarDate today;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text('$title（${goals.length}）'),
        childrenPadding: const EdgeInsets.all(LifeOsSpacing.md),
        children: [
          for (var index = 0; index < goals.length; index++) ...[
            _GoalCard(
              aggregate: goals[index],
              visionTitle: visionTitles[goals[index].goal.visionId],
              today: today,
            ),
            if (index != goals.length - 1)
              const SizedBox(height: LifeOsSpacing.sm),
          ],
        ],
      ),
    );
  }
}

final class _EmptyGoal extends StatelessWidget {
  const _EmptyGoal();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.xxl),
        child: Column(
          children: [
            Icon(
              Icons.flag_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: LifeOsSpacing.md),
            Text('把方向变成一个阶段', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: LifeOsSpacing.sm),
            const Text('90 天是默认模板，不是对生活的硬性期限。'),
            const SizedBox(height: LifeOsSpacing.xl),
            FilledButton.tonalIcon(
              onPressed: () => openGoalEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('创建第一个目标'),
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
        const Text('目标暂时无法读取'),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}
