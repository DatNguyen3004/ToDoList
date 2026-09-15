import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class RichTextPreview extends StatefulWidget {
  const RichTextPreview({
    required this.richTextJson,
    required this.plainText,
    this.height = 44,
    super.key,
  });

  final String? richTextJson;
  final String? plainText;
  final double height;

  @override
  State<RichTextPreview> createState() => _RichTextPreviewState();
}

class _RichTextPreviewState extends State<RichTextPreview> {
  late QuillController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(canRequestFocus: false);
    _controller = _createController();
  }

  @override
  void didUpdateWidget(covariant RichTextPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.richTextJson != widget.richTextJson ||
        oldWidget.plainText != widget.plainText) {
      final oldController = _controller;
      _controller = _createController();
      oldController.dispose();
    }
  }

  QuillController _createController() {
    return QuillController(
      document: _loadDocument(),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  Document _loadDocument() {
    final richTextJson = widget.richTextJson;
    if (richTextJson != null && richTextJson.isNotEmpty) {
      try {
        return Document.fromJson(jsonDecode(richTextJson) as List<dynamic>);
      } on FormatException {
        // Use the plain-text fallback for notes saved by older app versions.
      }
    }

    final text = widget.plainText?.trim();
    return Document.fromJson([
      {'insert': '${text ?? ''}\n'},
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRect(
        child: IgnorePointer(
          child: QuillEditor.basic(
            controller: _controller,
            focusNode: _focusNode,
            config: const QuillEditorConfig(
              scrollable: false,
              showCursor: false,
              enableInteractiveSelection: false,
              enableSelectionToolbar: false,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
