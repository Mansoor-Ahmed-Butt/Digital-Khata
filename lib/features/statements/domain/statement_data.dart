import '../../customers/domain/customer.dart';
import '../../ledger/domain/ledger_transaction.dart';

/// Everything needed to print a customer statement for a date range (FR-08).
class StatementData {
  const StatementData({
    required this.shopName,
    required this.customer,
    required this.from,
    required this.to,
    required this.openingBalance,
    required this.entries,
    required this.totalCredit,
    required this.totalPayment,
  });

  final String shopName;
  final Customer customer;
  final DateTime from;
  final DateTime to;

  /// Balance at the start of [from] (paisa).
  final int openingBalance;

  /// Transactions in range with running balances, oldest first.
  final List<LedgerEntry> entries;
  final int totalCredit;
  final int totalPayment;

  int get closingBalance => openingBalance + totalCredit - totalPayment;

  /// Pure assembly so the rules are unit tested without a database.
  static StatementData assemble({
    required String shopName,
    required Customer customer,
    required DateTime from,
    required DateTime to,
    required List<LedgerTransaction> allTransactions,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    var opening = customer.openingBalance;
    final inRange = <LedgerTransaction>[];
    for (final t in allTransactions) {
      if (t.isDeleted) continue;
      if (t.txnDate.isBefore(start)) {
        opening += t.signedAmount;
      } else if (!t.txnDate.isAfter(end)) {
        inRange.add(t);
      }
    }
    inRange.sort((a, b) {
      final byDate = a.txnDate.compareTo(b.txnDate);
      return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
    });

    var running = opening;
    var credit = 0;
    var payment = 0;
    final entries = <LedgerEntry>[];
    for (final t in inRange) {
      running += t.signedAmount;
      if (t.type == TxnType.credit) {
        credit += t.amount;
      } else {
        payment += t.amount;
      }
      entries.add(LedgerEntry(transaction: t, balanceAfter: running));
    }

    return StatementData(
      shopName: shopName,
      customer: customer,
      from: start,
      to: end,
      openingBalance: opening,
      entries: entries,
      totalCredit: credit,
      totalPayment: payment,
    );
  }
}
