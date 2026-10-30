import 'package:digital_khata/features/customers/domain/customer.dart';
import 'package:digital_khata/features/customers/domain/customer_list_logic.dart';
import 'package:digital_khata/features/dashboard/domain/dashboard_data.dart';
import 'package:digital_khata/features/ledger/domain/ledger_transaction.dart';
import 'package:digital_khata/features/reminders/domain/reminder.dart';
import 'package:digital_khata/features/statements/domain/statement_data.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _t = DateTime.utc(2026, 10, 1);

Customer customer(String id, String name, {int opening = 0, bool archived = false, String? phone}) =>
    Customer(
        id: id,
        userId: 'local',
        createdAt: _t,
        updatedAt: _t,
        name: name,
        openingBalance: opening,
        isArchived: archived,
        phone: phone);

LedgerTransaction txn(String id, TxnType type, int amount, DateTime date, {bool deleted = false}) =>
    LedgerTransaction(
        id: id,
        userId: 'local',
        createdAt: _t.add(Duration(minutes: id.hashCode % 1000)),
        updatedAt: _t,
        isDeleted: deleted,
        customerId: 'c1',
        type: type,
        amount: amount,
        txnDate: date);

void main() {
  group('BR-01/02/05 balance', () {
    final list = <LedgerTransaction>[
      txn('a', TxnType.credit, 150000, DateTime(2026, 9, 28)),
      txn('b', TxnType.payment, 300000, DateTime(2026, 10, 2)),
      txn('c', TxnType.credit, 50000, DateTime(2026, 10, 3), deleted: true),
    ];
    test('opening + credits - payments, ignoring deleted', () {
      expect(BalanceCalculator.balance(100000, list), -50000); // advance
    });
    test('timeline is newest first with running balance', () {
      final tl = BalanceCalculator.timeline(100000, list);
      expect(tl.length, 2);
      expect(tl.first.transaction.id, 'b');
      expect(tl.first.balanceAfter, -50000);
      expect(tl.last.balanceAfter, 250000);
    });
  });

  group('Customer list', () {
    final all = <CustomerSummary>[
      CustomerSummary(customer: customer('1', 'Ali Raza', phone: '03001234567'), balance: 450000),
      CustomerSummary(customer: customer('2', 'Sana Khan'), balance: 0),
      CustomerSummary(customer: customer('3', 'Bilal', archived: true), balance: 1000),
    ];
    test('archived hidden by default, due and clear filters', () {
      expect(CustomerListLogic.apply(all, query: '', filter: CustomerFilter.all, sort: CustomerSort.name).length, 2);
      expect(CustomerListLogic.apply(all, query: '', filter: CustomerFilter.due, sort: CustomerSort.name).single.customer.id, '1');
      expect(CustomerListLogic.apply(all, query: '', filter: CustomerFilter.clear, sort: CustomerSort.name).single.customer.id, '2');
      expect(CustomerListLogic.apply(all, query: '', filter: CustomerFilter.archived, sort: CustomerSort.name).single.customer.id, '3');
    });
    test('search by name and phone', () {
      expect(CustomerListLogic.apply(all, query: 'sana', filter: CustomerFilter.all, sort: CustomerSort.name).single.customer.id, '2');
      expect(CustomerListLogic.apply(all, query: '0300', filter: CustomerFilter.all, sort: CustomerSort.name).single.customer.id, '1');
    });
  });

  group('Dashboard', () {
    test('receivable counts positive balances only; top 5 sorted', () {
      final s = <CustomerSummary>[
        for (var i = 1; i <= 7; i++) CustomerSummary(customer: customer('$i', 'C$i'), balance: i * 100),
        CustomerSummary(customer: customer('x', 'Adv'), balance: -5000),
      ];
      final d = DashboardData.compute(summaries: s, todayCollection: 7, recent: const <RecentActivity>[]);
      expect(d.totalReceivable, 2800);
      expect(d.topDebtors.length, 5);
      expect(d.topDebtors.first.balance, 700);
      expect(d.todayCollection, 7);
    });
  });

  group('Statement', () {
    test('opening balance includes earlier entries; totals in range', () {
      final c = customer('c1', 'Ali', opening: 10000);
      final data = StatementData.assemble(
        shopName: 'Shop',
        customer: c,
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
        allTransactions: <LedgerTransaction>[
          txn('p', TxnType.credit, 20000, DateTime(2026, 9, 10)),
          txn('q', TxnType.credit, 50000, DateTime(2026, 10, 5)),
          txn('r', TxnType.payment, 30000, DateTime(2026, 10, 6)),
          txn('s', TxnType.credit, 99999, DateTime(2026, 11, 2)),
        ],
      );
      expect(data.openingBalance, 30000);
      expect(data.totalCredit, 50000);
      expect(data.totalPayment, 30000);
      expect(data.closingBalance, 50000);
      expect(data.entries.length, 2);
    });
  });

  group('Reminder message', () {
    test('fills placeholders', () {
      expect(ReminderMessage.fill('{name} owes {amount} to {shop}', name: 'Ali', amount: 'Rs 4,500', shop: 'Store'),
          'Ali owes Rs 4,500 to Store');
    });
    test('builds links', () {
      final wa = ReminderMessage.whatsAppUri(digits: '923001234567', message: 'Hi there');
      expect(wa.toString(), 'https://wa.me/923001234567?text=Hi%20there');
      expect(ReminderMessage.whatsAppUri(message: 'x').toString(), 'https://wa.me/?text=x');
      expect(ReminderMessage.smsUri(phone: '03001234567', message: 'a b').toString(), 'sms:03001234567?body=a%20b');
    });
  });
}
