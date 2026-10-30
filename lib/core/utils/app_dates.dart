import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AppDates {
  AppDates._();

  static String get _lang => Get.locale?.languageCode ?? 'en';

  static DateTime today([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// "yyyy-MM-dd" - the format stored in the database for txn_date.
  static String toDbDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime? fromDbDate(String? s) {
    if (s == null || s.length < 10) return null;
    final parsed = DateTime.tryParse(s.substring(0, 10));
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String full(DateTime d) => _safe(() => DateFormat('dd MMM yyyy', _lang).format(d), d);

  static String short(DateTime d) => _safe(() => DateFormat('dd MMM', _lang).format(d), d);

  static String _safe(String Function() f, DateTime fallback) {
    try {
      return f();
    } catch (_) {
      return '${fallback.day}/${fallback.month}/${fallback.year}';
    }
  }
}
