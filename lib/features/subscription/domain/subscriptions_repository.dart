import 'subscription.dart';

abstract class SubscriptionsRepository {
  Stream<List<Subscription>> watchAll();
  Future<Subscription?> getById(String id);
  Future<void> upsert(Subscription item);
  Future<void> softDelete(String id);

  /// Returns the active subscription row, creating the default free plan
  /// the first time it is called.
  Future<Subscription> current();
}
