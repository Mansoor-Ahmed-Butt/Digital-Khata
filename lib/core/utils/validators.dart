import 'money.dart';

/// Pure validation rules (VR-01 .. VR-05). Each returns a translation key
/// for the error, or null when the value is valid.
class Validators {
  Validators._();

  static final RegExp _phoneRe = RegExp(r'^(03\d{9}|\+923\d{9})$');

  static String cleanPhone(String input) =>
      Money.normalizeDigits(input).replaceAll(RegExp(r'[\s\-()]'), '');

  /// Normalizes a number from the phone book (+92 300 1234567, 0300-1234567,
  /// 923001234567, 00923001234567) to a valid 03XXXXXXXXX / +923XXXXXXXXX
  /// value, or null when it is not a Pakistani mobile number.
  static String? normalizeMobile(String raw) {
    var s = cleanPhone(raw);
    if (s.startsWith('0092')) {
      s = '+${s.substring(2)}';
    } else if (s.startsWith('92') && s.length == 12) {
      s = '+$s';
    }
    return _phoneRe.hasMatch(s) ? s : null;
  }

  /// VR-03: 2-60 characters.
  static String? name(String value) {
    final length = value.trim().runes.length;
    if (length < 2 || length > 60) return 'err_name_length';
    return null;
  }

  /// VR-01: Pakistani mobile 03XXXXXXXXX or +923XXXXXXXXX. Empty is allowed
  /// unless [required] is true.
  static String? phone(String value, {bool required = false}) {
    final cleaned = cleanPhone(value);
    if (cleaned.isEmpty) return required ? 'err_phone_required' : null;
    return _phoneRe.hasMatch(cleaned) ? null : 'err_phone_invalid';
  }

  /// VR-02: positive and no more than 9,999,999,900 paisa.
  static String? amount(int? paisa) {
    if (paisa == null || paisa <= 0 || paisa > Money.maxPaisa) return 'err_amount_invalid';
    return null;
  }

  /// Opening balance may be negative (advance) or zero, within the same bound.
  static String? openingBalance(int? paisa) {
    if (paisa == null) return 'err_amount_invalid';
    if (paisa.abs() > Money.maxPaisa) return 'err_amount_invalid';
    return null;
  }

  /// Optional credit limit: empty is fine, otherwise positive and in range.
  static String? creditLimit(String raw, int? parsed) {
    if (raw.trim().isEmpty) return null;
    return amount(parsed);
  }

  /// VR-04: not more than one day in the future.
  static String? txnDate(DateTime date, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final latest = DateTime(n.year, n.month, n.day + 1);
    final d = DateTime(date.year, date.month, date.day);
    return d.isAfter(latest) ? 'err_date_future' : null;
  }

  /// Converts a valid Pakistani number to the international digits used by
  /// wa.me links (923XXXXXXXXX). Returns null when the number is invalid.
  static String? whatsAppNumber(String? raw) {
    if (raw == null) return null;
    final cleaned = cleanPhone(raw);
    if (!_phoneRe.hasMatch(cleaned)) return null;
    if (cleaned.startsWith('+')) return cleaned.substring(1);
    return '92${cleaned.substring(1)}';
  }
}
