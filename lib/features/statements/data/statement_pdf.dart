import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/errors/failure.dart';
import '../../../core/utils/money.dart';
import '../../ledger/domain/ledger_transaction.dart';
import '../domain/statement_data.dart';

/// Builds the statement PDF. Labels are English so the document reads the
/// same on any device; Urdu customer names fall back to the bundled
/// Nastaliq font instead of failing.
class StatementPdf {
  StatementPdf._();

  static final PdfColor _primary = PdfColor.fromInt(0xFF1565C0);
  static final PdfColor _grid = PdfColor.fromInt(0xFFD0D5DD);
  static final PdfColor _tint = PdfColor.fromInt(0xFFE3EDF7);

  static Future<pw.ThemeData> _loadTheme() async {
    try {
      final base = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Regular.ttf'));
      final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf'));
      final fallback = <pw.Font>[];
      try {
        fallback.add(pw.Font.ttf(await rootBundle.load('assets/fonts/NotoNastaliqUrdu.ttf')));
      } catch (e, s) {
        CrashReporter.record(e, s, reason: 'pdf_fallback_font');
      }
      return pw.ThemeData.withFont(base: base, bold: bold, fontFallback: fallback);
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'pdf_fonts');
      return pw.ThemeData();
    }
  }

  static String _date(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String _rs(int paisa) => 'Rs ${Money.format(paisa)}';

  static Future<Uint8List> build(StatementData data) async {
    final theme = await _loadTheme();
    final doc = pw.Document(
      title: 'Statement - ${data.customer.name}',
      author: data.shopName.isEmpty ? 'Digital Khata' : data.shopName,
    );

    pw.Widget cell(String text,
        {bool bold = false, pw.Alignment align = pw.Alignment.centerLeft, PdfColor? color}) {
      return pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      );
    }

    final header = pw.TableRow(
      decoration: pw.BoxDecoration(color: _tint),
      children: <pw.Widget>[
        cell('Date', bold: true),
        cell('Details', bold: true),
        cell('Credit', bold: true, align: pw.Alignment.centerRight),
        cell('Payment', bold: true, align: pw.Alignment.centerRight),
        cell('Balance', bold: true, align: pw.Alignment.centerRight),
      ],
    );

    final rows = <pw.TableRow>[
      header,
      pw.TableRow(children: <pw.Widget>[
        cell(_date(data.from)),
        cell('Opening balance', bold: true),
        cell(''),
        cell(''),
        cell(_rs(data.openingBalance), align: pw.Alignment.centerRight),
      ]),
      for (final e in data.entries)
        pw.TableRow(children: <pw.Widget>[
          cell(_date(e.transaction.txnDate)),
          cell(_details(e.transaction)),
          cell(e.transaction.type == TxnType.credit ? _rs(e.transaction.amount) : '',
              align: pw.Alignment.centerRight),
          cell(e.transaction.type == TxnType.payment ? _rs(e.transaction.amount) : '',
              align: pw.Alignment.centerRight),
          cell(_rs(e.balanceAfter), align: pw.Alignment.centerRight),
        ]),
    ];

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: theme,
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8)),
        ),
        build: (context) => <pw.Widget>[
          pw.Text(data.shopName.isEmpty ? 'Digital Khata' : data.shopName,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.SizedBox(height: 2),
          pw.Text('Account statement', style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 14),
          pw.Text(data.customer.name,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          if (data.customer.phone != null)
            pw.Text(data.customer.phone!, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text('Period: ${_date(data.from)} - ${_date(data.to)}',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 14),
          pw.Table(
            border: pw.TableBorder.all(color: _grid, width: 0.5),
            columnWidths: <int, pw.TableColumnWidth>{
              0: const pw.FixedColumnWidth(70),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(72),
              3: const pw.FixedColumnWidth(72),
              4: const pw.FixedColumnWidth(80),
            },
            children: rows,
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: _tint),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: <pw.Widget>[
                _summaryRow('Total credit given', _rs(data.totalCredit)),
                _summaryRow('Total payments received', _rs(data.totalPayment)),
                pw.Divider(color: _grid),
                _summaryRow(
                  data.closingBalance < 0 ? 'Advance paid by customer' : 'Amount due',
                  _rs(data.closingBalance.abs()),
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String _details(LedgerTransaction t) {
    final label = t.type == TxnType.credit ? 'Credit given' : 'Payment received';
    final note = t.note;
    return note == null || note.isEmpty ? label : '$label - $note';
  }

  static pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: 10.5,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }
}
