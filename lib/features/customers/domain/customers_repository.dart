import 'customer.dart';

abstract class CustomersRepository {
  Stream<List<Customer>> watchAll();

  /// Every non-deleted customer (archived included) with its balance.
  Stream<List<CustomerSummary>> watchSummaries();
  Stream<CustomerSummary?> watchSummary(String id);

  Future<Customer?> getById(String id);
  Future<CustomerSummary?> getSummary(String id);
  Future<void> upsert(Customer item);
  Future<void> softDelete(String id);
  Future<void> setArchived(String id, bool archived);

  /// BR-06: counts only non-archived, non-deleted customers.
  Future<int> countActive();

  /// VR-05: used to show a duplicate-number warning, never an error.
  Future<bool> phoneExists(String phone, {String? excludeId});
}
