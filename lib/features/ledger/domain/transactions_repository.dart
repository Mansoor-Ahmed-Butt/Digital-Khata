import 'ledger_transaction.dart';

abstract class TransactionsRepository {
  Stream<List<LedgerTransaction>> watchAll();
  Stream<List<LedgerTransaction>> watchForCustomer(String customerId);
  Future<LedgerTransaction?> getById(String id);
  Future<void> upsert(LedgerTransaction item);

  /// BR-05: a soft delete; the balance recalculates because deleted rows
  /// are excluded from every sum.
  Future<void> softDelete(String id);
  Future<void> restore(String id);

  Future<List<LedgerTransaction>> forCustomerBetween(String customerId,
      {DateTime? from, DateTime? to});

  /// Sum of credits and payments for all customers, inclusive date range.
  Future<RangeTotals> totalsBetween(DateTime from, DateTime to);
}
