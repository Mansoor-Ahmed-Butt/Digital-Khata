import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pin_pad_controller.dart';
import 'pin_entry_panel.dart';

/// PIN creation / verification screen opened from onboarding and settings.
class PinSetupView extends GetView<PinPadController> {
  const PinSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('lock_settings'.tr),
        actions: <Widget>[
          if (controller.fromOnboarding)
            TextButton(onPressed: controller.skip, child: Text('skip_for_now'.tr)),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('pin_setup_hint'.tr, textAlign: TextAlign.center),
                ),
                const PinEntryPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
