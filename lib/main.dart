import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WorkshopWizardApp());
}

class WorkshopWizardApp extends StatelessWidget {
  const WorkshopWizardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workshop Wizard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF76C279),
        scaffoldBackgroundColor: const Color(0xFF76C279),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}