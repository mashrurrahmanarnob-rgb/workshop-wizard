import 'package:flutter/material.dart';
// This imports the new file you just created
import 'screens/auth_screens.dart';

void main() {
  runApp(const WorkshopWizardApp());
}

class WorkshopWizardApp extends StatelessWidget {
  const WorkshopWizardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workshop Wizard',
      debugShowCheckedModeBanner: false, // Hides the "DEBUG" banner
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      // This tells the app to launch your LoginScreen first!
      home: LoginScreen(),
    );
  }
}