import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/analytics/application/analytics_providers.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/analytics/presentation/analytics_trend_chart.dart';

final class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

final class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  var _period = AnalyticsPeriod.sevenDays;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(analyticsReportProvider(_period));
    return Scaffold(
      appBar: AppBar(title: const Text('成长趋势')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(analyticsReportProvider(_period));
            await ref.read(analyticsReportProvider(_period).future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LifeOsSpacing.lg,
              LifeOsSpacing.md,
              LifeOsSpacing.lg,
              LifeOsSpacing.xxl,
            ),
            children: [
              Text(
                '看见变化，不评价自己。',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: LifeOsSpacing.xs),
              Text(
                '所有指标都在本机按固定公式计算，不调用 AI。',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LifeOsSpacing.xl),
              SegmentedButton<AnalyticsPeriod>(
                segments: [
                  for (final period in AnalyticsPeriod.values)
                    ButtonSegment(value: period, label: Text(period.label)),
                ],
                selected: {_period},
                onSelectionChanged: (selection) {
                  setState(() => _period = selection.single);
                },
              ),
              const SizedBox(height: LifeOsSpacing.xl),
              report.when(
                loading: () => const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => _AnalyticsLoadError(
                  onRetry: () =>
                      ref.invalidate(analyticsReportProvider(_period)),
                ),
                data: (value) => _AnalyticsContent(report: value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.report});

  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!report.hasPeriodData) ...[
          const _EmptyPeriodNotice(),
          const SizedBox(height: LifeOsSpacing.lg),
        ],
        _SummaryGrid(report: report),
        const SizedBox(height: LifeOsSpacing.xl),
        _TrendCard(
          title: '睡眠趋势',
          summary: report.averageSleepMinutes == null
              ? '暂无平均值'
              : '平均 ${_formatHours(report.averageSleepMinutes!)}',
          series: [
            AnalyticsChartSeries(
              label: '睡眠',
              color: Theme.of(context).colorScheme.primary,
              values: report.days
                  .map(
                    (day) => day.sleepMinutes == null
                        ? null
                        : day.sleepMinutes! / 60,
                  )
                  .toList(growable: false),
            ),
          ],
          report: report,
        ),
        const SizedBox(height: LifeOsSpacing.lg),
        _TrendCard(
          title: '情绪与精力',
          summary:
              '情绪 ${_formatLevel(report.averageMood)} · 精力 ${_formatLevel(report.averageEnergy)}',
          series: [
            AnalyticsChartSeries(
              label: '情绪',
              color: Theme.of(context).colorScheme.primary,
              values: report.days
                  .map((day) => day.mood)
                  .toList(growable: false),
            ),
            AnalyticsChartSeries(
              label: '精力',
              color: Theme.of(context).colorScheme.tertiary,
              values: report.days
                  .map((day) => day.energy)
                  .toList(growable: false),
            ),
          ],
          report: report,
        ),
        const SizedBox(height: LifeOsSpacing.lg),
        _TrendCard(
          title: '体重趋势',
          summary: _weightSummary(report),
          series: [
            AnalyticsChartSeries(
              label: '体重',
              color: Theme.of(context).colorScheme.secondary,
              values: report.days
                  .map(
                    (day) => day.weightGrams == null
                        ? null
                        : day.weightGrams! / 1000,
                  )
                  .toList(growable: false),
            ),
          ],
          report: report,
        ),
        const SizedBox(height: LifeOsSpacing.lg),
        const _FormulaNote(),
      ],
    );
  }

  static String _formatHours(double minutes) {
    return '${(minutes / 60).toStringAsFixed(1)} 小时';
  }

  static String _formatLevel(double? value) {
    return value == null ? '暂无' : value.toStringAsFixed(1);
  }

  static String _weightSummary(AnalyticsReport report) {
    final latest = report.latestWeightGrams;
    if (latest == null) return '暂无最新体重';
    final latestLabel = '${(latest / 1000).toStringAsFixed(1)} kg';
    final change = report.weightChangeGrams;
    if (change == null) return '最新 $latestLabel';
    final sign = change > 0 ? '+' : '';
    return '最新 $latestLabel · 周期变化 $sign${(change / 1000).toStringAsFixed(1)} kg';
  }
}

final class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report});

  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - LifeOsSpacing.md) / 2;
        return Wrap(
          spacing: LifeOsSpacing.md,
          runSpacing: LifeOsSpacing.md,
          children: [
            SizedBox(
              width: width,
              child: _SummaryMetric(
                icon: Icons.fact_check_outlined,
                label: '记录天数',
                value: '${report.recordDays}/${report.period.dayCount}',
                detail: '覆盖 ${report.checkInRate.round()}%',
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryMetric(
                icon: Icons.task_alt_rounded,
                label: '行动完成率',
                value: report.actionCompletionRate == null
                    ? '暂无'
                    : '${report.actionCompletionRate!.round()}%',
                detail:
                    '${report.completedActionCount}/${report.actionCount} 项完成',
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryMetric(
                icon: Icons.directions_run_rounded,
                label: '运动',
                value: '${report.exerciseDays} 天',
                detail: '共 ${report.totalExerciseMinutes} 分钟',
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryMetric(
                icon: Icons.flag_outlined,
                label: '进行中目标',
                value: report.activeGoalAverageProgress == null
                    ? '暂无'
                    : '${report.activeGoalAverageProgress!.round()}%',
                detail: '${report.activeGoalCount} 个目标平均进度',
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: LifeOsSpacing.md),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: LifeOsSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: LifeOsSpacing.xs),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

final class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.summary,
    required this.series,
    required this.report,
  });

  final String title;
  final String summary;
  final List<AnalyticsChartSeries> series;
  final AnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: LifeOsSpacing.xs),
            Text(summary, style: Theme.of(context).textTheme.bodyMedium),
            if (series.length > 1) ...[
              const SizedBox(height: LifeOsSpacing.sm),
              Wrap(
                spacing: LifeOsSpacing.lg,
                children: [
                  for (final item in series) _LegendItem(series: item),
                ],
              ),
            ],
            const SizedBox(height: LifeOsSpacing.md),
            AnalyticsTrendChart(
              series: series,
              startLabel: '${report.startDate.month}.${report.startDate.day}',
              endLabel: '${report.endDate.month}.${report.endDate.day}',
            ),
          ],
        ),
      ),
    );
  }
}

final class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.series});

  final AnalyticsChartSeries series;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: series.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: LifeOsSpacing.xs),
        Text(series.label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

final class _EmptyPeriodNotice extends StatelessWidget {
  const _EmptyPeriodNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.insights_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: LifeOsSpacing.md),
            const Expanded(child: Text('这个周期还没有状态或行动记录，从今天开始就很好。')),
          ],
        ),
      ),
    );
  }
}

final class _FormulaNote extends StatelessWidget {
  const _FormulaNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(LifeOsRadii.control),
      ),
      child: const Padding(
        padding: EdgeInsets.all(LifeOsSpacing.lg),
        child: Text(
          '统计说明：缺失数据不按 0 计算；行动完成率 = 已完成 ÷ 全部行动；'
          '目标进度取进行中目标各关键结果平均值。统计结果仅供自我观察，不用于医疗判断。',
        ),
      ),
    );
  }
}

final class _AnalyticsLoadError extends StatelessWidget {
  const _AnalyticsLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.xl),
        child: Column(
          children: [
            const Text('成长趋势暂时无法计算'),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
