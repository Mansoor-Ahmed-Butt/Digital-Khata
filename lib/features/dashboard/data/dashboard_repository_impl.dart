import '../../../core/database/app_database.dart';
import '../../../core/database/row_reader.dart';
import '../../../core/utils/app_dates.dart';
import '../../customers/data/customers_repository_impl.dart';
import '../../ledger/data/transactions_repository_impl.dart';
import '../../ledger/domain/ledger_transaction.dart';
import '../domain/dashboard_data.dart';
import '../domain/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Stream<DashboardData> watch() => _database.watch(_load);

  Future<DashboardData> _load() async {
    final db = _database.db;
    final summaries = await queryCustomerSummaries(db);

    final today = AppDates.toDbDate(AppDates.today());
    final collectionRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) AS total FROM transactions "
      "WHERE is_deleted = 0 AND type = 'payment' AND txn_date = ?",
      [today],
    );
    final collection =
        collectionRows.isEmpty ? 0 : collectionRows.first.integer('total', fallback: 0);

    final recentRows = await db.rawQuery('''
SELECT t.*, c.name AS customer_name
FROM transactions t
JOIN customers c ON c.id = t.customer_id
WHERE t.is_deleted = 0 AND c.is_deleted = 0
ORDER BY t.txn_date DESC, t.created_at DESC
LIMIT 5
''');
    final recent = <RecentActivity>[];
    for (final row in recentRows) {
      try {
        recent.add(RecentActivity(
          transaction: transactionFromRow(row),
          customerName: row.str('customer_name'),
        ));
      } on FormatException {
        continue;
      }
    }

    return DashboardData.compute(
      summaries: summaries,
      todayCollection: collection,
      recent: recent,
    );
  }
}
