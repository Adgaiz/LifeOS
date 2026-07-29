import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';

Future<void> showDailyCheckInSheet({
  required BuildContext context,
  required CalendarDate date,
  required String timezone,
  required DailyRecord? record,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        _DailyCheckInSheet(date: date, timezone: timezone, record: record),
  );
}

final class _DailyCheckInSheet extends ConsumerStatefulWidget {
  const _DailyCheckInSheet({
    required this.date,
    required this.timezone,
    required this.record,
  });

  final CalendarDate date;
  final String timezone;
  final DailyRecord? record;

  @override
  ConsumerState<_DailyCheckInSheet> createState() => _DailyCheckInSheetState();
}

final class _DailyCheckInSheetState extends ConsumerState<_DailyCheckInSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sleepController;
  late final TextEditingController _weightController;
  late final TextEditingController _exerciseController;
  MoodLevel? _mood;
  EnergyLevel? _energy;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _sleepController = TextEditingController(
      text: _formatDecimal(
        record?.sleepMinutes == null ? null : record!.sleepMinutes! / 60,
      ),
    );
    _weightController = TextEditingController(
      text: _formatDecimal(
        record?.weightGrams == null ? null : record!.weightGrams! / 1000,
      ),
    );
    _exerciseController = TextEditingController(
      text: record?.exerciseMinutes?.toString() ?? '',
    );
    _mood = record?.mood;
    _energy = record?.energy;
  }

  @override
  void dispose() {
    _sleepController.dispose();
    _weightController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  String _formatDecimal(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  String? _validateDecimal(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed < min || parsed > max) {
      return '$label应在 $min 到 $max 之间';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final sleepHours = double.tryParse(_sleepController.text.trim());
      final weightKg = double.tryParse(_weightController.text.trim());
      final exerciseMinutes = int.tryParse(_exerciseController.text.trim());
      await ref
          .read(dailyServiceProvider)
          .saveCheckIn(
            DailyCheckInInput(
              localDate: widget.date,
              timezone: widget.timezone,
              sleepMinutes: sleepHours == null
                  ? null
                  : (sleepHours * 60).round(),
              mood: _mood,
              energy: _energy,
              weightGrams: weightKg == null ? null : (weightKg * 1000).round(),
              exerciseMinutes: exerciseMinutes,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DailyValidationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂时无法保存，请稍后重试')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        LifeOsSpacing.xl,
        LifeOsSpacing.sm,
        LifeOsSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + LifeOsSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('记录今天', style: textTheme.headlineSmall),
            const SizedBox(height: LifeOsSpacing.xs),
            Text(
              '不必面面俱到，只记录你愿意留下的部分。',
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LifeOsSpacing.xl),
            _NumberField(
              controller: _sleepController,
              label: '睡眠',
              suffix: '小时',
              decimal: true,
              validator: (value) =>
                  _validateDecimal(value, min: 0, max: 24, label: '睡眠时间'),
            ),
            const SizedBox(height: LifeOsSpacing.lg),
            _ChoiceSection<MoodLevel>(
              title: '心情',
              values: MoodLevel.values,
              selected: _mood,
              labelOf: (value) => value.label,
              onSelected: (value) => setState(() => _mood = value),
            ),
            const SizedBox(height: LifeOsSpacing.lg),
            _ChoiceSection<EnergyLevel>(
              title: '精力',
              values: EnergyLevel.values,
              selected: _energy,
              labelOf: (value) => value.label,
              onSelected: (value) => setState(() => _energy = value),
            ),
            const SizedBox(height: LifeOsSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NumberField(
                    controller: _weightController,
                    label: '体重',
                    suffix: 'kg',
                    decimal: true,
                    validator: (value) =>
                        _validateDecimal(value, min: 1, max: 1000, label: '体重'),
                  ),
                ),
                const SizedBox(width: LifeOsSpacing.md),
                Expanded(
                  child: _NumberField(
                    controller: _exerciseController,
                    label: '运动',
                    suffix: '分钟',
                    validator: (value) => _validateDecimal(
                      value,
                      min: 0,
                      max: 1440,
                      label: '运动时间',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: LifeOsSpacing.xl),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_isSaving ? '保存中…' : '保存今日状态'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.validator,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final FormFieldValidator<String> validator;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'^\d*\.?\d{0,2}') : RegExp(r'^\d*'),
        ),
      ],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: validator,
    );
  }
}

final class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: LifeOsSpacing.sm),
        Wrap(
          spacing: LifeOsSpacing.sm,
          runSpacing: LifeOsSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('暂不记录'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
            for (final value in values)
              ChoiceChip(
                label: Text(labelOf(value)),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}
