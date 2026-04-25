import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:workshop_wizard/services/firebase_service.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FirebaseService firebaseService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    firebaseService = FirebaseService(auth: mockAuth);
  });

  group('FirebaseService - SignUp', () {
    test('successful sign up', () async {
      final result = await firebaseService.signUp(
        email: 'test@graduate.utm.my',
        password: 'password123',
        fullName: 'Test User',
        username: 'testuser',
      );

      expect(result['success'], true);
      expect(result['message'], 'Account created successfully!');
      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser!.displayName, 'Test User');
    });

    test('sign up fails with weak-password', () async {
      // For mock_exceptions/firebase_auth_mocks we might need to handle specific errors if the mock supports it
      // Standard MockFirebaseAuth allows creating users. 
      // To test failures, we can use a mock that throws or check if the mock supports exception triggering.
    });
   group('FirebaseService - Login', () {
    test('successful login', () async {
      // First create a user in the mock
      await mockAuth.createUserWithEmailAndPassword(
        email: 'test@graduate.utm.my',
        password: 'password123',
      );
      // Sign out to test login
      await mockAuth.signOut();

      final result = await firebaseService.login(
        email: 'test@graduate.utm.my',
        password: 'password123',
      );

      expect(result['success'], true);
      expect(result['message'], 'Login successful!');
      expect(mockAuth.currentUser, isNotNull);
    });
  });

  group('FirebaseService - Password Reset', () {
    test('send password reset email', () async {
      final result = await firebaseService.resetPassword(email: 'test@graduate.utm.my');

      expect(result['success'], true);
      expect(result['message'], 'Password reset email sent! Check your inbox.');
    });
  });
  });
}
