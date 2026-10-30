import 'package:flutter/material.dart';

import '../../app/theme/khata_colors.dart';

class ShopAvatar extends StatelessWidget {
  const ShopAvatar({super.key, required this.name, this.radius = 22});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
    final colors = context.khata;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: colors.primaryTint,
        foregroundColor: Theme.of(context).brightness == Brightness.light
            ? colors.primaryDark
            : Theme.of(context).colorScheme.primary,
        child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
    );
  }
}
