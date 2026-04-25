import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:workshop_wizard/screens/auth_screens.dart';
import 'package:workshop_wizard/services/firebase_service.dart';

void main() {
  testWidgets('LoginScreen displays Workshop Wizard UI', (WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth();
    final mockService = FirebaseService(auth: mockAuth);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(firebaseService: mockService),
      ),
    );

    // Verify that the app displays the Login screen with expected elements
    expect(find.text('Workshop Wizard'), findsWidgets);
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Select your role to access dashboard'), findsOneWidget);
  });
}
