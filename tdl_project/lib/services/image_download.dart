import 'dart:typed_data';

import 'image_download_stub.dart'
    if (dart.library.html) 'image_download_web.dart'
    as platform;

Future<void> downloadImage(Uint8List bytes) => platform.downloadImage(bytes);
