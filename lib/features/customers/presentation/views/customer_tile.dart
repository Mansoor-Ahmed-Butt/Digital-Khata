import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/khata_card.dart';
import '../../../../core/widgets/money_widgets.dart';
import '../../../../core/widgets/shop_avatar.dart';
import '../../domain/customer.dart';

/// Avatar initial, name, subtitle and balance (red/green/blue + icon).
class CustomerTile extends StatelessWidget {
  const CustomerTile({super.key, required this.summary, required this.onTap, this.onLongPress});

  final CustomerSummary summary;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  String get _subtitle {
    if (summary.isAdvance) return 'advance'.tr;
    final last = summary.lastEntryDate;
    if (summary.isClear) {
      return last == null ? 'no_entries'.tr : 'settled_on'.trParams(<String, String>{'date': AppDates.short(last)});
    }
    return last == null
        ? 'no_entries'.tr
        : 'last_entry'.trParams(<String, String>{'date': AppDates.short(last)});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: KhataCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: <Widget>[
                ShopAvatar(name: summary.customer.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        summary.customer.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(_subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                BalanceDisplay(balance: summary.balance),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
