enum TxnType { credit, payment }

/// A credit given to, or a payment received from, a customer.
/// (Named LedgerTransaction to avoid clashing with sqflite's Transaction.)
class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.txnDate,
    this.note,
    this.photoPath,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String customerId;
  final TxnType type;

  /// Paisa, always positive.
  final int amount;

  /// Date only (local midnight).
  final DateTime txnDate;
  final String? note;
  final String? photoPath;

  /// Effect on the customer's balance: credit adds, payment subtracts.
  int get signedAmount => type == TxnType.credit ? amount : -amount;
}

/// A transaction with the customer's balance right after it (for the timeline).
class LedgerEntry {
  const LedgerEntry({required this.transaction, required this.balanceAfter});

  final LedgerTransaction transaction;
  final int balanceAfter;
}

class RangeTotals {
  const RangeTotals({this.credit = 0, this.payment = 0});

  final int credit;
  final int payment;
}

class RecentActivity {
  const RecentActivity({required this.transaction, required this.customerName});

  final LedgerTransaction transaction;
  final String customerName;
}

/// Pure balance math (BR-01, BR-02).
class BalanceCalculator {
  BalanceCalculator._();

  static int balance(int openingBalance, Iterable<LedgerTransaction> transactions) {
    var total = openingBalance;
    for (final t in transactions) {
      if (t.isDeleted) continue;
      total += t.signedAmount;
    }
    return total;
  }

  /// Orders oldest-first (date, then creation time) and returns each entry
  /// with its running balance. The list is returned newest-first for display.
  static List<LedgerEntry> timeline(int openingBalance, Iterable<LedgerTransaction> transactions) {
    final sorted = transactions.where((t) => !t.isDeleted).toList()
      ..sort((a, b) {
        final byDate = a.txnDate.compareTo(b.txnDate);
        return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
      });
    var running = openingBalance;
    final entries = <LedgerEntry>[];
    for (final t in sorted) {
      running += t.signedAmount;
      entries.add(LedgerEntry(transaction: t, balanceAfter: running));
    }
    return entries.reversed.toList();
  }
}
