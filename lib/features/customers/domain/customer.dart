class Customer {
  const Customer({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    required this.name,
    this.phone,
    this.address,
    this.openingBalance = 0,
    this.creditLimit,
    this.notes,
    this.isArchived = false,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String name;
  final String? phone;
  final String? address;

  /// Paisa. Positive means the customer already owed the shop on day one.
  final int openingBalance;
  final int? creditLimit;
  final String? notes;
  final bool isArchived;

  Customer copyWith({DateTime? updatedAt, bool? isDeleted, bool? isArchived}) => Customer(
        id: id,
        userId: userId,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        name: name,
        phone: phone,
        address: address,
        openingBalance: openingBalance,
        creditLimit: creditLimit,
        notes: notes,
        isArchived: isArchived ?? this.isArchived,
      );
}

/// A customer together with the computed balance (BR-01).
class CustomerSummary {
  const CustomerSummary({required this.customer, required this.balance, this.lastEntryDate});

  final Customer customer;

  /// Paisa. Positive = customer owes the shop; negative = advance (BR-02).
  final int balance;
  final DateTime? lastEntryDate;

  bool get isDue => balance > 0;
  bool get isAdvance => balance < 0;
  bool get isClear => balance == 0;
}

enum CustomerFilter { all, due, clear, archived }

enum CustomerSort { name, balanceHigh, recent }
