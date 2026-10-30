import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/pin_pad.dart';
import '../controllers/pin_pad_controller.dart';

/// Title, dots, error line and keypad. Used by the lock screen and PIN setup.
class PinEntryPanel extends GetView<PinPadController> {
  const PinEntryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final error = controller.errorText.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 16),
          Text(controller.titleKey.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: 20),
          PinDots(
            length: controller.length,
            filled: controller.pin.value.length,
            hasError: error != null,
          ),
          SizedBox(
            height: 44,
            child: Center(
              child: error == null
                  ? const SizedBox.shrink()
                  : Text(
                      error,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error),
                    ),
            ),
          ),
          PinPad(
            enabled: !controller.busy.value,
            onDigit: controller.onDigit,
            onBackspace: controller.onBackspace,
            onBiometric: controller.biometricOffered ? controller.tryBiometric : null,
          ),
          const SizedBox(height: 16),
        ],
      );
    });
  }
}
