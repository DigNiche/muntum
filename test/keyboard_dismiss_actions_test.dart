import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muntum/components/keyboard_dismiss_actions.dart';

void main() {
  testWidgets('touching outside a text field removes focus', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => KeyboardDismissActions(child: child!),
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: focus),
              const SizedBox(height: 80),
              const Text('outside'),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    await tester.tap(find.text('outside'));
    await tester.pump();
    expect(focus.hasFocus, isFalse);
  });
}
