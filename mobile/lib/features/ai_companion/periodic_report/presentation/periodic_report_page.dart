import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';
import 'package:lifeos/features/ai_companion/periodic_report/application/periodic_report_providers.dart';
import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

final class PeriodicReportPage extends ConsumerStatefulWidget {
  const PeriodicReportPage({
    this.initialPeriod = AnalyticsPeriod.sevenDays,
    super.key,
  });

  final AnalyticsPeriod initialPeriod;

  @override
  ConsumerState<PeriodicReportPage> createState() => _PeriodicReportPageState();
}

final class _PeriodicReportPageState extends ConsumerState<PeriodicReportPage> {
  late AnalyticsPeriod _period;
  PeriodicReportPageData? _data;
  AiPeriodicReport? _report;
  final Set<PeriodicReportContextType> _selectedTypes = {};
  var _loading = true;
  var _generating = false;
  var _showComposer = true;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(periodicReportServiceProvider).load(_period);
      if (!mounted) return;
      setState(() {
        _data = data;
        _report = data.latestReport;
        _selectedTypes.clear();
        _showComposer = data.latestReport == null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _data = null;
        _loading = false;
      });
      _showMessage('周期统计暂时无法读取');
    }
  }

  Future<void> _changePeriod(Set<AnalyticsPeriod> selection) async {
    if (_generating || selection.single == _period) return;
    setState(() => _period = selection.single);
    await _load();
  }

  Future<void> _generate() async {
    final context = _data?.context;
    if (context == null || _generating) return;
    setState(() => _generating = true);
    try {
      final report = await ref
          .read(periodicReportServiceProvider)
          .generate(context, PeriodicReportSelection(_selectedTypes));
      if (!mounted) return;
      setState(() {
        _report = report;
        _showComposer = false;
      });
    } on PeriodicReportException catch (error) {
      if (mounted) _showMessage(error.message);
    } on AiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('AI 周期解读生成失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _startNewReport() {
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
      appBar: AppBar(title: const Text('AI 周期解读')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            LifeOsSpacing.lg,
            LifeOsSpacing.md,
            LifeOsSpacing.lg,
            LifeOsSpacing.xxl,
          ),
          children: [
            SegmentedButton<AnalyticsPeriod>(
              segments: [
                for (final period in AnalyticsPeriod.values)
                  ButtonSegment(
                    value: period,
                    label: Text(
                      period == AnalyticsPeriod.sevenDays ? '周报' : '月报',
                    ),
                  ),
              ],
              selected: {_period},
              onSelectionChanged: _generating ? null : _changePeriod,
            ),
            const SizedBox(height: LifeOsSpacing.xl),
            if (_loading)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_data == null)
              _LoadError(onRetry: _load)
            else if (_showComposer)
              _ReportComposer(
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
            else if (_report != null)
              _ReportResult(report: _report!, onGenerateAgain: _startNewReport),
          ],
        ),
      ),
    );
  }
}

final class _ReportComposer extends StatelessWidget {
  const _ReportComposer({
    required this.contextData,
    required this.selectedTypes,
    required this.generating,
    required this.onChanged,
    required this.onGenerate,
  });

  final PeriodicReportContext contextData;
  final Set<PeriodicReportContextType> selectedTypes;
  final bool generating;
  final void Function(PeriodicReportContextType type, bool selected) onChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final report = contextData.analytics;
    final available = contextData.availableTypes;
    final isWeekly = report.period == AnalyticsPeriod.sevenDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isWeekly ? '回顾这一周' : '回顾这一个月',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: LifeOsSpacing.xs),
        Text(
          '${_date(report.startDate)} — ${_date(report.endDate)} · '
          '你决定 AI 能看到哪些聚合指标',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: LifeOsSpacing.xl),
        const _PrivacyNotice(),
        const SizedBox(height: LifeOsSpacing.xl),
        Text('选择本次发送内容', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: LifeOsSpacing.sm),
        _ContextOption(
          icon: Icons.bedtime_outlined,
          title: '状态趋势',
          subtitle: available.contains(PeriodicReportContextType.wellbeing)
              ? _wellbeingSummary(report)
              : '这个周期没有睡眠、情绪或精力记录',
          enabled:
              !generating &&
              available.contains(PeriodicReportContextType.wellbeing),
          selected: selectedTypes.contains(PeriodicReportContextType.wellbeing),
          onChanged: (value) =>
              onChanged(PeriodicReportContextType.wellbeing, value),
        ),
        _ContextOption(
          icon: Icons.favorite_border_rounded,
          title: '健康趋势',
          subtitle: available.contains(PeriodicReportContextType.health)
              ? _healthSummary(report)
              : '这个周期没有体重或运动记录',
          enabled:
              !generating &&
              available.contains(PeriodicReportContextType.health),
          selected: selectedTypes.contains(PeriodicReportContextType.health),
          onChanged: (value) =>
              onChanged(PeriodicReportContextType.health, value),
        ),
        _ContextOption(
          icon: Icons.task_alt_rounded,
          title: '行动完成',
          subtitle: available.contains(PeriodicReportContextType.actions)
              ? '${report.completedActionCount}/${report.actionCount} 项完成 · '
                    '${report.actionCompletionRate?.round() ?? 0}%'
              : '这个周期没有行动记录',
          enabled:
              !generating &&
              available.contains(PeriodicReportContextType.actions),
          selected: selectedTypes.contains(PeriodicReportContextType.actions),
          onChanged: (value) =>
              onChanged(PeriodicReportContextType.actions, value),
        ),
        _ContextOption(
          icon: Icons.flag_outlined,
          title: '目标进度',
          subtitle: available.contains(PeriodicReportContextType.goals)
              ? '${report.activeGoalCount} 个进行中目标 · '
                    '平均 ${report.activeGoalAverageProgress?.round() ?? 0}%'
              : '当前没有进行中的目标',
          enabled:
              !generating &&
              available.contains(PeriodicReportContextType.goals),
          selected: selectedTypes.contains(PeriodicReportContextType.goals),
          onChanged: (value) =>
              onChanged(PeriodicReportContextType.goals, value),
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
          label: Text(
            generating
                ? '正在理解这段时间…'
                : isWeekly
                ? '授权并生成周报'
                : '授权并生成月报',
          ),
        ),
        const SizedBox(height: LifeOsSpacing.md),
        Text(
          'AI 只能解释有限的聚合数据，无法代表你的生活全貌。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  static String _date(CalendarDate value) =>
      '${value.year}.${value.month}.${value.day}';

  static String _wellbeingSummary(AnalyticsReport report) {
    final sleep = report.averageSleepMinutes == null
        ? '睡眠暂无'
        : '睡眠 ${(report.averageSleepMinutes! / 60).toStringAsFixed(1)}h';
    final mood = report.averageMood == null
        ? '情绪暂无'
        : '情绪 ${report.averageMood!.toStringAsFixed(1)}/5';
    final energy = report.averageEnergy == null
        ? '精力暂无'
        : '精力 ${report.averageEnergy!.toStringAsFixed(1)}/5';
    return '$sleep · $mood · $energy';
  }

  static String _healthSummary(AnalyticsReport report) {
    final weight = report.latestWeightGrams == null
        ? '体重暂无'
        : '最新 ${(report.latestWeightGrams! / 1000).toStringAsFixed(1)}kg';
    return '$weight · 运动 ${report.exerciseDays} 天/${report.totalExerciseMinutes} 分钟';
  }
}

final class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
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
                '只发送你本次勾选的统计摘要，以及周期和记录覆盖率。'
                '不会发送逐日原始记录、行动标题、日记、图片或内部 ID。',
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

final class _ReportResult extends StatelessWidget {
  const _ReportResult({required this.report, required this.onGenerateAgain});

  final AiPeriodicReport report;
  final VoidCallback onGenerateAgain;

  @override
  Widget build(BuildContext context) {
    final isWeekly = report.period == AnalyticsPeriod.sevenDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isWeekly ? '这一周的解读' : '这一个月的解读',
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
          '${report.startDate.month}.${report.startDate.day} — '
          '${report.endDate.month}.${report.endDate.day} · '
          '${report.provider.displayName} / ${report.model}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: LifeOsSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(LifeOsSpacing.lg),
            child: MarkdownBody(data: report.content, selectable: true),
          ),
        ),
        const SizedBox(height: LifeOsSpacing.md),
        Wrap(
          spacing: LifeOsSpacing.sm,
          runSpacing: LifeOsSpacing.sm,
          children: [
            for (final type in PeriodicReportContextType.values)
              if (report.contextTypes.contains(type))
                Chip(label: Text('已使用：${type.label}')),
          ],
        ),
        const SizedBox(height: LifeOsSpacing.xl),
        OutlinedButton.icon(
          onPressed: onGenerateAgain,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(isWeekly ? '生成新的周报' : '生成新的月报'),
        ),
        const SizedBox(height: LifeOsSpacing.md),
        Text(
          '报告已保存在本机。重新生成会创建新版本，不会修改原始记录或统计事实。',
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
          const Text('AI 周期解读暂时无法打开'),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
