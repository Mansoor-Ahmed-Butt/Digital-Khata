import 'package:digital_khata/core/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PinPad reports digits and backspace', (tester) async {
    final digits = <String>[];
    var backspaces = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PinPad(onDigit: digits.add, onBackspace: () => backspaces++),
      ),
    ));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('0'));
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    expect(digits, <String>['1', '0']);
    expect(backspaces, 1);
  });
}
