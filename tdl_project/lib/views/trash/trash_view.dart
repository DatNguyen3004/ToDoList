import 'package:flutter/material.dart';

import '../../controllers/task_controller.dart';
import '../../models/task_item.dart';
import '../../widgets/drawing_preview.dart';
import '../../widgets/image_preview.dart';
import '../../widgets/rich_text_preview.dart';

const _deepBlue = Color(0xFF1976D2);
const _ink = Color(0xFF17324D);
const _mutedInk = Color(0xFF6F8192);

enum TrashViewMode { cards, list }

class TrashView extends StatefulWidget {
  const TrashView({required this.taskController, super.key});

  final TaskController taskController;

  @override
  State<TrashView> createState() => _TrashViewState();
}

class _TrashViewState extends State<TrashView> {
  TrashViewMode _viewMode = TrashViewMode.cards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thùng rác',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.taskController,
          builder: (context, _) {
            final tasks = widget.taskController.deletedTasks;
            if (tasks.isEmpty) return const _EmptyTrashState();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _TrashViewToggle(
                      viewMode: _viewMode,
                      onChanged: (mode) => setState(() => _viewMode = mode),
                    ),
                  ),
                ),
                Expanded(
                  child: _DeletedTaskCollection(
                    tasks: tasks,
                    viewMode: _viewMode,
                    onRestore: widget.taskController.restore,
                    onDeleteForever: widget.taskController.deleteForever,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TrashViewToggle extends StatelessWidget {
  const _TrashViewToggle({required this.viewMode, required this.onChanged});

  final TrashViewMode viewMode;
  final ValueChanged<TrashViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF3F6580)
        : const Color(0xFFB9DDFC);
    final selectedColor = isDark
        ? const Color(0xFF24445C)
        : const Color(0xFFDDEEFF);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrashViewButton(
            key: const Key('trash_cards_view_button'),
            icon: Icons.grid_view_rounded,
            tooltip: 'Xem dạng thẻ',
            selected: viewMode == TrashViewMode.cards,
            selectedColor: selectedColor,
            onPressed: () => onChanged(TrashViewMode.cards),
          ),
          Container(width: 1, color: borderColor),
          _TrashViewButton(
            key: const Key('trash_list_view_button'),
            icon: Icons.view_list_rounded,
            tooltip: 'Xem dạng danh sách',
            selected: viewMode == TrashViewMode.list,
            selectedColor: selectedColor,
            onPressed: () => onChanged(TrashViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _TrashViewButton extends StatelessWidget {
  const _TrashViewButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.selectedColor,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 44,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: _deepBlue,
          backgroundColor: selected ? selectedColor : Colors.transparent,
          shape: const RoundedRectangleBorder(),
        ),
        icon: Icon(icon, size: 21),
      ),
    );
  }
}

class _EmptyTrashState extends StatelessWidget {
  const _EmptyTrashState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFE6F3FF) : _ink;
    final subtitleColor = isDark ? const Color(0xFFA8C1D4) : _mutedInk;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B3447)
                    : const Color(0xFFE8F5FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: _deepBlue,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thùng rác đang trống',
              style: TextStyle(
                color: titleColor,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các công việc đã xóa sẽ được hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletedTaskCollection extends StatelessWidget {
  const _DeletedTaskCollection({
    required this.tasks,
    required this.viewMode,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final List<TaskItem> tasks;
  final TrashViewMode viewMode;
  final ValueChanged<String> onRestore;
  final ValueChanged<String> onDeleteForever;

  @override
  Widget build(BuildContext context) {
    if (viewMode == TrashViewMode.list) {
      return ListView.separated(
        key: const Key('trash_task_list'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return SizedBox(
            height: 190,
            child: _DeletedTaskCard(
              task: task,
              onRestore: () => onRestore(task.id),
              onDeleteForever: () => onDeleteForever(task.id),
            ),
          );
        },
      );
    }

    return GridView.builder(
      key: const Key('trash_task_grid'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 210,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _DeletedTaskCard(
          task: task,
          onRestore: () => onRestore(task.id),
          onDeleteForever: () => onDeleteForever(task.id),
        );
      },
    );
  }
}

class _DeletedTaskCard extends StatelessWidget {
  const _DeletedTaskCard({
    required this.task,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final TaskItem task;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  IconData get _contentIcon => switch (task.contentType) {
    TaskContentType.drawing => Icons.draw_rounded,
    TaskContentType.image => Icons.image_rounded,
    TaskContentType.text => Icons.notes_rounded,
  };

  Widget _contentPreview() {
    return switch (task.contentType) {
      TaskContentType.drawing => DrawingPreview(
        key: Key('trash_drawing_preview_${task.id}'),
        drawingJson: task.drawingJson,
      ),
      TaskContentType.image => ImagePreview(
        key: Key('trash_image_preview_${task.id}'),
        imageDataJson: task.imageDataJson,
      ),
      TaskContentType.text => Align(
        alignment: Alignment.topLeft,
        child: RichTextPreview(
          key: Key('trash_text_preview_${task.id}'),
          richTextJson: task.richTextJson,
          plainText: task.description,
          height: 82,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFE6F3FF) : _ink;
    final hasTitle = task.title.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172A3A) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isDark ? const Color(0xFF29485E) : const Color(0xFFCFE8FC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle)
            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (hasTitle) const SizedBox(height: 6),
          Expanded(child: _contentPreview()),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(_contentIcon, size: 17, color: _deepBlue),
              const Spacer(),
              IconButton(
                key: const Key('restore_task_button'),
                tooltip: 'Khôi phục',
                onPressed: onRestore,
                color: _deepBlue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 38,
                  height: 34,
                ),
                icon: const Icon(Icons.restore_rounded, size: 22),
              ),
              IconButton(
                key: const Key('delete_forever_button'),
                tooltip: 'Xóa vĩnh viễn',
                onPressed: () => _confirmDeleteForever(context),
                color: const Color(0xFFD14343),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 38,
                  height: 34,
                ),
                icon: const Icon(Icons.delete_forever_rounded, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteForever(BuildContext context) async {
    final taskName = task.title.trim().isEmpty
        ? 'Công việc này'
        : '“${task.title}”';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa vĩnh viễn?'),
        content: Text('$taskName sẽ bị xóa hoàn toàn và không thể khôi phục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('confirm_delete_forever_button'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD14343),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDeleteForever();
  }
}
