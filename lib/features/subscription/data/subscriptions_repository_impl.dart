import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/local_user.dart';
import '../../../core/database/row_reader.dart';
import '../../../core/utils/ids.dart';
import '../domain/subscription.dart';
import '../domain/subscriptions_repository.dart';

Subscription subscriptionFromRow(Map<String, Object?> r) {
  final plan = r.str('plan') == 'pro' ? Plan.pro : Plan.free;
  final status = switch (r.str('status')) {
    'expired' => SubscriptionStatus.expired,
    'cancelled' => SubscriptionStatus.cancelled,
    _ => SubscriptionStatus.active,
  };
  return Subscription(
    id: r.str('id'),
    userId: r.str('user_id'),
    createdAt: r.date('created_at'),
    updatedAt: r.date('updated_at'),
    isDeleted: r.flag('is_deleted'),
    plan: plan,
    status: status,
    expiresAt: r.dateOrNull('expires_at'),
    storeReceipt: r.strOrNull('store_receipt'),
  );
}

Map<String, Object?> subscriptionToRow(Subscription s) => <String, Object?>{
      'id': s.id,
      'user_id': s.userId,
      'created_at': s.createdAt.toUtc().toIso8601String(),
      'updated_at': s.updatedAt.toUtc().toIso8601String(),
      'is_deleted': s.isDeleted ? 1 : 0,
      'sync_status': 'pending',
      'plan': s.plan == Plan.pro ? 'pro' : 'free',
      'status': switch (s.status) {
        SubscriptionStatus.active => 'active',
        SubscriptionStatus.expired => 'expired',
        SubscriptionStatus.cancelled => 'cancelled',
      },
      'expires_at': s.expiresAt?.toUtc().toIso8601String(),
      'store_receipt': s.storeReceipt,
    };

class SubscriptionsRepositoryImpl implements SubscriptionsRepository {
  SubscriptionsRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Stream<List<Subscription>> watchAll() => _database.watch(() async {
        final rows = await _database.db.query('subscriptions',
            where: 'is_deleted = 0', orderBy: 'updated_at DESC');
        return rows.map(subscriptionFromRow).toList();
      });

  @override
  Future<Subscription?> getById(String id) async {
    final rows = await _database.db
        .query('subscriptions', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : subscriptionFromRow(rows.first);
  }

  @override
  Future<void> upsert(Subscription item) => _database.write((txn) async {
        await txn.insert('subscriptions', subscriptionToRow(item),
            conflictAlgorithm: ConflictAlgorithm.replace);
      });

  @override
  Future<void> softDelete(String id) => _database.write((txn) async {
        await txn.update(
          'subscriptions',
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
  Future<Subscription> current() async {
    final rows = await _database.db.query('subscriptions',
        where: 'is_deleted = 0', orderBy: 'updated_at DESC', limit: 1);
    if (rows.isNotEmpty) {
      try {
        return subscriptionFromRow(rows.first);
      } on FormatException {
        // Fall through and recreate a clean default row.
      }
    }
    final now = DateTime.now().toUtc();
    final fresh = Subscription(
      id: newId(),
      userId: kLocalUserId,
      createdAt: now,
      updatedAt: now,
    );
    await upsert(fresh);
    return fresh;
  }
}
