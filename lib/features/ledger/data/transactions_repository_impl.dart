import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_reader.dart';
import '../../../core/utils/app_dates.dart';
import '../domain/ledger_transaction.dart';
import '../domain/transactions_repository.dart';

LedgerTransaction transactionFromRow(Map<String, Object?> r) {
  final type = r.str('type') == 'payment' ? TxnType.payment : TxnType.credit;
  final date = AppDates.fromDbDate(r.str('txn_date'));
  if (date == null) throw const FormatException('Invalid txn_date');
  return LedgerTransaction(
    id: r.str('id'),
    userId: r.str('user_id'),
    createdAt: r.date('created_at'),
    updatedAt: r.date('updated_at'),
    isDeleted: r.flag('is_deleted'),
    customerId: r.str('customer_id'),
    type: type,
    amount: r.integer('amount'),
    txnDate: date,
    note: r.strOrNull('note'),
    photoPath: r.strOrNull('photo_path'),
  );
}

Map<String, Object?> transactionToRow(LedgerTransaction t) => <String, Object?>{
      'id': t.id,
      'user_id': t.userId,
      'created_at': t.createdAt.toUtc().toIso8601String(),
      'updated_at': t.updatedAt.toUtc().toIso8601String(),
      'is_deleted': t.isDeleted ? 1 : 0,
      'sync_status': 'pending',
      'customer_id': t.customerId,
      'type': t.type == TxnType.payment ? 'payment' : 'credit',
      'amount': t.amount,
      'txn_date': AppDates.toDbDate(t.txnDate),
      'note': t.note,
      'photo_path': t.photoPath,
    };

List<LedgerTransaction> _mapRows(List<Map<String, Object?>> rows) {
  final out = <LedgerTransaction>[];
  for (final row in rows) {
    try {
      out.add(transactionFromRow(row));
    } on FormatException {
      continue;
    }
  }
  return out;
}

class TransactionsRepositoryImpl implements TransactionsRepository {
  TransactionsRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Stream<List<LedgerTransaction>> watchAll() => _database.watch(() async {
        final rows = await _database.db.query('transactions',
            where: 'is_deleted = 0', orderBy: 'txn_date DESC, created_at DESC');
        return _mapRows(rows);
      });

  @override
  Stream<List<LedgerTransaction>> watchForCustomer(String customerId) =>
      _database.watch(() async {
        final rows = await _database.db.query('transactions',
            where: 'customer_id = ? AND is_deleted = 0',
            whereArgs: [customerId],
            orderBy: 'txn_date DESC, created_at DESC');
        return _mapRows(rows);
      });

  @override
  Future<LedgerTransaction?> getById(String id) async {
    final rows = await _database.db
        .query('transactions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return transactionFromRow(rows.first);
  }

  @override
  Future<void> upsert(LedgerTransaction item) => _database.write((txn) async {
        await txn.insert('transactions', transactionToRow(item),
            conflictAlgorithm: ConflictAlgorithm.replace);
      });

  Future<void> _setDeleted(String id, bool deleted) => _database.write((txn) async {
        await txn.update(
          'transactions',
          {
            'is_deleted': deleted ? 1 : 0,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'sync_status': 'pending',
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });

  @override
  Future<void> softDelete(String id) => _setDeleted(id, true);

  @override
  Future<void> restore(String id) => _setDeleted(id, false);

  @override
  Future<List<LedgerTransaction>> forCustomerBetween(String customerId,
      {DateTime? from, DateTime? to}) async {
    final where = StringBuffer('customer_id = ? AND is_deleted = 0');
    final args = <Object?>[customerId];
    if (from != null) {
      where.write(' AND txn_date >= ?');
      args.add(AppDates.toDbDate(from));
    }
    if (to != null) {
      where.write(' AND txn_date <= ?');
      args.add(AppDates.toDbDate(to));
    }
    final rows = await _database.db.query('transactions',
        where: where.toString(),
        whereArgs: args,
        orderBy: 'txn_date ASC, created_at ASC');
    return _mapRows(rows);
  }

  @override
  Future<RangeTotals> totalsBetween(DateTime from, DateTime to) async {
    final rows = await _database.db.rawQuery('''
SELECT
  COALESCE(SUM(CASE WHEN type = 'credit' THEN amount ELSE 0 END), 0) AS credit,
  COALESCE(SUM(CASE WHEN type = 'payment' THEN amount ELSE 0 END), 0) AS payment
FROM transactions
WHERE is_deleted = 0 AND txn_date >= ? AND txn_date <= ?
''', [AppDates.toDbDate(from), AppDates.toDbDate(to)]);
    if (rows.isEmpty) return const RangeTotals();
    final r = rows.first;
    return RangeTotals(
      credit: r.integer('credit', fallback: 0),
      payment: r.integer('payment', fallback: 0),
    );
  }
}
