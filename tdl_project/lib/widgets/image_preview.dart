import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  const ImagePreview({required this.imageDataJson, super.key});

  final String? imageDataJson;

  List<Uint8List> _decodeImages() {
    final source = imageDataJson;
    if (source == null || source.isEmpty) return const [];
    try {
      final encodedImages = (jsonDecode(source) as List<dynamic>)
          .cast<String>();
      return encodedImages.map(base64Decode).toList();
    } on FormatException {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _decodeImages();
    if (images.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF90CAF9), size: 30),
      );
    }

    final shownImages = images.take(4).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: shownImages.length == 1 ? 1 : 2,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: shownImages.length == 2 ? 0.9 : 1.35,
        ),
        itemCount: shownImages.length,
        itemBuilder: (context, index) {
          final remaining = images.length - shownImages.length;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                shownImages[index],
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
              if (index == shownImages.length - 1 && remaining > 0)
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
