import '../../../core/database/local_user.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/validators.dart';
import '../../customers/domain/customers_repository.dart';
import 'ledger_transaction.dart';
import 'transactions_repository.dart';

class RecordTransactionInput {
  const RecordTransactionInput({
    required this.customerId,
    required this.type,
    required this.amountPaisa,
    required this.date,
    this.note = '',
    this.photoPath,
  });

  final String customerId;
  final TxnType type;
  final int? amountPaisa;
  final DateTime date;
  final String note;
  final String? photoPath;
}

class RecordTransactionOutcome {
  const RecordTransactionOutcome({required this.transaction, required this.exceedsCreditLimit});

  final LedgerTransaction transaction;

  /// BR-03: only a warning, the entry is always saved.
  final bool exceedsCreditLimit;
}

class RecordTransactionUseCase {
  RecordTransactionUseCase(this._customers, this._transactions);

  final CustomersRepository _customers;
  final TransactionsRepository _transactions;

  Future<RecordTransactionOutcome> call(RecordTransactionInput input) async {
    final amountError = Validators.amount(input.amountPaisa);
    if (amountError != null) throw Failure(amountError);
    final dateError = Validators.txnDate(input.date);
    if (dateError != null) throw Failure(dateError);

    final summary = await _customers.getSummary(input.customerId);
    if (summary == null) throw const Failure('err_not_found');

    final amount = input.amountPaisa!;
    final now = DateTime.now().toUtc();
    final note = input.note.trim();
    final txn = LedgerTransaction(
      id: newId(),
      userId: kLocalUserId,
      createdAt: now,
      updatedAt: now,
      customerId: input.customerId,
      type: input.type,
      amount: amount,
      txnDate: DateTime(input.date.year, input.date.month, input.date.day),
      note: note.isEmpty ? null : note,
      photoPath: input.photoPath,
    );
    await _transactions.upsert(txn);

    final limit = summary.customer.creditLimit;
    final newBalance = summary.balance + txn.signedAmount;
    final exceeds = input.type == TxnType.credit && limit != null && newBalance > limit;
    return RecordTransactionOutcome(transaction: txn, exceedsCreditLimit: exceeds);
  }
}
