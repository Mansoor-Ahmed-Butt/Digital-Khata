import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Snackbars through ScaffoldMessenger (registered on GetMaterialApp), which
/// is safer than overlay-based snackbars and supports an Undo action (C8).
class AppSnack {
  AppSnack._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: isError ? const Color(0xFFB3261E) : null,
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction ?? () {},
                ),
        ),
      );
  }

  static void showKey(String key,
      {bool isError = false, String? actionKey, VoidCallback? onAction}) {
    show(key.tr,
        isError: isError, actionLabel: actionKey?.tr, onAction: onAction);
  }

  static void error(String key) => showKey(key, isError: true);
}
