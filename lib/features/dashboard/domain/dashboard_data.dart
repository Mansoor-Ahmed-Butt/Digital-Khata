import '../../customers/domain/customer.dart';
import '../../ledger/domain/ledger_transaction.dart';

class DashboardData {
  const DashboardData({
    this.totalReceivable = 0,
    this.todayCollection = 0,
    this.topDebtors = const <CustomerSummary>[],
    this.recent = const <RecentActivity>[],
    this.customerCount = 0,
  });

  /// Sum of every positive balance (advances are not netted off).
  final int totalReceivable;

  /// Payments received with today's date.
  final int todayCollection;

  /// Top 5 customers who owe the most.
  final List<CustomerSummary> topDebtors;
  final List<RecentActivity> recent;
  final int customerCount;

  /// Pure computation so it can be unit tested without a database.
  static DashboardData compute({
    required List<CustomerSummary> summaries,
    required int todayCollection,
    required List<RecentActivity> recent,
  }) {
    var total = 0;
    final debtors = <CustomerSummary>[];
    for (final s in summaries) {
      if (s.balance > 0) {
        total += s.balance;
        debtors.add(s);
      }
    }
    debtors.sort((a, b) => b.balance.compareTo(a.balance));
    return DashboardData(
      totalReceivable: total,
      todayCollection: todayCollection,
      topDebtors: debtors.take(5).toList(),
      recent: recent,
      customerCount: summaries.length,
    );
  }
}
