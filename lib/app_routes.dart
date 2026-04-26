import 'package:flutter/material.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String createAccount = '/create_account';
  static const String forgotPassword = '/forgot_password';
  static const String dashboard = '/dashboard';
  static const String committeeHome = '/committee_home';
  static const String proposals = '/proposals';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      createAccount: (context) => const CreateAccountScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      dashboard: (context) => const DashboardScreen(role: 'Student'),
      
      // PLACEHOLDERS: Your teammates will replace these with their actual Screen classes
      committeeHome: (context) => const PlaceholderScreen(title: 'Committee Homepage'),
      proposals: (context) => const PlaceholderScreen(title: 'Proposals List'),
    };
  }
}

/// A temporary screen to be used until your teammates integrate their code.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              '$title is coming soon!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'This is a placeholder. Team members should replace this route in app_routes.dart with their finished screen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
