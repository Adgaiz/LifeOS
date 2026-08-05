import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/timeline/application/timeline_providers.dart';
import 'package:lifeos/features/timeline/domain/timeline_event.dart';

Future<void> openTimelineEditor(BuildContext context, {TimelineEvent? event}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => TimelineEditorPage(event: event),
      fullscreenDialog: true,
    ),
  );
}

final class TimelineEditorPage extends ConsumerStatefulWidget {
  const TimelineEditorPage({this.event, super.key});

  final TimelineEvent? event;

  @override
  ConsumerState<TimelineEditorPage> createState() => _TimelineEditorPageState();
}

final class _TimelineEditorPageState extends ConsumerState<TimelineEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late CalendarDate _occurredOn;
  late TimelineEventType _type;
  var _isDirty = false;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _occurredOn =
        event?.occurredOn ?? CalendarDate.fromDateTime(DateTime.now());
    _type = event?.type ?? TimelineEventType.milestone;
    _titleController.addListener(_markDirty);
    _descriptionController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
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
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _occurredOn.toLocalDateTime(),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '选择节点发生日期',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _occurredOn = CalendarDate.fromDateTime(selected);
      _isDirty = true;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(timelineServiceProvider)
          .save(
            TimelineEventInput(
              id: widget.event?.id,
              occurredOn: _occurredOn,
              type: _type,
              title: _titleController.text,
              description: _descriptionController.text,
            ),
          );
      _isDirty = false;
      if (mounted) Navigator.of(context).pop();
    } on TimelineValidationException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('人生节点暂时无法保存，请稍后重试');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop || !_isDirty) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃尚未保存的修改？'),
        content: const Text('离开后，本次修改不会保留。'),
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
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;
    return PopScope<Object?>(
      canPop: !_isDirty,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? '编辑人生节点' : '记录人生节点'),
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                LifeOsSpacing.lg,
                LifeOsSpacing.xl,
                LifeOsSpacing.lg,
                LifeOsSpacing.xxl,
              ),
              children: [
                Text(
                  '有些时刻，值得被认真记住。',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: LifeOsSpacing.xl),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_occurredOn.year} 年 ${_occurredOn.month} 月 ${_occurredOn.day} 日',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: LifeOsSpacing.lg,
                    ),
                  ),
                ),
                const SizedBox(height: LifeOsSpacing.lg),
                DropdownButtonFormField<TimelineEventType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: '节点类型'),
                  items: [
                    for (final type in TimelineEventType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _type = value;
                            _isDirty = true;
                          });
                        },
                ),
                const SizedBox(height: LifeOsSpacing.lg),
                TextFormField(
                  controller: _titleController,
                  enabled: !_isSaving,
                  maxLength: timelineMaximumTitleLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: '发生了什么？',
                    hintText: '例如：完成 LifeOS 第一版',
                  ),
                  validator: (value) {
                    final length = value?.trim().length ?? 0;
                    return length == 0 || length > timelineMaximumTitleLength
                        ? '请输入 1 到 80 个字符'
                        : null;
                  },
                ),
                const SizedBox(height: LifeOsSpacing.lg),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSaving,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: timelineMaximumDescriptionLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: '想留下的话（可选）',
                    hintText: '这件事为什么对你重要？当时有什么感受？',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    return (value?.trim().length ?? 0) >
                            timelineMaximumDescriptionLength
                        ? '最多输入 2000 个字符'
                        : null;
                  },
                ),
                const SizedBox(height: LifeOsSpacing.md),
                Text(
                  '首版只保存你主动记录的节点，不会自动从日记、目标或 AI 内容中生成。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
