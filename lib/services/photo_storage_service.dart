import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Copies a picked image into the app's private documents folder under a
/// stable, unique filename, so it survives even if the original picked
/// file (e.g. a camera temp file) gets cleaned up by the OS later.
class PhotoStorageService {
  static const _uuid = Uuid();

  Future<String> saveMedicinePhoto(File sourceFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'medicine_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final extension = p.extension(sourceFile.path).isNotEmpty ? p.extension(sourceFile.path) : '.jpg';
    final fileName = '${_uuid.v4()}$extension';
    final savedPath = p.join(photosDir.path, fileName);

    await sourceFile.copy(savedPath);
    return savedPath;
  }

  Future<void> deletePhoto(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
