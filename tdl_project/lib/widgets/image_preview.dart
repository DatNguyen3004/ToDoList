import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImagePreview extends StatefulWidget {
  const ImagePreview({required this.imageDataJson, super.key});

  final String? imageDataJson;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  static const _cacheLimit = 12;
  static final LinkedHashMap<String, _CachedImagePreview> _cache =
      LinkedHashMap();

  late List<Uint8List> _shownImages;
  late int _totalImageCount;

  @override
  void initState() {
    super.initState();
    _decodeImages();
  }

  @override
  void didUpdateWidget(covariant ImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageDataJson != widget.imageDataJson) _decodeImages();
  }

  void _decodeImages() {
    final source = widget.imageDataJson;
    _shownImages = const [];
    _totalImageCount = 0;
    if (source == null || source.isEmpty) return;

    final cached = _cache.remove(source);
    if (cached != null) {
      _cache[source] = cached;
      _shownImages = cached.images;
      _totalImageCount = cached.totalCount;
      return;
    }
    try {
      final encodedImages = (jsonDecode(source) as List<dynamic>)
          .cast<String>();
      _totalImageCount = encodedImages.length;
      _shownImages = encodedImages.take(4).map(base64Decode).toList();
      _cache[source] = _CachedImagePreview(
        images: _shownImages,
        totalCount: _totalImageCount,
      );
      if (_cache.length > _cacheLimit) _cache.remove(_cache.keys.first);
    } on Object {
      _shownImages = const [];
      _totalImageCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shownImages.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF90CAF9), size: 30),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _shownImages.length == 1 ? 1 : 2,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: _shownImages.length == 2 ? 0.9 : 1.35,
        ),
        itemCount: _shownImages.length,
        itemBuilder: (context, index) {
          final remaining = _totalImageCount - _shownImages.length;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                _shownImages[index],
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: 640,
              ),
              if (index == _shownImages.length - 1 && remaining > 0)
                ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CachedImagePreview {
  const _CachedImagePreview({required this.images, required this.totalCount});

  final List<Uint8List> images;
  final int totalCount;
}
