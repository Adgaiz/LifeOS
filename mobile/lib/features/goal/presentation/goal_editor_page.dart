import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/goal/application/goal_providers.dart';
import 'package:lifeos/features/goal/domain/goal.dart';
import 'package:lifeos/features/vision/application/vision_providers.dart';
import 'package:lifeos/features/vision/domain/vision.dart';

Future<void> openGoalEditor(BuildContext context, {GoalAggregate? aggregate}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => GoalEditorPage(aggregate: aggregate),
      fullscreenDialog: true,
    ),
  );
}

final class GoalEditorPage extends ConsumerStatefulWidget {
  const GoalEditorPage({this.aggregate, super.key});

  final GoalAggregate? aggregate;

  @override
  ConsumerState<GoalEditorPage> createState() => _GoalEditorPageState();
}

final class _GoalEditorPageState extends ConsumerState<GoalEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final List<_KeyResultDraftController> _keyResults = [];
  late CalendarDate _startDate;
  late CalendarDate _endDate;
  String? _visionId;
  var _isDirty = false;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final aggregate = widget.aggregate;
    final today = CalendarDate.fromDateTime(ref.read(currentDateTimeProvider));
    _titleController = TextEditingController(text: aggregate?.goal.title ?? '');
    _descriptionController = TextEditingController(
      text: aggregate?.goal.description ?? '',
    );
    _startDate = aggregate?.goal.startDate ?? today;
    _endDate = aggregate?.goal.endDate ?? today.addDays(89);
    _visionId = aggregate?.goal.visionId;
    final existingKeyResults = aggregate?.keyResults ?? const [];
    if (existingKeyResults.isEmpty) {
      _addKeyResult(markDirty: false);
    } else {
      for (final keyResult in existingKeyResults) {
        _keyResults.add(
          _KeyResultDraftController(
            id: keyResult.id,
            title: keyResult.title,
            progress: keyResult.progress,
            onChanged: _markDirty,
          ),
        );
      }
    }
    _titleController.addListener(_markDirty);
    _descriptionController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  void _addKeyResult({bool markDirty = true}) {
    setState(() {
      _keyResults.add(
        _KeyResultDraftController(progress: 0, onChanged: _markDirty),
      );
      if (markDirty) {
        _isDirty = true;
      }
    });
  }

  void _removeKeyResult(int index) {
    if (_keyResults.length == 1) {
      return;
    }
    setState(() {
      _keyResults.removeAt(index).dispose();
      _isDirty = true;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.toLocalDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      final date = CalendarDate.fromDateTime(picked);
      if (isStart) {
        _startDate = date;
        if (_endDate.compareTo(date) < 0) {
          _endDate = date.addDays(89);
        }
      } else {
        _endDate = date;
      }
      _isDirty = true;
    });
  }

  void _useNinetyDays() {
    setState(() {
      _endDate = _startDate.addDays(89);
      _isDirty = true;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(goalServiceProvider)
          .save(
            GoalInput(
              id: widget.aggregate?.goal.id,
              visionId: _visionId,
              title: _titleController.text,
              description: _descriptionController.text,
              startDate: _startDate,
              endDate: _endDate,
              keyResults: [
                for (final keyResult in _keyResults)
                  GoalKeyResultInput(
                    id: keyResult.id,
                    title: keyResult.titleController.text,
                    progress: keyResult.progress,
                  ),
              ],
            ),
          );
      _isDirty = false;
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on GoalValidationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('目标暂时无法保存，请稍后重试')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop || !_isDirty) {
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃尚未保存的修改？'),
        content: const Text('离开后，本次目标和关键结果修改不会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃修改'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _isDirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_markDirty)
      ..dispose();
    _descriptionController
      ..removeListener(_markDirty)
      ..dispose();
    for (final keyResult in _keyResults) {
      keyResult.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.aggregate != null;
    final visions = ref.watch(allVisionsProvider);
    return PopScope<Object?>(
      canPop: !_isDirty,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? '编辑目标' : '新的 90 天目标'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: LifeOsSpacing.sm),
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? '保存中…' : '保存'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                LifeOsSpacing.lg,
                LifeOsSpacing.lg,
                LifeOsSpacing.lg,
                LifeOsSpacing.xxl,
              ),
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '目标标题',
                    hintText: '例如：90 天恢复健康状态',
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    return length == 0 || length > 80 ? '请输入 1 到 80 个字符' : null;
                  },
                ),
                const SizedBox(height: LifeOsSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 2000,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: '为什么这件事重要？（可选）'),
                ),
                const SizedBox(height: LifeOsSpacing.md),
                visions.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('愿景暂时无法读取，可先不关联'),
                  data: (items) => _VisionSelector(
                    visions: items,
                    value: _visionId,
                    onChanged: (value) {
                      setState(() {
                        _visionId = value;
                        _isDirty = true;
                      });
                    },
                  ),
                ),
                const SizedBox(height: LifeOsSpacing.xl),
                Text('目标周期', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: LifeOsSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: '开始',
                        date: _startDate,
                        onPressed: () => _pickDate(isStart: true),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: LifeOsSpacing.sm,
                      ),
                      child: Icon(Icons.arrow_forward_rounded),
                    ),
                    Expanded(
                      child: _DateButton(
                        label: '结束',
                        date: _endDate,
                        onPressed: () => _pickDate(isStart: false),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _useNinetyDays,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      '使用 90 天模板 · 当前 ${_startDate.daysUntil(_endDate) + 1} 天',
                    ),
                  ),
                ),
                const SizedBox(height: LifeOsSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '关键结果',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addKeyResult,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('添加'),
                    ),
                  ],
                ),
                Text(
                  '用 0–100% 记录进度，目标总进度取所有关键结果的平均值。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: LifeOsSpacing.md),
                for (var index = 0; index < _keyResults.length; index++) ...[
                  _KeyResultEditor(
                    key: ValueKey(_keyResults[index]),
                    draft: _keyResults[index],
                    canDelete: _keyResults.length > 1,
                    onDelete: () => _removeKeyResult(index),
                    onProgressChanged: (value) {
                      setState(() {
                        _keyResults[index].progress = value;
                        _isDirty = true;
                      });
                    },
                  ),
                  if (index != _keyResults.length - 1)
                    const SizedBox(height: LifeOsSpacing.md),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _KeyResultDraftController {
  _KeyResultDraftController({
    required this.progress,
    required this.onChanged,
    this.id,
    String title = '',
  }) : titleController = TextEditingController(text: title) {
    titleController.addListener(onChanged);
  }

  final String? id;
  final TextEditingController titleController;
  final VoidCallback onChanged;
  int progress;

  void dispose() {
    titleController
      ..removeListener(onChanged)
      ..dispose();
  }
}

final class _VisionSelector extends StatelessWidget {
  const _VisionSelector({
    required this.visions,
    required this.value,
    required this.onChanged,
  });

  final List<Vision> visions;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: const InputDecoration(labelText: '关联人生愿景（可选）'),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('暂不关联')),
        for (final vision in visions)
          DropdownMenuItem<String?>(
            value: vision.id,
            child: Text(vision.title, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

final class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final CalendarDate date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: LifeOsSpacing.md),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: LifeOsSpacing.xs),
          Text('${date.year}.${date.month}.${date.day}'),
        ],
      ),
    );
  }
}

final class _KeyResultEditor extends StatelessWidget {
  const _KeyResultEditor({
    required this.draft,
    required this.canDelete,
    required this.onDelete,
    required this.onProgressChanged,
    super.key,
  });

  final _KeyResultDraftController draft;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<int> onProgressChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.md),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.titleController,
                    maxLength: 120,
                    decoration: const InputDecoration(
                      labelText: '关键结果',
                      hintText: '例如：每周运动 3 次',
                    ),
                    validator: (value) {
                      final length = value?.trim().length ?? 0;
                      return length == 0 || length > 120
                          ? '请输入 1 到 120 个字符'
                          : null;
                    },
                  ),
                ),
                IconButton(
                  tooltip: '删除关键结果',
                  onPressed: canDelete ? onDelete : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: draft.progress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${draft.progress}%',
                    onChanged: (value) => onProgressChanged(value.round()),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${draft.progress}%',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
