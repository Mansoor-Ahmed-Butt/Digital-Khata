import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../errors/failure.dart';
import '../utils/ids.dart';

/// Picks a bill photo and copies it into app storage so it survives cache clears.
class PhotoStorage {
  final ImagePicker _picker = ImagePicker();

  /// Returns the stored path, or null if the user cancelled.
  Future<String?> pick(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
    if (picked == null) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'bill_photos'));
      if (!await folder.exists()) await folder.create(recursive: true);
      final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
      final target = p.join(folder.path, '${newId()}$ext');
      await File(picked.path).copy(target);
      return target;
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'photo_copy');
      throw const Failure('err_photo_failed');
    }
  }
}
