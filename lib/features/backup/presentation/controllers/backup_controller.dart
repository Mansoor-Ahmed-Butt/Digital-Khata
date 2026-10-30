import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/controllers/lock_controller.dart';
import '../../../settings/data/settings_store.dart';
import '../../domain/backup_service.dart';

/// Backup now / Restore (FR-09, local file version that works offline).
class BackupController extends GetxController {
  final BackupService _service = Get.find<BackupService>();
  final SettingsStore _store = Get.find<SettingsStore>();
  final LockController _lock = Get.find<LockController>();

  final Rxn<DateTime> lastBackupAt = Rxn<DateTime>();
  final RxBool isBackingUp = false.obs;
  final RxBool isRestoring = false.obs;

  @override
  void onInit() {
    super.onInit();
    lastBackupAt.value = _store.lastBackupAt;
  }

  Future<void> backupNow() async {
    if (isBackingUp.value) return;
    isBackingUp.value = true;
    try {
      final file = await _service.writeBackupFile();
      await _lock.external(() => Share.shareXFiles(
            <XFile>[XFile(file.path, mimeType: 'application/json')],
            subject: 'Digital Khata backup',
          ));
      final now = DateTime.now();
      await _store.setLastBackupAt(now);
      lastBackupAt.value = now;
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'backup');
      AppSnack.error('err_backup_failed');
    } finally {
      isBackingUp.value = false;
    }
  }

  Future<void> restore() async {
    if (isRestoring.value) return;
    isRestoring.value = true;
    try {
      final picked = await _lock.external(() => FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: <String>['json']));
      final path = (picked == null || picked.files.isEmpty) ? null : picked.files.first.path;
      if (path == null) return;

      final ok = await ConfirmDialog.show(
        titleKey: 'restore',
        messageKey: 'restore_confirm',
        confirmKey: 'restore',
        destructive: true,
      );
      if (!ok) return;

      final result = await guard<RestoreSummary>(() async {
        final raw = await _service.readFileSafely(File(path));
        return _service.restore(raw);
      });
      result.when(
        ok: (summary) => AppSnack.show('restore_done'.trParams(<String, String>{
          'customers': '${summary.customers}',
          'entries': '${summary.transactions}',
        })),
        err: (f) => AppSnack.error(f.messageKey),
      );
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'restore_pick');
      AppSnack.error('err_restore_failed');
    } finally {
      isRestoring.value = false;
    }
  }
}
