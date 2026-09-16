import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../models/task_item.dart';

const _primaryBlue = Color(0xFF1976D2);

class TextTaskDraft {
  const TextTaskDraft({
    required this.title,
    required this.richTextJson,
    this.description,
  });

  final String title;
  final String? description;
  final String richTextJson;
}

class TextTaskView extends StatefulWidget {
  const TextTaskView({
    required this.onSave,
    this.initialTask,
    this.onDeleteEmpty,
    super.key,
  });

  final TaskItem? initialTask;
  final ValueChanged<TextTaskDraft> onSave;
  final VoidCallback? onDeleteEmpty;

  @override
  State<TextTaskView> createState() => _TextTaskViewState();
}

class _TextTaskViewState extends State<TextTaskView> {
  late final TextEditingController _titleController;
  late final QuillController _contentController;
  late final FocusNode _contentFocusNode;
  bool _canPop = false;
  bool _isClosing = false;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTask?.title);
    _contentFocusNode = FocusNode(debugLabel: 'text-task-content');
    _contentController = QuillController(
      document: _loadDocument(widget.initialTask),
      selection: const TextSelection.collapsed(offset: 0),
      onReplaceText: _handleContentReplacement,
    );
  }

  Document _loadDocument(TaskItem? task) {
    final richTextJson = task?.richTextJson;
    if (richTextJson != null && richTextJson.isNotEmpty) {
      try {
        return Document.fromJson(jsonDecode(richTextJson) as List<dynamic>);
      } on FormatException {
        // Falls back to the plain text saved by older versions of the app.
      }
    }

    final plainText = task?.description;
    if (plainText != null && plainText.isNotEmpty) {
      return Document.fromJson([
        {'insert': '$plainText\n'},
      ]);
    }
    return Document.fromJson(const [
      {'insert': '\n'},
    ]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentFocusNode.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _handleContentReplacement(int index, int length, Object? data) {
    if (length <= 0) return true;

    final replacedStyle = _contentController.document.collectStyle(
      index,
      length,
    );
    final replacedColor = replacedStyle.attributes[Attribute.color.key]?.value
        ?.toString();
    final colorAttribute = ColorAttribute(replacedColor);

    // A replacement must inherit the color of the removed text, not the
    // differently colored character immediately after the selection.
    _contentController.toggledStyle = _contentController.toggledStyle.put(
      colorAttribute,
    );

    if (data is String && data.isEmpty) {
      scheduleMicrotask(() {
        if (!mounted) return;
        _contentController.forceToggledStyle(
          _contentController.toggledStyle.put(colorAttribute),
        );
      });
    }
    return true;
  }

  void _save() {
    final rawTitle = _titleController.text.trim();
    final description = _contentController.document.toPlainText().trim();

    if (rawTitle.isEmpty && description.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Hãy nhập nội dung để lưu.')),
        );
      return;
    }

    widget.onSave(
      TextTaskDraft(
        title: rawTitle,
        description: description.isEmpty ? null : description,
        richTextJson: jsonEncode(
          _contentController.document.toDelta().toJson(),
        ),
      ),
    );
    _closePage();
  }

  void _handleBack() {
    if (_isClosing) return;

    final hasTitle = _titleController.text.trim().isNotEmpty;
    final hasContent = _contentController.document
        .toPlainText()
        .trim()
        .isNotEmpty;
    if (hasTitle || hasContent) {
      _save();
    } else {
      if (_isEditing) widget.onDeleteEmpty?.call();
      _closePage();
    }
  }

  void _closePage() {
    if (_isClosing) return;
    _isClosing = true;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark
        ? const Color(0xFFEAF5FF)
        : const Color(0xFF17324D);
    final secondaryText = isDark
        ? const Color(0xFFA8C1D4)
        : const Color(0xFF6F8192);

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            _isEditing ? 'Chỉnh sửa ghi chú' : 'Ghi chú mới',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            FilledButton(
              key: const Key('save_text_task_button'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('text_task_title_field'),
                  controller: _titleController,
                  autofocus: !_isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _contentFocusNode.requestFocus(),
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Tiêu đề',
                    hintStyle: TextStyle(
                      color: secondaryText.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _contentFocusNode.requestFocus,
                    child: QuillEditor.basic(
                      key: const Key('text_task_description_field'),
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      config: QuillEditorConfig(
                        placeholder: 'Bắt đầu viết ghi chú...',
                        autoFocus: false,
                        expands: true,
                        padding: EdgeInsets.zero,
                        keyboardAppearance: isDark
                            ? Brightness.dark
                            : Brightness.light,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: isDark
                      ? const Color(0xFF172A3A)
                      : const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(15),
                  clipBehavior: Clip.antiAlias,
                  child: _FormattingToolbar(
                    key: const Key('rich_text_toolbar'),
                    controller: _contentController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormattingToolbar extends StatelessWidget {
  const _FormattingToolbar({required this.controller, super.key});

  final QuillController controller;

  @override
  Widget build(BuildContext context) {
    final normalColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEAF5FF)
        : const Color(0xFF202124);
    final iconTheme = QuillIconTheme(
      iconButtonUnselectedData: IconButtonData(
        color: normalColor,
        disabledColor: const Color(0xFF9AA0A6),
        style: IconButton.styleFrom(
          foregroundColor: normalColor,
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
        ),
      ),
      iconButtonSelectedData: IconButtonData(
        color: Colors.white,
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _primaryBlue,
          shape: const CircleBorder(),
        ),
      ),
    );
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          _ToolbarSlot(
            child: QuillToolbarHistoryButton(
              key: const Key('undo_edit_button'),
              controller: controller,
              isUndo: true,
              options: QuillToolbarHistoryButtonOptions(iconTheme: iconTheme),
            ),
          ),
          _ToolbarSlot(
            child: QuillToolbarHistoryButton(
              key: const Key('redo_edit_button'),
              controller: controller,
              isUndo: false,
              options: QuillToolbarHistoryButtonOptions(iconTheme: iconTheme),
            ),
          ),
          _ToolbarSlot(
            child: QuillToolbarToggleStyleButton(
              key: const Key('bold_format_button'),
              controller: controller,
              attribute: Attribute.bold,
              options: QuillToolbarToggleStyleButtonOptions(
                iconTheme: iconTheme,
              ),
            ),
          ),
          _ToolbarSlot(
            child: QuillToolbarToggleStyleButton(
              key: const Key('italic_format_button'),
              controller: controller,
              attribute: Attribute.italic,
              options: QuillToolbarToggleStyleButtonOptions(
                iconTheme: iconTheme,
              ),
            ),
          ),
          _ToolbarSlot(
            child: QuillToolbarToggleStyleButton(
              key: const Key('underline_format_button'),
              controller: controller,
              attribute: Attribute.underline,
              options: QuillToolbarToggleStyleButtonOptions(
                iconTheme: iconTheme,
              ),
            ),
          ),
          _ToolbarSlot(
            child: QuillToolbarToggleStyleButton(
              key: const Key('strike_format_button'),
              controller: controller,
              attribute: Attribute.strikeThrough,
              options: QuillToolbarToggleStyleButtonOptions(
                iconTheme: iconTheme,
              ),
            ),
          ),
          _ToolbarSlot(
            child: IconButton(
              key: const Key('text_color_button'),
              tooltip: 'Màu chữ',
              onPressed: () => _showTextColorPicker(context),
              color: normalColor,
              icon: const Icon(Icons.format_color_text_rounded),
            ),
          ),
          _ToolbarSlot(
            child: QuillToolbarToggleStyleButton(
              key: const Key('bullet_list_format_button'),
              controller: controller,
              attribute: Attribute.ul,
              options: QuillToolbarToggleStyleButtonOptions(
                iconTheme: iconTheme,
              ),
            ),
          ),
          _ToolbarSlot(
            child: QuillToolbarToggleStyleButton(
              key: const Key('number_list_format_button'),
              controller: controller,
              attribute: Attribute.ol,
              options: QuillToolbarToggleStyleButtonOptions(
                iconTheme: iconTheme,
              ),
            ),
          ),
          _ToolbarSlot(
            child: QuillToolbarClearFormatButton(
              key: const Key('clear_format_button'),
              controller: controller,
              options: QuillToolbarClearFormatButtonOptions(
                iconTheme: iconTheme,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTextColorPicker(BuildContext context) async {
    final originalSelection = controller.selection;
    final currentColor =
        controller
            .getSelectionStyle()
            .attributes[Attribute.color.key]
            ?.value
            ?.toString()
            .toUpperCase() ??
        '';
    final selectedColor = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) => _TextColorPicker(selectedColor: currentColor),
    );

    if (selectedColor == null) return;
    controller.formatSelection(
      selectedColor.isEmpty
          ? const ColorAttribute(null)
          : ColorAttribute(selectedColor),
    );

    if (!originalSelection.isCollapsed) {
      controller.updateSelection(
        TextSelection.collapsed(offset: originalSelection.end),
        ChangeSource.local,
      );
      controller.formatSelection(const ColorAttribute(null));
    }
  }
}

class _ToolbarSlot extends StatelessWidget {
  const _ToolbarSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      ),
    );
  }
}

class _TextColorPicker extends StatelessWidget {
  const _TextColorPicker({required this.selectedColor});

  final String selectedColor;

  static const colors = <(Color, String)>[
    (Color(0xFFEF4444), '#EF4444'),
    (Color(0xFFF97316), '#F97316'),
    (Color(0xFFEAB308), '#EAB308'),
    (Color(0xFF22C55E), '#22C55E'),
    (Color(0xFF2196F3), '#2196F3'),
    (Color(0xFF6366F1), '#6366F1'),
    (Color(0xFFA855F7), '#A855F7'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Màu chữ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8,
              runSpacing: 10,
              children: [
                _ColorChoice(
                  key: const Key('text_color_default'),
                  color: Theme.of(context).colorScheme.onSurface,
                  isSelected: selectedColor.isEmpty,
                  selectionColor: Theme.of(context).colorScheme.primary,
                  onTap: () => Navigator.pop(context, ''),
                  child: const Icon(Icons.format_color_reset_rounded),
                ),
                for (final entry in colors)
                  _ColorChoice(
                    key: Key('text_color_${entry.$2.substring(1)}'),
                    color: entry.$1,
                    isSelected: selectedColor == entry.$2,
                    onTap: () => Navigator.pop(context, entry.$2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.color,
    required this.onTap,
    required this.isSelected,
    this.selectionColor,
    this.child,
    super.key,
  });

  final Color color;
  final VoidCallback onTap;
  final bool isSelected;
  final Color? selectionColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        key: isSelected
            ? Key(
                'selected_text_color_${child == null ? color.toARGB32() : 'default'}',
              )
            : null,
        duration: const Duration(milliseconds: 160),
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: selectionColor ?? color, width: 2)
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: child == null ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
