import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_reader.dart';
import '../../../core/utils/app_dates.dart';
import '../domain/customer.dart';
import '../domain/customers_repository.dart';

Customer customerFromRow(Map<String, Object?> r) => Customer(
      id: r.str('id'),
      userId: r.str('user_id'),
      createdAt: r.date('created_at'),
      updatedAt: r.date('updated_at'),
      isDeleted: r.flag('is_deleted'),
      name: r.str('name'),
      phone: r.strOrNull('phone'),
      address: r.strOrNull('address'),
      openingBalance: r.integer('opening_balance', fallback: 0),
      creditLimit: r.integerOrNull('credit_limit'),
      notes: r.strOrNull('notes'),
      isArchived: r.flag('is_archived'),
    );

Map<String, Object?> customerToRow(Customer c) => <String, Object?>{
      'id': c.id,
      'user_id': c.userId,
      'created_at': c.createdAt.toUtc().toIso8601String(),
      'updated_at': c.updatedAt.toUtc().toIso8601String(),
      'is_deleted': c.isDeleted ? 1 : 0,
      'sync_status': 'pending',
      'name': c.name,
      'phone': c.phone,
      'address': c.address,
      'opening_balance': c.openingBalance,
      'credit_limit': c.creditLimit,
      'notes': c.notes,
      'is_archived': c.isArchived ? 1 : 0,
    };

/// BR-01: balance = opening_balance + sum(credit) - sum(payment).
/// Soft-deleted transactions are excluded (BR-05).
const String _summarySql = '''
SELECT c.*,
  c.opening_balance + COALESCE(SUM(CASE t.type
      WHEN 'credit' THEN t.amount
      WHEN 'payment' THEN -t.amount
      ELSE 0 END), 0) AS balance,
  MAX(t.txn_date) AS last_txn_date
FROM customers c
LEFT JOIN transactions t ON t.customer_id = c.id AND t.is_deleted = 0
WHERE c.is_deleted = 0
''';

CustomerSummary summaryFromRow(Map<String, Object?> r) => CustomerSummary(
      customer: customerFromRow(r),
      balance: r.integer('balance', fallback: 0),
      lastEntryDate: AppDates.fromDbDate(r['last_txn_date'] as String?),
    );

/// Shared by the customers and dashboard repositories.
Future<List<CustomerSummary>> queryCustomerSummaries(Database db) async {
  final rows = await db.rawQuery('$_summarySql GROUP BY c.id ORDER BY c.name COLLATE NOCASE ASC');
  final result = <CustomerSummary>[];
  for (final row in rows) {
    try {
      result.add(summaryFromRow(row));
    } on FormatException {
      continue; // Skip a single malformed row instead of failing the screen.
    }
  }
  return result;
}

class CustomersRepositoryImpl implements CustomersRepository {
  CustomersRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Stream<List<Customer>> watchAll() => _database.watch(() async {
        final rows = await _database.db.query('customers',
            where: 'is_deleted = 0', orderBy: 'name COLLATE NOCASE ASC');
        return rows.map(customerFromRow).toList();
      });

  @override
  Stream<List<CustomerSummary>> watchSummaries() =>
      _database.watch(() => queryCustomerSummaries(_database.db));

  @override
  Stream<CustomerSummary?> watchSummary(String id) =>
      _database.watch(() => getSummary(id));

  @override
  Future<Customer?> getById(String id) async {
    final rows = await _database.db
        .query('customers', where: 'id = ? AND is_deleted = 0', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : customerFromRow(rows.first);
  }

  @override
  Future<CustomerSummary?> getSummary(String id) async {
    final rows = await _database.db.rawQuery('$_summarySql AND c.id = ? GROUP BY c.id', [id]);
    return rows.isEmpty ? null : summaryFromRow(rows.first);
  }

  @override
  Future<void> upsert(Customer item) => _database.write((txn) async {
        await txn.insert('customers', customerToRow(item),
            conflictAlgorithm: ConflictAlgorithm.replace);
      });

  @override
  Future<void> softDelete(String id) => _database.write((txn) async {
        await txn.update(
          'customers',
          {
            'is_deleted': 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'sync_status': 'pending',
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });

  @override
  Future<void> setArchived(String id, bool archived) => _database.write((txn) async {
        await txn.update(
          'customers',
          {
            'is_archived': archived ? 1 : 0,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'sync_status': 'pending',
          },
          where: 'id = ? AND is_deleted = 0',
          whereArgs: [id],
        );
      });

  @override
  Future<int> countActive() async {
    final rows = await _database.db.rawQuery(
        'SELECT COUNT(*) AS n FROM customers WHERE is_deleted = 0 AND is_archived = 0');
    final v = rows.isEmpty ? 0 : rows.first['n'];
    return v is int ? v : 0;
  }

  @override
  Future<bool> phoneExists(String phone, {String? excludeId}) async {
    final rows = await _database.db.query(
      'customers',
      columns: ['id'],
      where: excludeId == null
          ? 'is_deleted = 0 AND phone = ?'
          : 'is_deleted = 0 AND phone = ? AND id != ?',
      whereArgs: excludeId == null ? [phone] : [phone, excludeId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
