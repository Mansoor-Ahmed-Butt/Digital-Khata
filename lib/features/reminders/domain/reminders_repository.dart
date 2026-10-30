import 'reminder.dart';

abstract class RemindersRepository {
  Stream<List<Reminder>> watchAll();
  Future<Reminder?> getById(String id);
  Future<void> upsert(Reminder item);
  Future<void> softDelete(String id);
}
