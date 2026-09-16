import 'dart:typed_data';

import 'package:gal/gal.dart';

Future<void> downloadImage(Uint8List bytes) async {
  final hasAccess = await Gal.requestAccess(toAlbum: true);
  if (!hasAccess) {
    throw StateError('gallery_permission_denied');
  }
  await Gal.putImageBytes(
    bytes,
    album: 'TDL',
    name: 'tdl_${DateTime.now().millisecondsSinceEpoch}',
  );
}
