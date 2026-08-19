// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vokabel_app/app/root.dart';

void main() {
  testWidgets('VokabelApp boots', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VokabelRoot());
    await tester.pumpAndSettle();

    // AppBar title is present on the login screen.
    expect(find.text('VokabelApp'), findsOneWidget);
  });
}
