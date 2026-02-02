import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStore {
  const ImageStore();

  Future<String> savePickedImageToAppDir(XFile picked) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final filename = 'img_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(imagesDir.path, filename);

    final srcFile = File(picked.path);
    final saved = await srcFile.copy(destPath);
    return saved.path;
  }
}
