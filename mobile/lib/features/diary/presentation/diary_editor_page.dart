import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/diary/application/diary_providers.dart';
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/presentation/diary_content_widgets.dart';

const _diaryTemplate = '''## 今天发生了什么？


## 今天我的感受


## 今天值得记录


## 明天最重要的一件事

''';

Future<void> openDiaryEditor(
  BuildContext context, {
  DiaryAggregate? aggregate,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => DiaryEditorPage(aggregate: aggregate),
      fullscreenDialog: true,
    ),
  );
}

final class DiaryEditorPage extends ConsumerStatefulWidget {
  const DiaryEditorPage({this.aggregate, super.key});

  final DiaryAggregate? aggregate;

  @override
  ConsumerState<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

final class _DiaryEditorPageState extends ConsumerState<DiaryEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late final TextEditingController _markdownController;
  late final TextEditingController _tagsController;
  late CalendarDate _localDate;
  late final List<DiaryAttachment> _retainedAttachments;
  final List<StagedDiaryImage> _stagedImages = [];
  var _showPreview = false;
  var _isDirty = false;
  var _isSaving = false;
  var _isPickingImages = false;

  @override
  void initState() {
    super.initState();
    final aggregate = widget.aggregate;
    _localDate =
        aggregate?.entry.localDate ??
        CalendarDate.fromDateTime(ref.read(currentDateTimeProvider));
    _markdownController = TextEditingController(
      text: aggregate?.entry.markdown ?? '',
    )..addListener(_markDirty);
    _tagsController = TextEditingController(
      text: aggregate?.tags.map((tag) => tag.name).join('，') ?? '',
    )..addListener(_markDirty);
    _retainedAttachments = [...?aggregate?.attachments];
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recoverLostImages());
    }
  }

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _pickDate() async {
    if (widget.aggregate != null) {
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _localDate.toLocalDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _localDate = CalendarDate.fromDateTime(picked);
        _isDirty = true;
      });
    }
  }

  void _insertTemplate() {
    if (_markdownController.text.trim().isNotEmpty) {
      return;
    }
    _markdownController.text = _diaryTemplate;
    _markdownController.selection = TextSelection.collapsed(
      offset: _markdownController.text.length,
    );
  }

  Future<void> _pickImages() async {
    final remaining =
        diaryMaximumAttachments -
        _retainedAttachments.length -
        _stagedImages.length;
    if (remaining <= 0) {
      _showMessage('每篇日记最多添加 9 张图片');
      return;
    }
    setState(() => _isPickingImages = true);
    try {
      final selected = await _imagePicker.pickMultiImage(
        maxWidth: 4096,
        maxHeight: 4096,
        limit: remaining,
      );
      await _stageSelectedFiles(selected);
    } catch (_) {
      _showMessage('暂时无法读取图片，请检查系统照片权限后重试');
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  Future<void> _recoverLostImages() async {
    try {
      final response = await _imagePicker.retrieveLostData();
      if (!mounted || response.isEmpty) {
        return;
      }
      if (response.exception != null) {
        _showMessage('上次选择的图片未能恢复，请重新选择');
        return;
      }
      final files =
          response.files ?? [if (response.file != null) response.file!];
      if (files.isEmpty) {
        return;
      }
      setState(() => _isPickingImages = true);
      await _stageSelectedFiles(files);
      _showMessage('已恢复上次选择的图片');
    } catch (_) {
      // Recovery is best effort and must not block normal diary editing.
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  Future<void> _stageSelectedFiles(Iterable<XFile> files) async {
    for (final file in files) {
      if (_retainedAttachments.length + _stagedImages.length >=
          diaryMaximumAttachments) {
        _showMessage('每篇日记最多添加 9 张图片');
        return;
      }
      try {
        final staged = await ref
            .read(diaryServiceProvider)
            .stageImage(file.path);
        if (mounted) {
          setState(() {
            _stagedImages.add(staged);
            _isDirty = true;
          });
        }
      } on DiaryImageException catch (error) {
        _showMessage(error.message);
      }
    }
  }

  Future<void> _removeStaged(StagedDiaryImage image) async {
    setState(() {
      _stagedImages.remove(image);
      _isDirty = true;
    });
    await ref.read(diaryServiceProvider).discardStagedImage(image);
  }

  void _removeStored(DiaryAttachment attachment) {
    setState(() {
      _retainedAttachments.remove(attachment);
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
          .read(diaryServiceProvider)
          .save(
            DiaryInput(
              id: widget.aggregate?.entry.id,
              localDate: _localDate,
              markdown: _markdownController.text,
              tags: _parseTags(_tagsController.text),
              retainedAttachmentIds: _retainedAttachments
                  .map((attachment) => attachment.id)
                  .toList(growable: false),
            ),
            stagedImages: List.unmodifiable(_stagedImages),
          );
      _stagedImages.clear();
      _isDirty = false;
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DiaryDateConflictException {
      _showMessage('这一天已经有一篇日记，请编辑已有日记');
    } on DiaryValidationException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('日记暂时无法保存，请稍后重试');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<String> _parseTags(String value) => value
      .split(RegExp(r'[,，\n]'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handlePop(bool didPop, Object? result) async {
    if (didPop || !_isDirty) {
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃尚未保存的日记？'),
        content: const Text('离开后，本次正文、标签和新选择的图片不会保留。'),
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
      final staged = List<StagedDiaryImage>.of(_stagedImages);
      _stagedImages.clear();
      _isDirty = false;
      for (final image in staged) {
        await ref.read(diaryServiceProvider).discardStagedImage(image);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _markdownController
      ..removeListener(_markDirty)
      ..dispose();
    _tagsController
      ..removeListener(_markDirty)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.aggregate != null;
    final imageCount = _retainedAttachments.length + _stagedImages.length;
    return PopScope<Object?>(
      canPop: !_isDirty,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? '编辑日记' : '写日记'),
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
                LifeOsSpacing.md,
                LifeOsSpacing.lg,
                LifeOsSpacing.xxl,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: isEditing ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${_localDate.year}年${_localDate.month}月${_localDate.day}日',
                    ),
                  ),
                ),
                const SizedBox(height: LifeOsSpacing.md),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.edit_outlined),
                      label: Text('编辑'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.visibility_outlined),
                      label: Text('预览'),
                    ),
                  ],
                  selected: {_showPreview},
                  onSelectionChanged: (values) {
                    setState(() => _showPreview = values.single);
                  },
                ),
                const SizedBox(height: LifeOsSpacing.md),
                if (_showPreview)
                  Container(
                    constraints: const BoxConstraints(minHeight: 320),
                    padding: const EdgeInsets.all(LifeOsSpacing.lg),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(LifeOsRadii.card),
                    ),
                    child: _markdownController.text.trim().isEmpty
                        ? const Text('写下一些内容后，可以在这里预览 Markdown。')
                        : SafeDiaryMarkdown(markdown: _markdownController.text),
                  )
                else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _markdownController.text.trim().isEmpty
                          ? _insertTemplate
                          : null,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('使用每日日记模板'),
                    ),
                  ),
                  TextFormField(
                    controller: _markdownController,
                    autofocus: !isEditing,
                    minLines: 14,
                    maxLines: null,
                    maxLength: diaryMaximumMarkdownLength,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Markdown 正文',
                      hintText: '今天发生了什么？\n\n今天我有什么感受？',
                    ),
                    validator: (value) {
                      final length = value?.trim().length ?? 0;
                      return length == 0 || length > diaryMaximumMarkdownLength
                          ? '请输入 1 到 50000 个字符'
                          : null;
                    },
                  ),
                ],
                const SizedBox(height: LifeOsSpacing.xl),
                TextFormField(
                  controller: _tagsController,
                  maxLength: 220,
                  decoration: const InputDecoration(
                    labelText: '标签（可选）',
                    hintText: '成长，家人，旅行',
                    helperText: '使用逗号分隔，最多 10 个，每个不超过 20 个字符',
                  ),
                  validator: (value) {
                    final tags = _parseTags(value ?? '');
                    if (tags.length > diaryMaximumTags) {
                      return '最多添加 10 个标签';
                    }
                    if (tags.any((tag) => tag.length > diaryMaximumTagLength)) {
                      return '每个标签不能超过 20 个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: LifeOsSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '图片 · $imageCount/$diaryMaximumAttachments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          _isPickingImages ||
                              imageCount >= diaryMaximumAttachments
                          ? null
                          : _pickImages,
                      icon: _isPickingImages
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('添加图片'),
                    ),
                  ],
                ),
                Text(
                  '图片会压缩并移除定位信息后复制到应用私有目录；卸载应用会同时删除这些副本。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (imageCount > 0) ...[
                  const SizedBox(height: LifeOsSpacing.md),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: LifeOsSpacing.sm,
                    crossAxisSpacing: LifeOsSpacing.sm,
                    children: [
                      for (final attachment in _retainedAttachments)
                        _EditableImage(
                          relativePath: attachment.thumbnailRelativePath,
                          onDelete: () => _removeStored(attachment),
                        ),
                      for (final image in _stagedImages)
                        _EditableImage(
                          relativePath: image.thumbnailRelativePath,
                          onDelete: () => _removeStaged(image),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _EditableImage extends StatelessWidget {
  const _EditableImage({required this.relativePath, required this.onDelete});

  final String relativePath;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LifeOsRadii.control),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: DiaryStoredImage(relativePath: relativePath),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filledTonal(
              tooltip: '移除图片',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
