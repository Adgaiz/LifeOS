import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/vision/application/vision_providers.dart';
import 'package:lifeos/features/vision/domain/vision.dart';

Future<void> openVisionEditor(BuildContext context, {Vision? vision}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => VisionEditorPage(vision: vision),
      fullscreenDialog: true,
    ),
  );
}

final class VisionEditorPage extends ConsumerStatefulWidget {
  const VisionEditorPage({this.vision, super.key});

  final Vision? vision;

  @override
  ConsumerState<VisionEditorPage> createState() => _VisionEditorPageState();
}

final class _VisionEditorPageState extends ConsumerState<VisionEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  var _isDirty = false;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.vision?.title ?? '');
    _contentController = TextEditingController(
      text: widget.vision?.content ?? '',
    );
    _titleController.addListener(_markDirty);
    _contentController.addListener(_markDirty);
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
    _contentController
      ..removeListener(_markDirty)
      ..dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(visionServiceProvider)
          .save(
            VisionInput(
              id: widget.vision?.id,
              title: _titleController.text,
              content: _contentController.text,
            ),
          );
      _isDirty = false;
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on VisionValidationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('愿景暂时无法保存，请稍后重试')));
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
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vision != null;
    return PopScope<Object?>(
      canPop: !_isDirty,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? '编辑愿景' : '新的愿景'),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              LifeOsSpacing.lg,
              LifeOsSpacing.lg,
              LifeOsSpacing.lg,
              LifeOsSpacing.xl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    autofocus: !isEditing,
                    maxLength: 80,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '愿景标题',
                      hintText: '例如：30 岁的我',
                    ),
                    validator: (value) {
                      final length = value?.trim().length ?? 0;
                      return length == 0 || length > 80
                          ? '请输入 1 到 80 个字符'
                          : null;
                    },
                  ),
                  const SizedBox(height: LifeOsSpacing.lg),
                  Text(
                    '我想成为怎样的人？',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: LifeOsSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _contentController,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      maxLength: 5000,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        hintText: '写下你向往的生活、重视的关系，以及希望保有的状态。',
                      ),
                      validator: (value) {
                        final length = value?.trim().length ?? 0;
                        return length == 0 || length > 5000
                            ? '请输入 1 到 5000 个字符'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
