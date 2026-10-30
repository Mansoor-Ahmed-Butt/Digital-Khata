import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/failure.dart';
import '../../customers/data/customers_repository_impl.dart';
import '../../customers/domain/customer.dart';
import '../../ledger/data/transactions_repository_impl.dart';
import '../../ledger/domain/ledger_transaction.dart';
import '../../reminders/data/reminders_repository_impl.dart';
import '../../reminders/domain/reminder.dart';

class RestoreSummary {
  const RestoreSummary({required this.customers, required this.transactions});

  final int customers;
  final int transactions;
}

/// Local JSON backup and restore. Works fully offline; the resulting file
/// can be shared to Drive, WhatsApp or email. (Cloud backup through Supabase
/// plugs in later behind the same screen.)
class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  static const String appId = 'digital_khata';
  static const int formatVersion = 1;
  static const int maxFileBytes = 25 * 1024 * 1024;

  Future<String> buildJson() async {
    final db = _database.db;
    final customers = await db.query('customers', where: 'is_deleted = 0');
    final transactions = await db.query('transactions', where: 'is_deleted = 0');
    final reminders = await db.query('reminders', where: 'is_deleted = 0');
    return jsonEncode(<String, Object?>{
      'app': appId,
      'version': formatVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'customers': customers,
      'transactions': transactions,
      'reminders': reminders,
    });
  }

  /// Writes the backup into the temp directory and returns the file.
  Future<File> writeBackupFile() async {
    final json = await buildJson();
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/digital_khata_backup_$stamp.json');
    return file.writeAsString(json, flush: true);
  }

  Future<String> readFileSafely(File file) async {
    final length = await file.length();
    if (length > maxFileBytes) throw const Failure('err_backup_too_large');
    return file.readAsString();
  }

  /// Validates the whole file first, saves a safety copy of the current data,
  /// then replaces everything inside one transaction. If anything fails the
  /// transaction rolls back and existing data stays untouched.
  Future<RestoreSummary> restore(String raw) async {
    final parsed = _parse(raw);

    try {
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/pre_restore_backup.json')
          .writeAsString(await buildJson(), flush: true);
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'pre_restore_copy');
    }

    try {
      await _database.write((txn) async {
        await txn.delete('reminders');
        await txn.delete('transactions');
        await txn.delete('customers');
        final batch = txn.batch();
        for (final c in parsed.customers) {
          batch.insert('customers', customerToRow(c), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final t in parsed.transactions) {
          batch.insert('transactions', transactionToRow(t),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final r in parsed.reminders) {
          batch.insert('reminders', reminderToRow(r), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
    } on DatabaseException catch (e, s) {
      CrashReporter.record(e, s, reason: 'restore_db');
      throw const Failure('err_restore_failed');
    }
    return RestoreSummary(
        customers: parsed.customers.length, transactions: parsed.transactions.length);
  }

  _ParsedBackup _parse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('root');
      if (decoded['app'] != appId) throw const FormatException('app');
      final version = decoded['version'];
      if (version is! int || version > formatVersion) throw const FormatException('version');

      List<Map<String, Object?>> rows(Object? value) {
        if (value == null) return <Map<String, Object?>>[];
        if (value is! List) throw const FormatException('table');
        return value.map((e) {
          if (e is! Map) throw const FormatException('row');
          return Map<String, Object?>.from(e);
        }).toList();
      }

      final customers = rows(decoded['customers']).map(customerFromRow).toList();
      final transactions = rows(decoded['transactions']).map(transactionFromRow).toList();
      final reminders = rows(decoded['reminders']).map(reminderFromRow).toList();

      final ids = customers.map((c) => c.id).toSet();
      for (final t in transactions) {
        if (!ids.contains(t.customerId) || t.amount <= 0) {
          throw const FormatException('reference');
        }
      }
      for (final r in reminders) {
        if (!ids.contains(r.customerId)) throw const FormatException('reference');
      }
      return _ParsedBackup(customers, transactions, reminders);
    } on FormatException catch (e) {
      throw Failure('err_backup_invalid', e);
    } on TypeError catch (e) {
      throw Failure('err_backup_invalid', e);
    }
  }
}

class _ParsedBackup {
  const _ParsedBackup(this.customers, this.transactions, this.reminders);

  final List<Customer> customers;
  final List<LedgerTransaction> transactions;
  final List<Reminder> reminders;
}
