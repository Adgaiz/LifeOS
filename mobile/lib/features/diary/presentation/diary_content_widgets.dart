import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/features/diary/application/diary_providers.dart';

final class SafeDiaryMarkdown extends StatelessWidget {
  const SafeDiaryMarkdown({required this.markdown, super.key});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdown,
      selectable: true,
      imageBuilder: (uri, title, alt) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported_outlined),
            const SizedBox(width: 8),
            Flexible(child: Text(alt?.isNotEmpty ?? false ? alt! : '外部图片已阻止')),
          ],
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('为保护隐私，日记预览不会直接打开外部链接')));
        }
      },
    );
  }
}

final class DiaryStoredImage extends ConsumerWidget {
  const DiaryStoredImage({
    required this.relativePath,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String relativePath;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(diaryAttachmentPathProvider(relativePath))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Icon(Icons.broken_image_outlined)),
          data: (absolutePath) => Image.file(
            File(absolutePath),
            fit: fit,
            errorBuilder: (_, _, _) =>
                const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        );
  }
}
