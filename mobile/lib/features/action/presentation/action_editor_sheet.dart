import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/action/application/action_providers.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/goal/application/goal_providers.dart';
import 'package:lifeos/features/goal/domain/goal.dart';

Future<void> showActionEditorSheet({
  required BuildContext context,
  required CalendarDate date,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ActionEditorSheet(date: date),
  );
}

final class _ActionEditorSheet extends ConsumerStatefulWidget {
  const _ActionEditorSheet({required this.date});

  final CalendarDate date;

  @override
  ConsumerState<_ActionEditorSheet> createState() => _ActionEditorSheetState();
}

final class _ActionEditorSheetState extends ConsumerState<_ActionEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _minimumController = TextEditingController();
  ActionCategory _category = ActionCategory.life;
  String? _goalId;
  var _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _minimumController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(actionServiceProvider)
          .add(
            localDate: widget.date,
            title: _titleController.text,
            category: _category,
            minimumAction: _minimumController.text,
            goalId: _goalId,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ActionValidationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂时无法添加行动，请稍后重试')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(allGoalsProvider);
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
            Text('添加今日行动', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: LifeOsSpacing.xs),
            Text(
              '从一个真正做得到的动作开始。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LifeOsSpacing.xl),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              maxLength: 80,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '想完成什么？',
                hintText: '例如：跑步 5 公里',
              ),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                return length == 0 || length > 80 ? '请输入 1 到 80 个字符' : null;
              },
            ),
            const SizedBox(height: LifeOsSpacing.md),
            DropdownButtonFormField<ActionCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: '分类'),
              items: [
                for (final category in ActionCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: LifeOsSpacing.md),
            goals.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('目标暂时无法读取，可先不关联'),
              data: (items) {
                final active = items
                    .where(
                      (aggregate) => aggregate.goal.status == GoalStatus.active,
                    )
                    .toList(growable: false);
                return DropdownButtonFormField<String?>(
                  initialValue: _goalId,
                  decoration: const InputDecoration(labelText: '关联 90 天目标（可选）'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('暂不关联'),
                    ),
                    for (final aggregate in active)
                      DropdownMenuItem<String?>(
                        value: aggregate.goal.id,
                        child: Text(
                          aggregate.goal.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _goalId = value),
                );
              },
            ),
            const SizedBox(height: LifeOsSpacing.md),
            TextFormField(
              controller: _minimumController,
              maxLength: 120,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '最低行动（可选）',
                hintText: '例如：散步 10 分钟',
                helperText: '状态不佳时，保留一个温和的起点。',
              ),
              validator: (value) =>
                  (value?.trim().length ?? 0) > 120 ? '最低行动不能超过 120 个字符' : null,
            ),
            const SizedBox(height: LifeOsSpacing.xl),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(_isSaving ? '添加中…' : '添加到今天'),
            ),
          ],
        ),
      ),
    );
  }
}
