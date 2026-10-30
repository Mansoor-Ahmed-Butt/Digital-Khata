/// Strict, null-safe accessors for sqflite rows and backup JSON maps.
/// Any malformed value throws [FormatException], which callers convert to a
/// user-friendly failure instead of crashing.
extension RowReader on Map<String, Object?> {
  String str(String key) {
    final v = this[key];
    if (v is String) return v;
    throw FormatException('Missing or invalid "$key"');
  }

  String? strOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    throw FormatException('Invalid "$key"');
  }

  int integer(String key, {int? fallback}) {
    final v = this[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v == null && fallback != null) return fallback;
    throw FormatException('Missing or invalid "$key"');
  }

  int? integerOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    throw FormatException('Invalid "$key"');
  }

  bool flag(String key) {
    final v = this[key];
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    throw FormatException('Invalid "$key"');
  }

  DateTime date(String key) {
    final parsed = DateTime.tryParse(str(key));
    if (parsed == null) throw FormatException('Invalid date "$key"');
    return parsed;
  }

  DateTime? dateOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is! String) throw FormatException('Invalid "$key"');
    return DateTime.tryParse(v);
  }
}
