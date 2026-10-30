import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../errors/failure.dart';

/// Local SQLite database - the source of truth for the user (offline-first).
///
/// Every write goes through [write], which runs inside a database
/// transaction (NFR-03) and then notifies watchers so reactive streams
/// refresh. Rows carry `sync_status` so a cloud sync engine can be added
/// later without a schema change.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  static const String fileName = 'digital_khata.db';
  static const int schemaVersion = 1;

  static Future<AppDatabase> open({String? path}) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), fileName);
    final database = await openDatabase(
      dbPath,
      version: schemaVersion,
      onConfigure: (d) async {
        await d.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (d, version) async {
        final batch = d.batch();
        for (final statement in _schema) {
          batch.execute(statement);
        }
        await batch.commit(noResult: true);
      },
      onUpgrade: (d, oldVersion, newVersion) async {
        // Add forward-only migrations here, one `if (oldVersion < N)` per version.
      },
    );
    return AppDatabase._(database);
  }

  /// Emits whenever data changed through [write] or [notify].
  Stream<void> get changes => _changes.stream;

  void notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Runs [action] in a transaction and notifies watchers on success.
  Future<T> write<T>(Future<T> Function(Transaction txn) action) async {
    final result = await db.transaction<T>(action);
    notify();
    return result;
  }

  /// Re-runs [query] now and after every write. Out-of-order results are
  /// dropped so the UI never shows stale data. Errors are delivered as
  /// stream errors, never thrown.
  Stream<T> watch<T>(Future<T> Function() query) {
    late final StreamController<T> controller;
    StreamSubscription<void>? subscription;
    var sequence = 0;

    Future<void> emit() async {
      final mine = ++sequence;
      try {
        final value = await query();
        if (!controller.isClosed && mine == sequence) controller.add(value);
      } catch (e, s) {
        CrashReporter.record(e, s, reason: 'watch');
        if (!controller.isClosed && mine == sequence) controller.addError(e, s);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        emit();
        subscription = _changes.stream.listen((_) => emit());
      },
      onCancel: () async {
        await subscription?.cancel();
        subscription = null;
      },
    );
    return controller.stream;
  }

  Future<void> close() async {
    await _changes.close();
    await db.close();
  }

  static const List<String> _schema = <String>[
    '''
CREATE TABLE customers (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL DEFAULT 'pending',
  name TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  opening_balance INTEGER NOT NULL DEFAULT 0,
  credit_limit INTEGER,
  notes TEXT,
  is_archived INTEGER NOT NULL DEFAULT 0
)''',
    '''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL DEFAULT 'pending',
  customer_id TEXT NOT NULL REFERENCES customers(id),
  type TEXT NOT NULL CHECK (type IN ('credit', 'payment')),
  amount INTEGER NOT NULL CHECK (amount > 0),
  txn_date TEXT NOT NULL,
  note TEXT,
  photo_path TEXT
)''',
    '''
CREATE TABLE reminders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL DEFAULT 'pending',
  customer_id TEXT NOT NULL REFERENCES customers(id),
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp', 'sms')),
  message TEXT NOT NULL,
  sent_at TEXT NOT NULL
)''',
    '''
CREATE TABLE subscriptions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  sync_status TEXT NOT NULL DEFAULT 'pending',
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'pro')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  expires_at TEXT,
  store_receipt TEXT
)''',
    'CREATE INDEX idx_customers_sync ON customers (user_id, updated_at)',
    'CREATE INDEX idx_customers_user_name ON customers (user_id, name)',
    'CREATE INDEX idx_transactions_customer ON transactions (customer_id)',
    'CREATE INDEX idx_transactions_sync ON transactions (user_id, updated_at)',
    'CREATE INDEX idx_transactions_customer_date ON transactions (customer_id, txn_date DESC)',
    'CREATE INDEX idx_reminders_customer ON reminders (customer_id)',
    'CREATE INDEX idx_reminders_sync ON reminders (user_id, updated_at)',
    'CREATE INDEX idx_subscriptions_sync ON subscriptions (user_id, updated_at)',
  ];
}
