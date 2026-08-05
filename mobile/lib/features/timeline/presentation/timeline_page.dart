import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/app/navigation/lifeos_scaffold.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/timeline/application/timeline_providers.dart';
import 'package:lifeos/features/timeline/domain/timeline_event.dart';
import 'package:lifeos/features/timeline/presentation/timeline_editor_page.dart';

final class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(allTimelineEventsProvider);
    return LifeOsScaffold(
      selectedIndex: 4,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTimelineEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('记录节点'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(allTimelineEventsProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LifeOsSpacing.lg,
              LifeOsSpacing.xl,
              LifeOsSpacing.lg,
              104,
            ),
            children: [
              const _TimelineHeader(),
              const SizedBox(height: LifeOsSpacing.xl),
              events.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _TimelineLoadError(
                  onRetry: () => ref.invalidate(allTimelineEventsProvider),
                ),
                data: (items) => items.isEmpty
                    ? const _EmptyTimeline()
                    : _TimelineContent(events: items),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '人生时间线',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: LifeOsSpacing.xs),
        Text(
          '回头看，才发现自己已经走了很远。',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

final class _TimelineContent extends StatelessWidget {
  const _TimelineContent({required this.events});

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    int? previousYear;
    int? previousMonth;
    for (final event in events) {
      if (event.occurredOn.year != previousYear ||
          event.occurredOn.month != previousMonth) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: LifeOsSpacing.lg));
        }
        children.add(
          _MonthHeader(
            year: event.occurredOn.year,
            month: event.occurredOn.month,
          ),
        );
        children.add(const SizedBox(height: LifeOsSpacing.sm));
        previousYear = event.occurredOn.year;
        previousMonth = event.occurredOn.month;
      }
      children.add(_TimelineEventTile(event: event));
      children.add(const SizedBox(height: LifeOsSpacing.sm));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

final class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.year, required this.month});

  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$year 年 $month 月',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

enum _TimelineMenuAction { edit, delete }

final class _TimelineEventTile extends ConsumerWidget {
  const _TimelineEventTile({required this.event});

  final TimelineEvent event;

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _TimelineMenuAction action,
  ) async {
    if (action == _TimelineMenuAction.edit) {
      await openTimelineEditor(context, event: event);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个人生节点？'),
        content: const Text('删除后，它将不再出现在人生时间线中。'),
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
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(timelineServiceProvider).delete(event.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('人生节点暂时无法删除，请稍后重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            children: [
              Text(
                event.occurredOn.day.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text('日', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        const SizedBox(width: LifeOsSpacing.sm),
        Expanded(
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(LifeOsRadii.card),
              onTap: event.isManual
                  ? () => openTimelineEditor(context, event: event)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(LifeOsSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _iconFor(event.type),
                          size: 20,
                          color: colors.primary,
                        ),
                        const SizedBox(width: LifeOsSpacing.sm),
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (event.isManual)
                          PopupMenuButton<_TimelineMenuAction>(
                            tooltip: '人生节点操作',
                            onSelected: (action) =>
                                _handleAction(context, ref, action),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: _TimelineMenuAction.edit,
                                child: Text('编辑'),
                              ),
                              PopupMenuItem(
                                value: _TimelineMenuAction.delete,
                                child: Text('删除'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (event.description != null) ...[
                      const SizedBox(height: LifeOsSpacing.sm),
                      Text(
                        event.description!,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: LifeOsSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(
                            LifeOsRadii.control,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: LifeOsSpacing.md,
                            vertical: LifeOsSpacing.xs,
                          ),
                          child: Text(
                            event.type.label,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(TimelineEventType type) {
    return switch (type) {
      TimelineEventType.beginning => Icons.wb_sunny_outlined,
      TimelineEventType.milestone => Icons.workspace_premium_outlined,
      TimelineEventType.turningPoint => Icons.alt_route_rounded,
      TimelineEventType.memory => Icons.favorite_border_rounded,
    };
  }
}

final class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LifeOsSpacing.xl,
          vertical: LifeOsSpacing.xxl,
        ),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: LifeOsSpacing.md),
            Text('从一个重要时刻开始', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: LifeOsSpacing.sm),
            Text(
              '它不必惊天动地。\n只要你觉得，这一刻值得记住。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LifeOsSpacing.xl),
            FilledButton.tonalIcon(
              onPressed: () => openTimelineEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('记录第一个节点'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TimelineLoadError extends StatelessWidget {
  const _TimelineLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.xl),
        child: Column(
          children: [
            const Text('人生时间线暂时无法读取'),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
