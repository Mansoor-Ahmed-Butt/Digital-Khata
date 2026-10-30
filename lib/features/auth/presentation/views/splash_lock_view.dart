import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/khata_colors.dart';
import '../controllers/splash_controller.dart';
import 'pin_entry_panel.dart';

/// Splash and lock screen (5.1): logo header, PIN pad, fingerprint button.
class SplashLockView extends GetView<SplashController> {
  const SplashLockView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const BrandHeader(),
          Expanded(
            child: Obx(
              () => controller.showLock.value
                  ? const SingleChildScrollView(child: PinEntryPanel())
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blue gradient header with the "D" logo tile, name and tagline.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.khata;
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + (compact ? 16 : 28), 24, compact ? 20 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[theme.colorScheme.primary, colors.primaryDark],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: compact ? 52 : 64,
            height: compact ? 52 : 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'D',
              style: TextStyle(
                fontSize: compact ? 28 : 34,
                fontWeight: FontWeight.w700,
                color: colors.primaryDark,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'app_name'.tr,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'tagline'.tr,
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
