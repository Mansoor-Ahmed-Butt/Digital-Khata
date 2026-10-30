import '../../../core/database/local_user.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/validators.dart';
import '../../subscription/domain/subscription.dart';
import '../../subscription/domain/subscriptions_repository.dart';
import 'customer.dart';
import 'customers_repository.dart';

class SaveCustomerInput {
  const SaveCustomerInput({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.openingBalance = 0,
    this.creditLimit,
    this.notes = '',
  });

  final String? id;
  final String name;
  final String phone;
  final String address;
  final int openingBalance;
  final int? creditLimit;
  final String notes;
}

class SaveCustomerOutcome {
  const SaveCustomerOutcome({required this.customer, required this.duplicatePhone});

  final Customer customer;
  final bool duplicatePhone;
}

/// Creates or updates a customer, enforcing VR-01/03 and BR-06.
class SaveCustomerUseCase {
  SaveCustomerUseCase(this._customers, this._subscriptions);

  final CustomersRepository _customers;
  final SubscriptionsRepository _subscriptions;

  /// BR-06: throws `err_plan_limit` when a free-plan shop already has 50
  /// active customers.
  Future<void> ensureCanAddActive() async {
    final subscription = await _subscriptions.current();
    if (subscription.isPro()) return;
    final active = await _customers.countActive();
    if (active >= kFreePlanCustomerLimit) throw const Failure('err_plan_limit');
  }

  Future<SaveCustomerOutcome> call(SaveCustomerInput input) async {
    final nameError = Validators.name(input.name);
    if (nameError != null) throw Failure(nameError);
    final phoneError = Validators.phone(input.phone);
    if (phoneError != null) throw Failure(phoneError);
    final balanceError = Validators.openingBalance(input.openingBalance);
    if (balanceError != null) throw Failure(balanceError);
    if (input.creditLimit != null) {
      final limitError = Validators.amount(input.creditLimit);
      if (limitError != null) throw Failure(limitError);
    }

    Customer? existing;
    if (input.id != null) {
      existing = await _customers.getById(input.id!);
      if (existing == null) throw const Failure('err_not_found');
    } else {
      await ensureCanAddActive();
    }

    final cleanedPhone = Validators.cleanPhone(input.phone);
    final address = input.address.trim();
    final notes = input.notes.trim();
    final now = DateTime.now().toUtc();

    final customer = Customer(
      id: existing?.id ?? newId(),
      userId: existing?.userId ?? kLocalUserId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      name: input.name.trim(),
      phone: cleanedPhone.isEmpty ? null : cleanedPhone,
      address: address.isEmpty ? null : address,
      openingBalance: input.openingBalance,
      creditLimit: input.creditLimit,
      notes: notes.isEmpty ? null : notes,
      isArchived: existing?.isArchived ?? false,
    );
    await _customers.upsert(customer);

    final duplicate = customer.phone != null &&
        await _customers.phoneExists(customer.phone!, excludeId: customer.id);
    return SaveCustomerOutcome(customer: customer, duplicatePhone: duplicate);
  }
}
