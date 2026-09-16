import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/task_item.dart';
import '../../services/image_download.dart';

const _primaryBlue = Color(0xFF1976D2);

class ImageTaskDraft {
  const ImageTaskDraft({
    required this.title,
    required this.imageDataJson,
    this.description,
  });

  final String title;
  final String? description;
  final String imageDataJson;
}

class ImageTaskView extends StatefulWidget {
  const ImageTaskView({
    required this.onSave,
    this.initialTask,
    this.onDeleteEmpty,
    this.pickImages,
    super.key,
  });

  final TaskItem? initialTask;
  final ValueChanged<ImageTaskDraft> onSave;
  final VoidCallback? onDeleteEmpty;
  final Future<List<Uint8List>> Function()? pickImages;

  @override
  State<ImageTaskView> createState() => _ImageTaskViewState();
}

class _ImageTaskViewState extends State<ImageTaskView> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final List<Uint8List> _images = [];
  final List<List<Uint8List>> _undoImages = [];
  final List<List<Uint8List>> _redoImages = [];
  bool _isPicking = false;
  bool _canPop = false;
  bool _isClosing = false;

  bool get _isEditing => widget.initialTask != null;
  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _contentController.text.trim().isNotEmpty ||
      _images.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTask?.title);
    _contentController = TextEditingController(
      text: widget.initialTask?.description,
    );
    _loadImages(widget.initialTask?.imageDataJson);
  }

  void _loadImages(String? imageDataJson) {
    if (imageDataJson == null || imageDataJson.isEmpty) return;
    try {
      final encodedImages = (jsonDecode(imageDataJson) as List<dynamic>)
          .cast<String>();
      _images.addAll(encodedImages.map(base64Decode));
    } on FormatException {
      // Ignore invalid image data from an unfinished older version.
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final pickedImages = widget.pickImages != null
          ? await widget.pickImages!()
          : await _pickFromDevice();
      if (!mounted || pickedImages.isEmpty) return;
      setState(() {
        _saveImageHistory();
        _images.addAll(pickedImages);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Không thể mở thư viện ảnh. Hãy thử lại.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _saveImageHistory() {
    _undoImages.add(_images.map(Uint8List.fromList).toList());
    _redoImages.clear();
  }

  void _restoreImageState(List<Uint8List> state) {
    _images
      ..clear()
      ..addAll(state.map(Uint8List.fromList));
  }

  void _undo() {
    if (_undoImages.isEmpty) return;
    setState(() {
      _redoImages.add(_images.map(Uint8List.fromList).toList());
      _restoreImageState(_undoImages.removeLast());
    });
  }

  void _redo() {
    if (_redoImages.isEmpty) return;
    setState(() {
      _undoImages.add(_images.map(Uint8List.fromList).toList());
      _restoreImageState(_redoImages.removeLast());
    });
  }

  Future<void> _openImageViewer(int initialIndex) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            _ImageViewer(images: _images, initialIndex: initialIndex),
      ),
    );
  }

  Future<List<Uint8List>> _pickFromDevice() async {
    final files = await ImagePicker().pickMultiImage(
      imageQuality: 88,
      requestFullMetadata: false,
    );
    return Future.wait(files.map((file) => file.readAsBytes()));
  }

  void _save({bool clearHistory = true}) {
    if (!_hasContent) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Hãy nhập nội dung để lưu.')),
        );
      return;
    }

    final description = _contentController.text.trim();
    widget.onSave(
      ImageTaskDraft(
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        imageDataJson: jsonEncode(_images.map(base64Encode).toList()),
      ),
    );
    if (clearHistory) {
      _undoImages.clear();
      _redoImages.clear();
    }
    _closePage();
  }

  void _handleBack() {
    if (_isClosing) return;
    if (_hasContent) {
      _save(clearHistory: false);
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
            _isEditing ? 'Chỉnh sửa hình ảnh' : 'Ghi nhớ hình ảnh',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              key: const Key('image_undo_button'),
              tooltip: 'Hoàn tác',
              onPressed: _undoImages.isEmpty ? null : _undo,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              key: const Key('image_redo_button'),
              tooltip: 'Làm lại',
              onPressed: _redoImages.isEmpty ? null : _redo,
              icon: const Icon(Icons.redo_rounded),
            ),
            FilledButton(
              key: const Key('save_image_task_button'),
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
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('image_task_title_field'),
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tiêu đề',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF172A3A)
                          : const Color(0xFFF0F8FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: _images.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.photo_library_outlined,
                                  size: 54,
                                  color: Color(0xFF64B5F6),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Chọn những hình ảnh cần ghi nhớ',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                _PickImagesButton(
                                  isPicking: _isPicking,
                                  onPressed: _pickImages,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: GridView.builder(
                                  key: const Key('selected_image_grid'),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 7,
                                        mainAxisSpacing: 7,
                                      ),
                                  itemCount: _images.length,
                                  itemBuilder: (context, index) => Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _openImageViewer(index),
                                        child: Hero(
                                          tag: 'tdl-image-$index',
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.memory(
                                              _images[index],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 3,
                                        right: 3,
                                        child: IconButton.filled(
                                          key: Key('remove_image_$index'),
                                          tooltip: 'Bỏ ảnh',
                                          onPressed: () => setState(() {
                                            _saveImageHistory();
                                            _images.removeAt(index);
                                          }),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black54,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(30, 30),
                                            padding: EdgeInsets.zero,
                                          ),
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PickImagesButton(
                                isPicking: _isPicking,
                                onPressed: _pickImages,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('image_task_content_field'),
                  controller: _contentController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Nội dung ghi nhớ...',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF172A3A)
                        : const Color(0xFFF0F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
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

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.images, required this.initialIndex});

  final List<Uint8List> images;
  final int initialIndex;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _downloadCurrent() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      await downloadImage(widget.images[_currentIndex]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu ảnh vào thư viện.')),
        );
      }
    } on StateError catch (error) {
      if (mounted) {
        final message = error.message == 'gallery_permission_denied'
            ? 'Chưa được cấp quyền lưu ảnh vào thư viện.'
            : 'Không thể lưu ảnh vào thư viện.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lưu ảnh vào thư viện.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1}/${widget.images.length}'),
        actions: [
          IconButton(
            key: const Key('download_image_button'),
            tooltip: 'Tải ảnh về thiết bị',
            onPressed: _isDownloading ? null : _downloadCurrent,
            icon: _isDownloading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (_, index) => Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Hero(
              tag: 'tdl-image-$index',
              child: Image.memory(widget.images[index], fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickImagesButton extends StatelessWidget {
  const _PickImagesButton({required this.isPicking, required this.onPressed});

  final bool isPicking;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const Key('pick_images_button'),
      onPressed: isPicking ? null : onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: isPicking
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_photo_alternate_outlined),
      label: Text(isPicking ? 'Đang mở...' : 'Chọn ảnh từ thư viện'),
    );
  }
}
