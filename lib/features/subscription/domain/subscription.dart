/// FR-10: the free plan allows 50 active (non-archived) customers.
const int kFreePlanCustomerLimit = 50;

enum Plan { free, pro }

enum SubscriptionStatus { active, expired, cancelled }

class Subscription {
  const Subscription({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.plan = Plan.free,
    this.status = SubscriptionStatus.active,
    this.expiresAt,
    this.storeReceipt,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final Plan plan;
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final String? storeReceipt;

  /// Pro is only effective while active and not past its expiry date.
  bool isPro({DateTime? now}) {
    if (plan != Plan.pro || status != SubscriptionStatus.active) return false;
    final expiry = expiresAt;
    if (expiry == null) return true;
    return expiry.isAfter(now ?? DateTime.now());
  }
}
