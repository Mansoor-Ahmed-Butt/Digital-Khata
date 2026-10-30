import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Row of dots showing how many PIN digits were typed.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, required this.filled, this.hasError = false});

  final int length;
  final int filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = hasError ? scheme.error : scheme.primary;
    return Semantics(
      label: 'a11y_pin_progress'.trParams(<String, String>{'n': '$filled', 'total': '$length'}),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(length, (i) {
          final isFilled = i < filled;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? active : Colors.transparent,
              border: Border.all(color: active, width: 2),
            ),
          );
        }),
      ),
    );
  }
}

/// 3x4 numeric keypad. Always left-to-right, even in RTL layouts.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final row in const <List<String>>[
            <String>['1', '2', '3'],
            <String>['4', '5', '6'],
            <String>['7', '8', '9'],
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[for (final d in row) _digit(context, d)],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (onBiometric != null)
                _key(
                  context,
                  child: const Icon(Icons.fingerprint, size: 30),
                  label: 'use_fingerprint'.tr,
                  onTap: enabled ? onBiometric : null,
                )
              else
                const SizedBox(width: 88, height: 80),
              _digit(context, '0'),
              _key(
                context,
                child: const Icon(Icons.backspace_outlined, size: 26),
                label: 'a11y_backspace'.tr,
                onTap: enabled ? onBackspace : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _digit(BuildContext context, String d) => _key(
        context,
        child: Text(d, style: Theme.of(context).textTheme.titleLarge),
        label: d,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onDigit(d);
              }
            : null,
      );

  Widget _key(BuildContext context,
      {required Widget child, required String label, required VoidCallback? onTap}) {
    return SizedBox(
      width: 88,
      height: 80,
      child: Center(
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: onTap,
            radius: 40,
            child: SizedBox(width: 64, height: 64, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}
