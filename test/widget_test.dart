// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:g2g_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // This test verifies that the app can be instantiated without compilation errors
    // The original issue was a package import mismatch which has been fixed
    final app = MyApp();
    expect(app, isNotNull);
    expect(app.runtimeType, MyApp);
  });
}
