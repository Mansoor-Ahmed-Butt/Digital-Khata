import 'package:digital_khata/core/utils/money.dart';
import 'package:digital_khata/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('parses rupees to paisa', () {
      expect(Money.parseToPaisa('2500'), 250000);
      expect(Money.parseToPaisa('2,500.5'), 250050);
      expect(Money.parseToPaisa('0.05'), 5);
      expect(Money.parseToPaisa('25.'), 2500);
    });
    test('accepts Urdu digits', () {
      expect(Money.parseToPaisa('۱۲۰۰'), 120000);
    });
    test('rejects invalid input', () {
      expect(Money.parseToPaisa(''), isNull);
      expect(Money.parseToPaisa('abc'), isNull);
      expect(Money.parseToPaisa('1.234'), isNull);
      expect(Money.parseToPaisa('-5'), isNull);
      expect(Money.parseToPaisa('-5', allowNegative: true), -500);
    });
    test('formats with grouping', () {
      expect(Money.format(450000), '4,500');
      expect(Money.format(450050), '4,500.50');
      expect(Money.format(-120000), '-1,200');
      expect(Money.format(0), '0');
    });
  });

  group('Validators', () {
    test('VR-01 phone', () {
      expect(Validators.phone('03001234567'), isNull);
      expect(Validators.phone('+923001234567'), isNull);
      expect(Validators.phone('0300 123 4567'), isNull);
      expect(Validators.phone(''), isNull);
      expect(Validators.phone('12345'), 'err_phone_invalid');
      expect(Validators.phone('', required: true), 'err_phone_required');
    });
    test('VR-02 amount', () {
      expect(Validators.amount(1), isNull);
      expect(Validators.amount(Money.maxPaisa), isNull);
      expect(Validators.amount(0), 'err_amount_invalid');
      expect(Validators.amount(Money.maxPaisa + 1), 'err_amount_invalid');
      expect(Validators.amount(null), 'err_amount_invalid');
    });
    test('VR-03 name', () {
      expect(Validators.name('Al'), isNull);
      expect(Validators.name('A'), 'err_name_length');
      expect(Validators.name('x' * 61), 'err_name_length');
    });
    test('VR-04 date', () {
      final now = DateTime(2026, 10, 18);
      expect(Validators.txnDate(DateTime(2026, 10, 19), now: now), isNull);
      expect(Validators.txnDate(DateTime(2026, 10, 20), now: now), 'err_date_future');
    });
    test('whatsapp number', () {
      expect(Validators.whatsAppNumber('03001234567'), '923001234567');
      expect(Validators.whatsAppNumber('+923001234567'), '923001234567');
      expect(Validators.whatsAppNumber('abc'), isNull);
      expect(Validators.normalizeMobile('+92 300 1234567'), '+923001234567');
    });
  });
}
