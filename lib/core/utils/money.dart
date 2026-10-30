/// All money is stored as integer paisa (1 PKR = 100 paisa).
class Money {
  Money._();

  static const int maxPaisa = 9999999900;

  /// Converts Arabic-Indic and Persian digits to ASCII so Urdu keyboards work.
  static String normalizeDigits(String input) {
    final sb = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        sb.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        sb.writeCharCode(0x30 + rune - 0x06F0);
      } else if (rune == 0x066B) {
        sb.write('.');
      } else if (rune == 0x066C) {
        continue;
      } else {
        sb.writeCharCode(rune);
      }
    }
    return sb.toString();
  }

  /// Parses user input such as "2,500.5" into paisa. Returns null when invalid.
  static int? parseToPaisa(String input, {bool allowNegative = false}) {
    var s = normalizeDigits(input).replaceAll(',', '').replaceAll(' ', '').trim();
    if (s.isEmpty) return null;
    var negative = false;
    if (s.startsWith('-')) {
      if (!allowNegative) return null;
      negative = true;
      s = s.substring(1);
    }
    final m = RegExp(r'^(\d{0,12})(?:\.(\d{0,2}))?$').firstMatch(s);
    if (m == null) return null;
    final whole = m.group(1) ?? '';
    final frac = m.group(2) ?? '';
    if (whole.isEmpty && frac.isEmpty) return null;
    final w = whole.isEmpty ? 0 : int.parse(whole);
    final f = frac.isEmpty ? 0 : int.parse(frac.padRight(2, '0'));
    final value = w * 100 + f;
    return negative ? -value : value;
  }

  /// Groups digits with commas: 1234567 -> "1,234,567".
  static String group(int n) {
    final s = n.abs().toString();
    final sb = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) sb.write(',');
      sb.write(s[i]);
    }
    return sb.toString();
  }

  /// 450000 -> "4,500", 450050 -> "4,500.50". Negative values keep their sign.
  static String format(int paisa) {
    final abs = paisa.abs();
    final whole = abs ~/ 100;
    final frac = abs % 100;
    var out = group(whole);
    if (frac != 0) out += '.${frac.toString().padLeft(2, '0')}';
    return paisa < 0 ? '-$out' : out;
  }

  static String withSymbol(int paisa, String symbol) => '$symbol ${format(paisa)}';
}
