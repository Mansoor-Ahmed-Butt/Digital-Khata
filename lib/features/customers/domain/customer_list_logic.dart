import '../../../core/utils/validators.dart';
import 'customer.dart';

/// Pure filtering, searching and sorting for the customer list.
class CustomerListLogic {
  CustomerListLogic._();

  static List<CustomerSummary> apply(
    List<CustomerSummary> source, {
    required String query,
    required CustomerFilter filter,
    required CustomerSort sort,
  }) {
    final q = query.trim().toLowerCase();
    final qDigits = Validators.cleanPhone(q);

    bool matchesFilter(CustomerSummary s) {
      switch (filter) {
        case CustomerFilter.all:
          return !s.customer.isArchived;
        case CustomerFilter.due:
          return !s.customer.isArchived && s.balance > 0;
        case CustomerFilter.clear:
          return !s.customer.isArchived && s.balance <= 0;
        case CustomerFilter.archived:
          return s.customer.isArchived;
      }
    }

    bool matchesQuery(CustomerSummary s) {
      if (q.isEmpty) return true;
      if (s.customer.name.toLowerCase().contains(q)) return true;
      final phone = s.customer.phone;
      return phone != null && qDigits.isNotEmpty && phone.contains(qDigits);
    }

    final result = source.where((s) => matchesFilter(s) && matchesQuery(s)).toList();

    int byName(CustomerSummary a, CustomerSummary b) =>
        a.customer.name.toLowerCase().compareTo(b.customer.name.toLowerCase());

    switch (sort) {
      case CustomerSort.name:
        result.sort(byName);
      case CustomerSort.balanceHigh:
        result.sort((a, b) {
          final c = b.balance.compareTo(a.balance);
          return c != 0 ? c : byName(a, b);
        });
      case CustomerSort.recent:
        result.sort((a, b) {
          final da = a.lastEntryDate;
          final db = b.lastEntryDate;
          if (da == null && db == null) return byName(a, b);
          if (da == null) return 1;
          if (db == null) return -1;
          final c = db.compareTo(da);
          return c != 0 ? c : byName(a, b);
        });
    }
    return result;
  }
}
