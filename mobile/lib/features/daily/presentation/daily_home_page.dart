import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/app/navigation/lifeos_scaffold.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/action/presentation/action_section.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/daily/presentation/daily_check_in_sheet.dart';

final class DailyHomePage extends ConsumerWidget {
  const DailyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(todayProvider);
    final timezone = ref.watch(currentTimeZoneProvider);
    final record = ref.watch(todayRecordProvider);

    return LifeOsScaffold(
      selectedIndex: 0,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayRecordProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LifeOsSpacing.lg,
              LifeOsSpacing.xl,
              LifeOsSpacing.lg,
              LifeOsSpacing.xxl,
            ),
            children: [
              _TodayHeader(
                date: date,
                onOpenAiSettings: () => context.push('/settings/ai'),
              ),
              const SizedBox(height: LifeOsSpacing.xl),
              record.when(
                loading: () => const _StatusLoadingCard(),
                error: (_, _) => _StatusErrorCard(
                  onRetry: () => ref.invalidate(todayRecordProvider),
                ),
                data: (value) => _DailyStatusCard(
                  record: value,
                  onEdit: () => showDailyCheckInSheet(
                    context: context,
                    date: date,
                    timezone: timezone,
                    record: value,
                  ),
                ),
              ),
              const SizedBox(height: LifeOsSpacing.lg),
              ActionSection(date: date),
              const SizedBox(height: LifeOsSpacing.lg),
              _GrowthTrendCard(onOpen: () => context.push('/analytics')),
              const SizedBox(height: LifeOsSpacing.lg),
              _CompanionCard(
                onStartReview: () => context.push('/ai/daily-review'),
                onStartFriend: () => context.push('/ai/friend'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _GrowthTrendCard extends StatelessWidget {
  const _GrowthTrendCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(LifeOsRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(LifeOsSpacing.lg),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(LifeOsRadii.control),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(LifeOsSpacing.md),
                  child: Icon(Icons.insights_outlined),
                ),
              ),
              const SizedBox(width: LifeOsSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('成长趋势'),
                    SizedBox(height: LifeOsSpacing.xs),
                    Text('看见睡眠、状态与行动的变化'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

final class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.date, required this.onOpenAiSettings});

  final CalendarDate date;
  final VoidCallback onOpenAiSettings;

  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdays[date.toLocalDateTime().weekday - 1];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今天，$weekday',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: LifeOsSpacing.xs),
              Text(
                '${date.month}月${date.day}日 · 先照顾好今天',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'AI 服务设置',
          onPressed: onOpenAiSettings,
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
        const SizedBox(width: LifeOsSpacing.xs),
        const _LifeOsMark(),
      ],
    );
  }
}

final class _LifeOsMark extends StatelessWidget {
  const _LifeOsMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'LifeOS',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(LifeOsRadii.control),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LifeOsSpacing.md,
            vertical: LifeOsSpacing.sm,
          ),
          child: Text(
            'L',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

final class _DailyStatusCard extends StatelessWidget {
  const _DailyStatusCard({required this.record, required this.onEdit});

  final DailyRecord? record;
  final VoidCallback onEdit;

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
                Expanded(
                  child: Text(
                    '今日状态',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(
                    record == null ? Icons.add_rounded : Icons.edit_outlined,
                  ),
                  label: Text(record == null ? '记录' : '修改'),
                ),
              ],
            ),
            const SizedBox(height: LifeOsSpacing.md),
            if (record == null)
              _EmptyStatus(onRecord: onEdit)
            else
              _StatusMetrics(record: record!),
          ],
        ),
      ),
    );
  }
}

final class _EmptyStatus extends StatelessWidget {
  const _EmptyStatus({required this.onRecord});

  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LifeOsSpacing.lg),
      child: Column(
        children: [
          Text('用一分钟，记下此刻的状态。', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: LifeOsSpacing.xs),
          Text('记录不是评价，只是看见自己。', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: LifeOsSpacing.lg),
          FilledButton.tonal(onPressed: onRecord, child: const Text('开始记录')),
        ],
      ),
    );
  }
}

final class _StatusMetrics extends StatelessWidget {
  const _StatusMetrics({required this.record});

  final DailyRecord record;

  @override
  Widget build(BuildContext context) {
    final metrics = <({IconData icon, String label, String value})>[
      (
        icon: Icons.bedtime_outlined,
        label: '睡眠',
        value: _sleepLabel(record.sleepMinutes),
      ),
      (
        icon: Icons.sentiment_satisfied_alt_rounded,
        label: '心情',
        value: record.mood?.label ?? '未记录',
      ),
      (
        icon: Icons.bolt_rounded,
        label: '精力',
        value: record.energy?.label ?? '未记录',
      ),
      (
        icon: Icons.monitor_weight_outlined,
        label: '体重',
        value: record.weightGrams == null
            ? '未记录'
            : '${_decimal(record.weightGrams! / 1000)} kg',
      ),
      (
        icon: Icons.directions_walk_rounded,
        label: '运动',
        value: record.exerciseMinutes == null
            ? '未记录'
            : '${record.exerciseMinutes} 分钟',
      ),
    ];
    return Wrap(
      spacing: LifeOsSpacing.sm,
      runSpacing: LifeOsSpacing.sm,
      children: [
        for (final metric in metrics)
          _MetricChip(
            icon: metric.icon,
            label: metric.label,
            value: metric.value,
          ),
      ],
    );
  }

  static String _sleepLabel(int? minutes) {
    if (minutes == null) {
      return '未记录';
    }
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) {
      return '$rest 分钟';
    }
    return rest == 0 ? '$hours 小时' : '$hours小时$rest分';
  }

  static String _decimal(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

final class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 128),
      padding: const EdgeInsets.all(LifeOsSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(LifeOsRadii.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: LifeOsSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

final class _CompanionCard extends StatelessWidget {
  const _CompanionCard({
    required this.onStartReview,
    required this.onStartFriend,
  });

  final VoidCallback onStartReview;
  final VoidCallback onStartFriend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(LifeOsRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: colorScheme.primary),
                const SizedBox(width: LifeOsSpacing.md),
                Expanded(
                  child: Text(
                    'AI 当日复盘',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LifeOsSpacing.sm),
            const Text('不是评价今天，而是温柔地看见今天。'),
            const SizedBox(height: LifeOsSpacing.md),
            FilledButton.tonalIcon(
              onPressed: onStartReview,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('一起回顾今天'),
            ),
            const SizedBox(height: LifeOsSpacing.sm),
            OutlinedButton.icon(
              onPressed: onStartFriend,
              icon: const Icon(Icons.favorite_border_rounded),
              label: const Text('聊聊此刻'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatusLoadingCard extends StatelessWidget {
  const _StatusLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

final class _StatusErrorCard extends StatelessWidget {
  const _StatusErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.xl),
        child: Column(
          children: [
            const Text('今日状态暂时无法读取'),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
