import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incident_reporter/screens/login_screen.dart';

void main() {
  testWidgets('login screen renders keycloak action', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Ambulancier'), findsOneWidget);
    expect(find.text('Sign In with Keycloak'), findsOneWidget);
  });
}
