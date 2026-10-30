import 'package:flutter/material.dart';

/// Semantic colors from the design tokens that ColorScheme has no slot for.
@immutable
class KhataColors extends ThemeExtension<KhataColors> {
  const KhataColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.advance,
    required this.primaryTint,
    required this.primaryDark,
  });

  final Color success;
  final Color warning;
  final Color danger;

  /// Customer has paid more than owed (advance).
  final Color advance;
  final Color primaryTint;
  final Color primaryDark;

  static const KhataColors light = KhataColors(
    success: Color(0xFF2E7D32),
    warning: Color(0xFFF9A825),
    danger: Color(0xFFC62828),
    advance: Color(0xFF1565C0),
    primaryTint: Color(0xFFE3EDF7),
    primaryDark: Color(0xFF0E427D),
  );

  static const KhataColors dark = KhataColors(
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFCA28),
    danger: Color(0xFFEF5350),
    advance: Color(0xFF64A8F0),
    primaryTint: Color(0xFF1F2B3B),
    primaryDark: Color(0xFF0E427D),
  );

  @override
  KhataColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? advance,
    Color? primaryTint,
    Color? primaryDark,
  }) =>
      KhataColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        advance: advance ?? this.advance,
        primaryTint: primaryTint ?? this.primaryTint,
        primaryDark: primaryDark ?? this.primaryDark,
      );

  @override
  KhataColors lerp(ThemeExtension<KhataColors>? other, double t) {
    if (other is! KhataColors) return this;
    return KhataColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      advance: Color.lerp(advance, other.advance, t) ?? advance,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t) ?? primaryTint,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t) ?? primaryDark,
    );
  }
}

extension KhataThemeContext on BuildContext {
  /// Always non-null: both themes register the extension.
  KhataColors get khata => Theme.of(this).extension<KhataColors>() ?? KhataColors.light;
}
