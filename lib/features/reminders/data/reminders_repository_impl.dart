import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_reader.dart';
import '../domain/reminder.dart';
import '../domain/reminders_repository.dart';

Reminder reminderFromRow(Map<String, Object?> r) => Reminder(
      id: r.str('id'),
      userId: r.str('user_id'),
      createdAt: r.date('created_at'),
      updatedAt: r.date('updated_at'),
      isDeleted: r.flag('is_deleted'),
      customerId: r.str('customer_id'),
      channel: r.str('channel') == 'sms' ? ReminderChannel.sms : ReminderChannel.whatsapp,
      message: r.str('message'),
      sentAt: r.date('sent_at'),
    );

Map<String, Object?> reminderToRow(Reminder m) => <String, Object?>{
      'id': m.id,
      'user_id': m.userId,
      'created_at': m.createdAt.toUtc().toIso8601String(),
      'updated_at': m.updatedAt.toUtc().toIso8601String(),
      'is_deleted': m.isDeleted ? 1 : 0,
      'sync_status': 'pending',
      'customer_id': m.customerId,
      'channel': m.channel == ReminderChannel.sms ? 'sms' : 'whatsapp',
      'message': m.message,
      'sent_at': m.sentAt.toUtc().toIso8601String(),
    };

class RemindersRepositoryImpl implements RemindersRepository {
  RemindersRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Stream<List<Reminder>> watchAll() => _database.watch(() async {
        final rows = await _database.db
            .query('reminders', where: 'is_deleted = 0', orderBy: 'sent_at DESC');
        final out = <Reminder>[];
        for (final row in rows) {
          try {
            out.add(reminderFromRow(row));
          } on FormatException {
            continue;
          }
        }
        return out;
      });

  @override
  Future<Reminder?> getById(String id) async {
    final rows =
        await _database.db.query('reminders', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : reminderFromRow(rows.first);
  }

  @override
  Future<void> upsert(Reminder item) => _database.write((txn) async {
        await txn.insert('reminders', reminderToRow(item),
            conflictAlgorithm: ConflictAlgorithm.replace);
      });

  @override
  Future<void> softDelete(String id) => _database.write((txn) async {
        await txn.update(
          'reminders',
          {
            'is_deleted': 1,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            'sync_status': 'pending',
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });
}
