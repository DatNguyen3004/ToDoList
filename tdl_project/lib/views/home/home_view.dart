import 'package:flutter/material.dart';

import '../../models/task_item.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/drawing_preview.dart';
import '../../widgets/google_logo.dart';
import '../../widgets/image_preview.dart';
import '../../widgets/rich_text_preview.dart';

const _deepBlue = Color(0xFF1976D2);
const _ink = Color(0xFF17324D);
const _mutedInk = Color(0xFF6F8192);

enum TaskViewMode { cards, list }

enum TaskSortOption { date, name }

class HomeView extends StatefulWidget {
  const HomeView({
    required this.isSignedIn,
    required this.onGoogleSignIn,
    required this.onSignOut,
    required this.onThemeChanged,
    required this.onOpenTrash,
    required this.onCreateDrawing,
    required this.onCreateText,
    required this.onCreateImage,
    required this.tasks,
    required this.onDeleteTask,
    required this.onOpenTask,
    this.userPhotoUrl,
    this.displayName,
    this.email,
    super.key,
  });

  final bool isSignedIn;
  final String? userPhotoUrl;
  final String? displayName;
  final String? email;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onSignOut;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onOpenTrash;
  final VoidCallback onCreateDrawing;
  final VoidCallback onCreateText;
  final VoidCallback onCreateImage;
  final List<TaskItem> tasks;
  final ValueChanged<String> onDeleteTask;
  final ValueChanged<String> onOpenTask;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _searchController = TextEditingController();
  TaskViewMode _viewMode = TaskViewMode.cards;
  TaskSortOption _sortOption = TaskSortOption.date;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAccountPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _AccountPanel(
        isSignedIn: widget.isSignedIn,
        userPhotoUrl: widget.userPhotoUrl,
        displayName: widget.displayName,
        email: widget.email,
        onThemeChanged: widget.onThemeChanged,
        onGoogleSignIn: () {
          Navigator.pop(sheetContext);
          widget.onGoogleSignIn();
        },
        onSignOut: () {
          Navigator.pop(sheetContext);
          widget.onSignOut();
        },
      ),
    );
  }

  void _openCreateTaskPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _CreateTaskPanel(
        onCreateDrawing: () {
          Navigator.pop(sheetContext);
          widget.onCreateDrawing();
        },
        onCreateText: () {
          Navigator.pop(sheetContext);
          widget.onCreateText();
        },
        onCreateImage: () {
          Navigator.pop(sheetContext);
          widget.onCreateImage();
        },
      ),
    );
  }

  List<TaskItem> _visibleTasks() {
    final query = _searchController.text.trim().toLowerCase();
    final tasks = widget.tasks
        .where((task) => task.title.toLowerCase().contains(query))
        .toList();

    if (_sortOption == TaskSortOption.name) {
      tasks.sort(
        (first, second) =>
            first.title.toLowerCase().compareTo(second.title.toLowerCase()),
      );
    } else {
      tasks.sort(
        (first, second) => second.updatedAt.compareTo(first.updatedAt),
      );
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleTasks = _visibleTasks();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: BrandLogo(
                            key: Key('home_brand_logo'),
                            size: 54,
                          ),
                        ),
                        const _HomeTitle(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            key: const Key('account_avatar_button'),
                            onTap: () => _openAccountPanel(context),
                            customBorder: const CircleBorder(),
                            child: _AccountAvatar(
                              isSignedIn: widget.isSignedIn,
                              photoUrl: widget.userPhotoUrl,
                              size: 46,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('task_search_field'),
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tiêu đề...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa tìm kiếm',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF172A3A)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF29485E)
                              : const Color(0xFFCFE8FC),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TaskToolbar(
                    viewMode: _viewMode,
                    sortOption: _sortOption,
                    onViewModeChanged: (value) {
                      setState(() => _viewMode = value);
                    },
                    onSortChanged: (value) {
                      setState(() => _sortOption = value);
                    },
                    onOpenTrash: widget.onOpenTrash,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: visibleTasks.isEmpty
                        ? _EmptyTaskState(
                            isSearching: _searchController.text
                                .trim()
                                .isNotEmpty,
                          )
                        : _TaskCollection(
                            tasks: visibleTasks,
                            viewMode: _viewMode,
                            onDeleteTask: widget.onDeleteTask,
                            onOpenTask: widget.onOpenTask,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_task_button'),
        onPressed: () => _openCreateTaskPanel(context),
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm công việc',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'TDL',
      key: Key('home_title'),
      style: TextStyle(
        color: _deepBlue,
        fontSize: 27,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        shadows: [
          Shadow(color: _deepBlue, offset: Offset(-0.8, 0)),
          Shadow(color: _deepBlue, offset: Offset(0.8, 0)),
          Shadow(color: _deepBlue, offset: Offset(0, -0.8)),
          Shadow(color: _deepBlue, offset: Offset(0, 0.8)),
          Shadow(color: _deepBlue, offset: Offset(-0.6, -0.6)),
          Shadow(color: _deepBlue, offset: Offset(0.6, -0.6)),
          Shadow(color: _deepBlue, offset: Offset(-0.6, 0.6)),
          Shadow(color: _deepBlue, offset: Offset(0.6, 0.6)),
        ],
      ),
    );
  }
}

class _CreateTaskPanel extends StatelessWidget {
  const _CreateTaskPanel({
    required this.onCreateDrawing,
    required this.onCreateText,
    required this.onCreateImage,
  });

  final VoidCallback onCreateDrawing;
  final VoidCallback onCreateText;
  final VoidCallback onCreateImage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFE6F3FF) : _ink;
    final subtitleColor = isDark ? const Color(0xFFA8C1D4) : _mutedInk;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF152837) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A5366)
                      : const Color(0xFFDCE6EE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thêm công việc',
              style: TextStyle(
                color: titleColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Chọn cách bạn muốn tạo nội dung.',
              style: TextStyle(color: subtitleColor, height: 1.4),
            ),
            const SizedBox(height: 20),
            _CreateTaskOption(
              key: const Key('create_drawing_option'),
              icon: Icons.draw_rounded,
              title: 'Bản vẽ',
              description: 'Phác thảo nhanh ý tưởng bằng nét vẽ.',
              color: const Color(0xFF7C6CE7),
              onTap: onCreateDrawing,
            ),
            const SizedBox(height: 10),
            _CreateTaskOption(
              key: const Key('create_text_option'),
              icon: Icons.notes_rounded,
              title: 'Văn bản',
              description: 'Tạo công việc bằng tiêu đề và ghi chú.',
              color: _deepBlue,
              onTap: onCreateText,
            ),
            const SizedBox(height: 10),
            _CreateTaskOption(
              key: const Key('create_image_option'),
              icon: Icons.add_photo_alternate_rounded,
              title: 'Hình ảnh',
              description: 'Chọn hình ảnh có sẵn từ thiết bị.',
              color: const Color(0xFF21A179),
              onTap: onCreateImage,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTaskOption extends StatelessWidget {
  const _CreateTaskOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1B3447) : const Color(0xFFF7FBFF),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFE6F3FF) : _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFA8C1D4) : _mutedInk,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? const Color(0xFF7892A5)
                    : const Color(0xFF91A8BA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskToolbar extends StatelessWidget {
  const _TaskToolbar({
    required this.viewMode,
    required this.sortOption,
    required this.onViewModeChanged,
    required this.onSortChanged,
    required this.onOpenTrash,
  });

  final TaskViewMode viewMode;
  final TaskSortOption sortOption;
  final ValueChanged<TaskViewMode> onViewModeChanged;
  final ValueChanged<TaskSortOption> onSortChanged;
  final VoidCallback onOpenTrash;

  @override
  Widget build(BuildContext context) {
    final sortControl = PopupMenuButton<TaskSortOption>(
      key: const Key('sort_tasks_button'),
      initialValue: sortOption,
      tooltip: 'Sắp xếp công việc',
      onSelected: onSortChanged,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: TaskSortOption.date,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_today_outlined),
            title: Text('Theo ngày'),
          ),
        ),
        PopupMenuItem(
          value: TaskSortOption.name,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.sort_by_alpha_rounded),
            title: Text('Theo tên'),
          ),
        ),
      ],
      child: _ToolContainer(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 20),
            const SizedBox(width: 7),
            Text(sortOption == TaskSortOption.date ? 'Theo ngày' : 'Theo tên'),
            const SizedBox(width: 3),
            const Icon(Icons.arrow_drop_down_rounded, size: 20),
          ],
        ),
      ),
    );

    final viewControl = SegmentedButton<TaskViewMode>(
      key: const Key('task_view_mode_button'),
      segments: const [
        ButtonSegment(
          value: TaskViewMode.cards,
          icon: Icon(Icons.grid_view_rounded),
          tooltip: 'Kiểu thẻ',
        ),
        ButtonSegment(
          value: TaskViewMode.list,
          icon: Icon(Icons.view_list_rounded),
          tooltip: 'Kiểu danh sách',
        ),
      ],
      selected: {viewMode},
      showSelectedIcon: false,
      onSelectionChanged: (values) => onViewModeChanged(values.first),
      style: ButtonStyle(
        visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF9CCFFF)
              : _deepBlue,
        ),
        side: WidgetStatePropertyAll(
          BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF29485E)
                : const Color(0xFFCFE8FC),
          ),
        ),
      ),
    );

    final trailingControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('trash_button'),
          onPressed: onOpenTrash,
          tooltip: 'Thùng rác',
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF9CCFFF)
                : _deepBlue,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A3042)
                : const Color(0xFFE8F5FF),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
        const SizedBox(width: 8),
        viewControl,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: sortControl),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: trailingControls),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [sortControl, trailingControls],
        );
      },
    );
  }
}

class _ToolContainer extends StatelessWidget {
  const _ToolContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172A3A) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isDark ? const Color(0xFF29485E) : const Color(0xFFCFE8FC),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: isDark ? const Color(0xFFCAE7FF) : _deepBlue,
          fontWeight: FontWeight.w700,
        ),
        child: IconTheme(
          data: IconThemeData(
            color: isDark ? const Color(0xFF9CCFFF) : _deepBlue,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyTaskState extends StatelessWidget {
  const _EmptyTaskState({this.isSearching = false});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 48,
                color: Color(0xFF70B9F6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching
                  ? 'Không tìm thấy công việc'
                  : 'Chưa có công việc nào',
              style: TextStyle(
                color: isDark ? const Color(0xFFE6F3FF) : _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Hãy thử một tiêu đề hoặc từ khóa khác.'
                  : 'Hãy tạo công việc đầu tiên để bắt đầu ngày mới.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFFA8C1D4) : _mutedInk,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCollection extends StatelessWidget {
  const _TaskCollection({
    required this.tasks,
    required this.viewMode,
    required this.onDeleteTask,
    required this.onOpenTask,
  });

  final List<TaskItem> tasks;
  final TaskViewMode viewMode;
  final ValueChanged<String> onDeleteTask;
  final ValueChanged<String> onOpenTask;

  @override
  Widget build(BuildContext context) {
    if (viewMode == TaskViewMode.list) {
      return ListView.separated(
        padding: const EdgeInsets.only(top: 6, bottom: 24),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) => SizedBox(
          height: 164,
          child: _TaskTile(
            task: tasks[index],
            onDelete: () => onDeleteTask(tasks[index].id),
            onOpen: () => onOpenTask(tasks[index].id),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 184,
      ),
      itemCount: tasks.length,
      itemBuilder: (_, index) => _TaskTile(
        task: tasks[index],
        onDelete: () => onDeleteTask(tasks[index].id),
        onOpen: () => onOpenTask(tasks[index].id),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onDelete,
    required this.onOpen,
  });

  final TaskItem task;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$hour:$minute • $day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFE6F3FF) : _ink;
    final subtitleColor = isDark ? const Color(0xFFA8C1D4) : _mutedInk;

    return Material(
      color: isDark ? const Color(0xFF172A3A) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('open_task_${task.id}'),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF29485E) : const Color(0xFFCFE8FC),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.title.isNotEmpty)
                        Text(
                          task.title,
                          key: Key('task_title_${task.id}'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (task.contentType == TaskContentType.drawing) ...[
                        if (task.title.isNotEmpty) const SizedBox(height: 6),
                        Expanded(
                          child: DrawingPreview(
                            key: Key('drawing_preview_${task.id}'),
                            drawingJson: task.drawingJson,
                          ),
                        ),
                        const SizedBox(height: 7),
                      ] else if (task.contentType == TaskContentType.image) ...[
                        if (task.title.isNotEmpty) const SizedBox(height: 6),
                        Expanded(
                          child: ImagePreview(
                            key: Key('image_preview_${task.id}'),
                            imageDataJson: task.imageDataJson,
                          ),
                        ),
                        const SizedBox(height: 7),
                      ] else ...[
                        if (task.description != null) ...[
                          if (task.title.isNotEmpty) const SizedBox(height: 5),
                          RichTextPreview(
                            key: Key('task_preview_${task.id}'),
                            richTextJson: task.richTextJson,
                            plainText: task.description,
                            height: task.title.isEmpty ? 70 : 48,
                          ),
                        ],
                        const Spacer(),
                      ],
                      Row(
                        children: [
                          Icon(
                            task.contentType == TaskContentType.drawing
                                ? Icons.draw_rounded
                                : task.contentType == TaskContentType.image
                                ? Icons.image_rounded
                                : Icons.notes_rounded,
                            size: 16,
                            color: _deepBlue,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: subtitleColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDateTime(task.updatedAt),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('delete_task_button'),
                            onPressed: () => _confirmMoveToTrash(context),
                            tooltip: 'Chuyển vào thùng rác',
                            color: isDark ? const Color(0xFF9CCFFF) : _deepBlue,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 28,
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmMoveToTrash(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: Text('“${task.title}” sẽ được chuyển vào thùng rác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: const Key('confirm_delete_task_button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({
    required this.isSignedIn,
    required this.photoUrl,
    required this.size,
  });

  final bool isSignedIn;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = isSignedIn && photoUrl != null && photoUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4FF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB9DDFC), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.person_rounded, color: _deepBlue),
            )
          : const Icon(Icons.person_rounded, color: _deepBlue),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({
    required this.isSignedIn,
    required this.userPhotoUrl,
    required this.displayName,
    required this.email,
    required this.onThemeChanged,
    required this.onGoogleSignIn,
    required this.onSignOut,
  });

  final bool isSignedIn;
  final String? userPhotoUrl;
  final String? displayName;
  final String? email;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF152837) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6EE),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 22),
            _AccountAvatar(
              isSignedIn: isSignedIn,
              photoUrl: userPhotoUrl,
              size: 66,
            ),
            const SizedBox(height: 14),
            Text(
              isSignedIn ? (displayName ?? 'Tài khoản Google') : 'Chế độ khách',
              style: TextStyle(
                color: isDark ? const Color(0xFFE6F3FF) : _ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isSignedIn
                  ? (email ?? 'Dữ liệu đang được đồng bộ')
                  : 'Dữ liệu hiện chỉ được lưu trên thiết bị này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFFA8C1D4) : _mutedInk,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Material(
              color: isDark ? const Color(0xFF1B3447) : const Color(0xFFF0F8FF),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile.adaptive(
                key: const Key('theme_mode_switch'),
                value: isDark,
                onChanged: onThemeChanged,
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: _deepBlue,
                ),
                title: const Text(
                  'Chế độ tối',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
            const SizedBox(height: 18),
            if (!isSignedIn)
              FilledButton(
                key: const Key('home_google_sign_in_button'),
                onPressed: onGoogleSignIn,
                style: FilledButton.styleFrom(
                  backgroundColor: _deepBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoogleLogo(),
                    SizedBox(width: 12),
                    Text('Đăng nhập bằng Google'),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                key: const Key('sign_out_button'),
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Đăng xuất'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD14343),
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: Color(0xFFF0B8B8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
