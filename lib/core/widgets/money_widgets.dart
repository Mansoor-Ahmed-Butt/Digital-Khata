import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/theme/khata_colors.dart';
import '../utils/money.dart';

/// "Rs 4,500" - formats paisa with the localized currency symbol.
class MoneyText extends StatelessWidget {
  const MoneyText(this.paisa, {super.key, this.style, this.color});

  final int paisa;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge;
    return Text(
      Money.withSymbol(paisa, 'currency'.tr),
      style: color == null ? base : base?.copyWith(color: color),
      textDirection: TextDirection.ltr,
    );
  }
}

/// Balance with color AND icon AND text, never color alone (C1):
/// owed = red + minus, cleared = green + check, advance = blue + plus.
class BalanceDisplay extends StatelessWidget {
  const BalanceDisplay({super.key, required this.balance, this.large = false});

  final int balance;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = context.khata;
    final theme = Theme.of(context);
    final Color color;
    final IconData icon;
    final String semantic;
    if (balance > 0) {
      color = colors.danger;
      icon = Icons.remove_circle_outline;
      semantic = 'a11y_owes';
    } else if (balance < 0) {
      color = colors.advance;
      icon = Icons.add_circle_outline;
      semantic = 'a11y_advance';
    } else {
      color = colors.success;
      icon = Icons.check_circle_outline;
      semantic = 'a11y_clear';
    }
    final amount = Money.withSymbol(balance.abs(), 'currency'.tr);
    final style = (large ? theme.textTheme.displaySmall : theme.textTheme.titleMedium)
        ?.copyWith(color: color);
    return Semantics(
      label: '${semantic.tr} $amount',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: large ? 28 : 18),
          const SizedBox(width: 4),
          Flexible(
            child: Text(amount, style: style, textDirection: TextDirection.ltr),
          ),
        ],
      ),
    );
  }
}

/// Text field for rupee amounts. Accepts Latin and Urdu digits.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.allowNegative = false,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool allowNegative;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: textInputAction,
      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: allowNegative),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
          RegExp(allowNegative ? r'[0-9\u0660-\u0669\u06F0-\u06F9.,\-]' : r'[0-9\u0660-\u0669\u06F0-\u06F9.,]'),
        ),
        LengthLimitingTextInputFormatter(16),
      ],
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: const Icon(Icons.payments_outlined),
      ),
    );
  }
}
