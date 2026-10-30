import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfirmDialog {
  ConfirmDialog._();

  /// Returns true only when the user explicitly confirms.
  static Future<bool> show({
    required String titleKey,
    required String messageKey,
    String confirmKey = 'confirm',
    bool destructive = false,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(titleKey.tr),
        content: Text(messageKey.tr),
        actions: <Widget>[
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(
                confirmKey.tr,
                style: destructive
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
