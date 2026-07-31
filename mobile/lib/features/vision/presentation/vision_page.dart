import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/app/navigation/lifeos_scaffold.dart';
import 'package:lifeos/core/ui/design_tokens.dart';
import 'package:lifeos/features/vision/application/vision_providers.dart';
import 'package:lifeos/features/vision/domain/vision.dart';
import 'package:lifeos/features/vision/presentation/vision_editor_page.dart';

final class VisionPage extends ConsumerWidget {
  const VisionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visions = ref.watch(allVisionsProvider);
    return LifeOsScaffold(
      selectedIndex: 1,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openVisionEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新愿景'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allVisionsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LifeOsSpacing.lg,
              LifeOsSpacing.xl,
              LifeOsSpacing.lg,
              104,
            ),
            children: [
              const _VisionHeader(),
              const SizedBox(height: LifeOsSpacing.xl),
              visions.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _VisionLoadError(
                  onRetry: () => ref.invalidate(allVisionsProvider),
                ),
                data: (items) => _VisionContent(visions: items),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _VisionHeader extends StatelessWidget {
  const _VisionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '人生愿景',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: LifeOsSpacing.xs),
        Text(
          '我想成为怎样的人？',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

final class _VisionContent extends StatelessWidget {
  const _VisionContent({required this.visions});

  final List<Vision> visions;

  @override
  Widget build(BuildContext context) {
    final active = visions
        .where((vision) => vision.status == VisionStatus.active)
        .toList(growable: false);
    final archived = visions
        .where((vision) => vision.status == VisionStatus.archived)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isEmpty)
          const _EmptyVision()
        else ...[
          for (var index = 0; index < active.length; index++) ...[
            _VisionCard(vision: active[index]),
            if (index != active.length - 1)
              const SizedBox(height: LifeOsSpacing.md),
          ],
        ],
        if (archived.isNotEmpty) ...[
          const SizedBox(height: LifeOsSpacing.xl),
          _ArchivedVisions(visions: archived),
        ],
      ],
    );
  }
}

enum _VisionMenuAction { edit, archive, restore, delete }

final class _VisionCard extends ConsumerWidget {
  const _VisionCard({required this.vision});

  final Vision vision;

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _VisionMenuAction action,
  ) async {
    try {
      switch (action) {
        case _VisionMenuAction.edit:
          await openVisionEditor(context, vision: vision);
          return;
        case _VisionMenuAction.archive:
          await ref.read(visionServiceProvider).archive(vision.id);
          return;
        case _VisionMenuAction.restore:
          await ref.read(visionServiceProvider).restore(vision.id);
          return;
        case _VisionMenuAction.delete:
          await _confirmDelete(context, ref);
          return;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('愿景暂时无法更新，请稍后重试')));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这个愿景？'),
        content: const Text('删除后，它将不再出现在愿景列表中。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(visionServiceProvider).delete(vision.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(LifeOsRadii.card),
        onTap: () => openVisionEditor(context, vision: vision),
        child: Padding(
          padding: const EdgeInsets.all(LifeOsSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      vision.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  PopupMenuButton<_VisionMenuAction>(
                    tooltip: '愿景操作',
                    onSelected: (action) => _handleAction(context, ref, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: _VisionMenuAction.edit,
                        child: Text('编辑'),
                      ),
                      if (vision.status == VisionStatus.active)
                        const PopupMenuItem(
                          value: _VisionMenuAction.archive,
                          child: Text('归档'),
                        )
                      else
                        const PopupMenuItem(
                          value: _VisionMenuAction.restore,
                          child: Text('恢复'),
                        ),
                      const PopupMenuItem(
                        value: _VisionMenuAction.delete,
                        child: Text('删除'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: LifeOsSpacing.sm),
              Text(
                vision.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LifeOsSpacing.md),
              Row(
                children: [
                  Icon(
                    vision.status == VisionStatus.active
                        ? Icons.explore_outlined
                        : Icons.archive_outlined,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: LifeOsSpacing.xs),
                  Text(
                    vision.status.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '更新于 ${_formatDate(vision.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}.${local.month}.${local.day}';
  }
}

final class _ArchivedVisions extends StatelessWidget {
  const _ArchivedVisions({required this.visions});

  final List<Vision> visions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text('已归档愿景（${visions.length}）'),
        childrenPadding: const EdgeInsets.fromLTRB(
          LifeOsSpacing.md,
          0,
          LifeOsSpacing.md,
          LifeOsSpacing.md,
        ),
        children: [
          for (var index = 0; index < visions.length; index++) ...[
            _VisionCard(vision: visions[index]),
            if (index != visions.length - 1)
              const SizedBox(height: LifeOsSpacing.sm),
          ],
        ],
      ),
    );
  }
}

final class _EmptyVision extends StatelessWidget {
  const _EmptyVision();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LifeOsSpacing.xl,
          vertical: LifeOsSpacing.xxl,
        ),
        child: Column(
          children: [
            Icon(
              Icons.explore_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: LifeOsSpacing.md),
            Text('给未来一个方向', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: LifeOsSpacing.sm),
            Text(
              '愿景不是必须完成的清单，\n而是你愿意反复靠近的生活。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LifeOsSpacing.xl),
            FilledButton.tonalIcon(
              onPressed: () => openVisionEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('写下第一个愿景'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _VisionLoadError extends StatelessWidget {
  const _VisionLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LifeOsSpacing.xl),
        child: Column(
          children: [
            const Text('愿景暂时无法读取'),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
