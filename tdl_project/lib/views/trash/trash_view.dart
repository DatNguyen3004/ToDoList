import 'package:flutter/material.dart';

import '../../controllers/task_controller.dart';
import '../../models/task_item.dart';
import '../../widgets/rich_text_preview.dart';

const _deepBlue = Color(0xFF1976D2);
const _ink = Color(0xFF17324D);
const _mutedInk = Color(0xFF6F8192);

class TrashView extends StatelessWidget {
  const TrashView({required this.taskController, super.key});

  final TaskController taskController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thùng rác',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: taskController,
          builder: (context, _) {
            final tasks = taskController.deletedTasks;
            return tasks.isEmpty
                ? const _EmptyTrashState()
                : _DeletedTaskGrid(
                    tasks: tasks,
                    onRestore: taskController.restore,
                    onDeleteForever: taskController.deleteForever,
                  );
          },
        ),
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

class _DeletedTaskGrid extends StatelessWidget {
  const _DeletedTaskGrid({
    required this.tasks,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final List<TaskItem> tasks;
  final ValueChanged<String> onRestore;
  final ValueChanged<String> onDeleteForever;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      key: const Key('trash_task_grid'),
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 172,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFE6F3FF) : _ink;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
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
          if (task.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 5),
            RichTextPreview(
              richTextJson: task.richTextJson,
              plainText: task.description,
              height: 55,
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                key: const Key('restore_task_button'),
                tooltip: 'Khôi phục',
                onPressed: onRestore,
                icon: const Icon(Icons.restore_rounded, color: _deepBlue),
              ),
              IconButton(
                key: const Key('delete_forever_button'),
                tooltip: 'Xóa vĩnh viễn',
                onPressed: () => _confirmDeleteForever(context),
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFD14343),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteForever(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa vĩnh viễn?'),
        content: Text(
          '“${task.title}” sẽ bị xóa hoàn toàn và không thể khôi phục.',
        ),
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
